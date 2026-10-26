import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/model/frozen_book.dart';
import '../local/database.dart';

abstract interface class BookGateway {
  String? get userId;
  Future<List<FrozenBook>> list();
  Future<BookCompletionPreview> preview(String volumeId);
  Future<FrozenBook> complete(Map<String, dynamic> request);
  Future<void> next(String volumeId);
}

class SupabaseBookGateway implements BookGateway {
  const SupabaseBookGateway(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Future<List<FrozenBook>> list() async {
    final rows = await client
        .from('completed_books')
        .select('snapshot')
        .order('completed_at', ascending: false);
    return rows
        .map((r) => FrozenBook(Map<String, dynamic>.from(r['snapshot'] as Map)))
        .toList();
  }

  @override
  Future<BookCompletionPreview> preview(String volumeId) async {
    final row = Map<String, dynamic>.from(
      await client.rpc(
            'preview_book_completion',
            params: {'p_volume_id': volumeId},
          )
          as Map,
    );
    return BookCompletionPreview(
      document: Map<String, dynamic>.from(row['document'] as Map),
      revision: row['revision'] as String,
      eligible: row['eligible'] == true,
      busy: row['busy'] == true,
    );
  }

  @override
  Future<FrozenBook> complete(Map<String, dynamic> request) async => FrozenBook(
    Map<String, dynamic>.from(
      await client.rpc('complete_volume_book', params: request) as Map,
    ),
  );
  @override
  Future<void> next(String volumeId) async {
    await client.rpc(
      'start_volume_after_book',
      params: {'p_volume_id': volumeId},
    );
  }
}

/// Completion is a durable author mutation. A frozen book is never assembled
/// from a mix of local pending edits and an older remote manuscript.
class BookStore {
  BookStore(this.database, {this.gateway, this.pullVolume});
  final AppDatabase database;
  final BookGateway? gateway;
  final Future<void> Function()? pullVolume;
  Stream<List<FrozenBook>> watchBooks() =>
      (database.select(
        database.completedBooks,
      )..orderBy([(b) => OrderingTerm.desc(b.completedAt)])).watch().map(
        (rows) => rows
            .map(
              (r) => FrozenBook(jsonDecode(r.snapshot) as Map<String, dynamic>),
            )
            .toList(),
      );
  Stream<LocalCompletionRequestRow?> watchRequest(String volumeId) =>
      (database.select(
        database.completionRequests,
      )..where((r) => r.volumeId.equals(volumeId))).watchSingleOrNull();

  Future<void> _ensureSettled() async {
    final pending =
        await (database.select(database.outbox)..where(
              (o) =>
                  o.status.isNotValue('done') &
                  o.op.isNotValue('complete_volume') &
                  o.op.isNotValue('mark_passage_read'),
            ))
            .get();
    if (pending.isNotEmpty) throw StateError('author_changes_pending');
  }

  Future<BookCompletionPreview> prepare(String volumeId) async {
    await _ensureSettled();
    if (gateway != null) return gateway!.preview(volumeId);
    return database.transaction(() async {
      final v = await (database.select(
        database.volumes,
      )..where((v) => v.id.equals(volumeId))).getSingle();
      final scenes =
          await (database.select(database.scenes)
                ..where((s) => s.volumeId.equals(volumeId))
                ..orderBy([(s) => OrderingTerm.asc(s.orderKey)]))
              .get();
      final passages = await database.select(database.passages).get();
      final dreams = await (database.select(
        database.dreams,
      )..where((d) => d.volumeId.equals(volumeId))).get();
      final entities = await (database.select(
        database.entities,
      )..where((e) => e.volumeId.equals(volumeId))).get();
      final jobs = await (database.select(
        database.jobs,
      )..where((j) => j.volumeId.equals(volumeId))).get();
      final doc = <String, dynamic>{
        'volume_id': v.id,
        'volume_no': v.volNo,
        'format': v.format,
        'settings_version': v.settingsVersion,
        'cover_seed': v.coverSeed,
        'cover_motif_id': v.coverMotifId,
        'scenes': [
          for (final s in scenes)
            if (passages.any((p) => p.sceneId == s.id))
              {
                'id': s.id,
                'order_key': s.orderKey,
                'title': s.title,
                'kind': s.kind,
                'placement': s.placement,
                'source_dream_ids': jsonDecode(s.sourceDreamIds),
                'passages': [
                  for (final p
                      in (passages.where((p) => p.sceneId == s.id).toList()
                        ..sort((a, b) => a.orderKey.compareTo(b.orderKey))))
                    {
                      'id': p.id,
                      'order_key': p.orderKey,
                      'text': p.content,
                      'origin': p.origin,
                      'locked': p.locked,
                      'source_dream_id': p.sourceDreamId,
                      'source_element_ids': jsonDecode(p.sourceElementIds),
                      'c_reason': p.cReason,
                    },
                ],
              },
        ],
        'dreams': [
          for (final d in dreams)
            if (scenes.any(
              (s) => (jsonDecode(s.sourceDreamIds) as List).contains(d.id),
            ))
              {
                'id': d.id,
                'date': d.dreamDate.toIso8601String(),
                'first_line': String.fromCharCodes(
                  d.rawText.trim().split('\n').first.runes.take(120),
                ),
              },
        ],
      };
      // Local mock has no entity_mentions mirror. This is a prototype gate;
      // remote completion always uses the authoritative cross-dream SQL gate.
      final eligible =
          v.format == 'short' &&
          ['active', 'completable'].contains(v.status) &&
          v.progressMu >= v.targetMu * .7 &&
          (doc['scenes'] as List).length >= 5 &&
          entities.any((e) => e.mentionCount >= 2) &&
          dreams.length >= 2;
      return BookCompletionPreview(
        document: doc,
        revision: jsonEncode(doc),
        eligible: eligible,
        busy: jobs.any(
          (j) => j.attempt > 0 && ['queued', 'running'].contains(j.status),
        ),
      );
    });
  }

  Future<void> complete(
    String volumeId,
    BookCompletionPreview preview,
    String title,
    String? note,
  ) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty ||
        cleaned.runes.length > 120 ||
        (note?.runes.length ?? 0) > 10000) {
      throw ArgumentError('completion_fields_invalid');
    }
    await database.transaction(() async {
      await _ensureSettled();
      final old = await (database.select(
        database.completionRequests,
      )..where((r) => r.volumeId.equals(volumeId))).getSingleOrNull();
      if (old?.status == 'pending') return;
      if (!preview.eligible || preview.busy) {
        throw StateError('completion_not_ready');
      }
      final v = await (database.select(
        database.volumes,
      )..where((v) => v.id.equals(volumeId))).getSingle();
      if (!['active', 'completable'].contains(v.status)) {
        throw StateError('completion_not_ready');
      }
      final requestId = const Uuid().v4();
      final body = <String, dynamic>{
        'p_volume_id': volumeId,
        'p_request_id': requestId,
        'p_revision': preview.revision,
        'p_title': cleaned,
        'p_author_note': note,
      };
      if (gateway == null) {
        final current = await prepare(volumeId);
        if (current.revision != preview.revision || current.busy) {
          throw StateError('manuscript_changed');
        }
        await _store(
          FrozenBook({
            ...current.document,
            'version': 1,
            'request_id': requestId,
            'title': cleaned,
            'author_note': note,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          }),
          v.userId,
        );
        return;
      }
      if (v.userId != gateway!.userId) throw StateError('cloud_owner_changed');
      await database
          .into(database.completionRequests)
          .insertOnConflictUpdate(
            CompletionRequestsCompanion.insert(
              volumeId: volumeId,
              requestId: requestId,
              revision: preview.revision,
              title: cleaned,
              authorNote: Value(note),
              previousStatus: v.status,
              status: 'pending',
            ),
          );
      await (database.update(database.volumes)
            ..where((r) => r.id.equals(volumeId)))
          .write(const VolumesCompanion(status: Value('completing')));
      await database
          .into(database.outbox)
          .insert(
            OutboxCompanion.insert(
              id: requestId,
              op: 'complete_volume',
              payload: jsonEncode({
                'aggregate_id': 'volume:$volumeId',
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'body': body,
              }),
              idempotencyKey: requestId,
              nextAttemptAt: DateTime.now().toUtc(),
              status: 'pending',
            ),
          );
    });
  }

  Future<void> deliver(Map<String, dynamic> body) async {
    final cloud = gateway;
    if (cloud == null) throw StateError('remote_completion_required');
    final id = body['p_volume_id'] as String;
    final request = await (database.select(
      database.completionRequests,
    )..where((r) => r.volumeId.equals(id))).getSingleOrNull();
    if (request == null || request.requestId != body['p_request_id']) return;
    final owner = (await (database.select(
      database.volumes,
    )..where((v) => v.id.equals(id))).getSingle()).userId;
    if (owner != cloud.userId) throw StateError('cloud_owner_changed');
    try {
      final book = await cloud.complete(body);
      if (cloud.userId != owner ||
          book.volumeId != id ||
          book.requestId != request.requestId) {
        throw StateError('completion_ack_mismatch');
      }
      await database.transaction(() async {
        await _store(book, owner);
        await (database.delete(
          database.completionRequests,
        )..where((r) => r.requestId.equals(request.requestId))).go();
      });
    } on PostgrestException catch (e) {
      if (!['PT409', '40001', '55000', '22023'].contains(e.code)) rethrow;
      await database.transaction(() async {
        if (cloud.userId != owner) throw StateError('cloud_owner_changed');
        await (database.update(
          database.completionRequests,
        )..where((r) => r.requestId.equals(request.requestId))).write(
          const CompletionRequestsCompanion(status: Value('conflict')),
        );
        await (database.update(database.volumes)
              ..where((v) => v.id.equals(id) & v.status.equals('completing')))
            .write(VolumesCompanion(status: Value(request.previousStatus)));
      });
    }
  }

  Future<void> retry(String volumeId) async {
    final row = await (database.select(
      database.completionRequests,
    )..where((r) => r.volumeId.equals(volumeId))).getSingle();
    if (row.status != 'pending') throw StateError('refresh_completion_preview');
    await (database.update(
      database.outbox,
    )..where((o) => o.id.equals(row.requestId))).write(
      OutboxCompanion(
        status: const Value('pending'),
        attempt: const Value(0),
        nextAttemptAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> refresh() async {
    final cloud = gateway;
    if (cloud == null) return;
    final user = cloud.userId;
    if (user == null) throw StateError('authentication_required');
    final books = await cloud.list();
    if (cloud.userId != user) throw StateError('cloud_owner_changed');
    await database.transaction(() async {
      for (final book in books) {
        await _store(book, user);
      }
    });
  }

  Future<void> _store(FrozenBook book, String owner) async {
    final old = await (database.select(
      database.completedBooks,
    )..where((r) => r.volumeId.equals(book.volumeId))).getSingleOrNull();
    if (old != null) {
      if (old.userId != owner ||
          FrozenBook(
                jsonDecode(old.snapshot) as Map<String, dynamic>,
              ).requestId !=
              book.requestId) {
        throw StateError('immutable_book_conflict');
      }
    } else {
      await database
          .into(database.completedBooks)
          .insert(
            CompletedBooksCompanion.insert(
              volumeId: book.volumeId,
              userId: owner,
              snapshot: jsonEncode(book.toJson()),
              completedAt: book.completedAt,
            ),
          );
    }
    await (database.update(
      database.volumes,
    )..where((v) => v.id.equals(book.volumeId) & v.userId.equals(owner))).write(
      VolumesCompanion(
        status: const Value('completed'),
        title: Value(book.title),
        authorNote: Value(book.authorNote),
        completedAt: Value(book.completedAt),
      ),
    );
  }

  Future<void> next(FrozenBook book) async {
    if (gateway != null) {
      await gateway!.next(book.volumeId);
      await pullVolume?.call();
      return;
    }
    await database.transaction(() async {
      final active =
          await (database.select(database.volumes)..where(
                (v) => v.status.isIn(['active', 'completable', 'completing']),
              ))
              .get();
      if (active.isNotEmpty) return;
      final old = await (database.select(
        database.volumes,
      )..where((v) => v.id.equals(book.volumeId))).getSingle();
      final all = await database.select(database.volumes).get();
      final now = DateTime.now().toUtc();
      await database
          .into(database.volumes)
          .insert(
            old.copyWith(
              id: const Uuid().v4(),
              volNo:
                  all.map((v) => v.volNo).reduce((a, b) => a > b ? a : b) + 1,
              status: 'active',
              title: const Value(null),
              authorNote: const Value(null),
              completedAt: const Value(null),
              progressMu: 0,
              targetMu: 20,
              format: 'short',
              settingsVersion: 1,
              createdAt: now,
              updatedAt: now,
              prologueSceneId: const Value(null),
              genreProfile: '{}',
              genreDirective: '{"mode":"keep"}',
              coverMotifId: const Value(null),
              coverSeed: const Value(null),
            ),
          );
    });
  }
}
