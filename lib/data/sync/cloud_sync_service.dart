import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/model/enums.dart';
import '../../domain/model/serialization.dart';
import '../engine/engine_client.dart';
import '../local/database.dart';

class CloudVolumeBundle {
  const CloudVolumeBundle({
    required this.volume,
    required this.dreams,
    required this.elements,
    required this.scenes,
    required this.passages,
    required this.progressEvents,
    required this.linkDecisions,
  });

  final Map<String, dynamic> volume;
  final List<Map<String, dynamic>> dreams;
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> scenes;
  final List<Map<String, dynamic>> passages;
  final List<Map<String, dynamic>> progressEvents;
  final List<Map<String, dynamic>> linkDecisions;
}

abstract interface class CloudSyncGateway {
  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchActiveVolume();

  Future<Map<String, dynamic>> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    required NarrativeVoice narrativeVoice,
  });

  Future<void> upsertDream(Map<String, dynamic> dream);

  Future<CloudVolumeBundle> fetchVolumeBundle(String volumeId);
}

class SupabaseCloudSyncGateway implements CloudSyncGateway {
  const SupabaseCloudSyncGateway(this.client);

  final SupabaseClient client;

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchActiveVolume() async {
    final row = await client
        .from('volumes')
        .select()
        .inFilter('status', const ['active', 'completable', 'completing'])
        .order('vol_no', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    required NarrativeVoice narrativeVoice,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('authentication_required');
    final row = await client
        .from('volumes')
        .insert({
          'user_id': userId,
          'vol_no': 1,
          'format': VolumeFormat.short.databaseValue,
          'adaptation': adaptation.databaseValue,
          'style': style.databaseValue,
          'narrative_voice': narrativeVoice.databaseValue,
          'status': VolumeStatus.active.databaseValue,
          'target_mu': 20,
          'progress_mu': 0,
          'genre_profile': <String, double>{},
          'genre_directive': const {'mode': 'keep'},
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> upsertDream(Map<String, dynamic> dream) async {
    await client.from('dreams').upsert(dream, onConflict: 'id');
  }

  @override
  Future<CloudVolumeBundle> fetchVolumeBundle(String volumeId) async {
    final results = await Future.wait<dynamic>([
      client.from('volumes').select().eq('id', volumeId).single(),
      client.from('dreams').select().eq('volume_id', volumeId),
      client.from('dream_elements').select(),
      client.from('scenes').select().eq('volume_id', volumeId),
      client.from('passages').select(),
      client.from('progress_events').select().eq('volume_id', volumeId),
      client.from('link_decisions').select().eq('volume_id', volumeId),
    ]);
    final dreams = _mapRows(results[1]);
    final dreamIds = dreams.map((row) => row['id'] as String).toSet();
    final scenes = _mapRows(results[3]);
    final sceneIds = scenes.map((row) => row['id'] as String).toSet();
    return CloudVolumeBundle(
      volume: Map<String, dynamic>.from(results[0] as Map),
      dreams: dreams,
      elements: _mapRows(
        results[2],
      ).where((row) => dreamIds.contains(row['dream_id'])).toList(),
      scenes: scenes,
      passages: _mapRows(
        results[4],
      ).where((row) => sceneIds.contains(row['scene_id'])).toList(),
      progressEvents: _mapRows(results[5]),
      linkDecisions: _mapRows(results[6]),
    );
  }
}

/// Owns the cloud/local boundary. Remote-generated manuscript rows are pulled
/// server-first, while locally authored dream input is upserted client-first.
class CloudSyncService implements RemoteEngineSync {
  CloudSyncService(this.database, this.gateway);

  final AppDatabase database;
  final CloudSyncGateway gateway;

  Future<bool> bootstrapCurrentAccount() async {
    final userId = _requireUser();
    await _clearForeignOwner(userId);
    final volume = await gateway.fetchActiveVolume();
    if (volume == null) return false;
    await _apply(await gateway.fetchVolumeBundle(volume['id'] as String));
    return true;
  }

  Future<void> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    NarrativeVoice narrativeVoice = NarrativeVoice.thirdPersonPast,
  }) async {
    final userId = _requireUser();
    await _clearForeignOwner(userId);
    late Map<String, dynamic> volume;
    try {
      volume = await gateway.createVolume(
        adaptation: adaptation,
        style: style,
        narrativeVoice: narrativeVoice,
      );
    } on Object {
      // A lost response may hide a successful insert. Recover the one active
      // volume instead of making the user create a duplicate.
      final existing = await gateway.fetchActiveVolume();
      if (existing == null) rethrow;
      volume = existing;
    }
    await _apply(
      CloudVolumeBundle(
        volume: volume,
        dreams: const [],
        elements: const [],
        scenes: const [],
        passages: const [],
        progressEvents: const [],
        linkDecisions: const [],
      ),
    );
  }

  @override
  Future<void> pushDream(String dreamId) async {
    final userId = _requireUser();
    final dream = await (database.select(
      database.dreams,
    )..where((row) => row.id.equals(dreamId))).getSingle();
    final volumeId = dream.volumeId;
    if (volumeId == null) throw StateError('dream_volume_required');
    final volume = await (database.select(
      database.volumes,
    )..where((row) => row.id.equals(volumeId))).getSingle();

    await gateway.upsertDream({
      'id': dream.id,
      'user_id': userId,
      'volume_id': volume.id,
      'dream_date': databaseDate(dream.dreamDate),
      'recorded_at': dream.recordedAt.toUtc().toIso8601String(),
      'input_mode': dream.inputMode,
      'raw_text': dream.rawText,
      'raw_text_edited_at': dream.rawTextEditedAt?.toUtc().toIso8601String(),
      'recall_answers': jsonDecode(dream.recallAnswers),
      'clarity': dream.clarity,
      'status': dream.status,
      'sensitive_flags': jsonDecode(dream.sensitiveFlags),
      'is_backfill': dream.isBackfill,
    });
  }

  @override
  Future<void> pullDreamResult(String dreamId) async {
    final dream = await (database.select(
      database.dreams,
    )..where((row) => row.id.equals(dreamId))).getSingle();
    final volumeId = dream.volumeId;
    if (volumeId == null) throw StateError('dream_volume_required');
    await _apply(await gateway.fetchVolumeBundle(volumeId));
  }

  String _requireUser() {
    final userId = gateway.currentUserId;
    if (userId == null) throw StateError('authentication_required');
    return userId;
  }

  Future<void> _clearForeignOwner(String userId) async {
    final foreign = await (database.select(
      database.volumes,
    )..where((row) => row.userId.isNotValue(userId))).getSingleOrNull();
    if (foreign == null) return;
    await database.transaction(() async {
      await database.delete(database.passages).go();
      await database.delete(database.linkDecisions).go();
      await database.delete(database.jobs).go();
      await database.delete(database.dreamElements).go();
      await database.delete(database.progressEvents).go();
      await database.delete(database.entities).go();
      await database.delete(database.readerPositions).go();
      await database.delete(database.scenes).go();
      await database.delete(database.dreams).go();
      await database.delete(database.volumes).go();
      await database.delete(database.outbox).go();
      await database.delete(database.dreamDrafts).go();
    });
  }

  Future<void> _apply(CloudVolumeBundle bundle) async {
    final userId = _requireUser();
    final volume = bundle.volume;
    final volumeId = volume['id'] as String;
    await database.transaction(() async {
      await database
          .into(database.volumes)
          .insertOnConflictUpdate(
            LocalVolumeRow(
              id: volumeId,
              userId: userId,
              volNo: (volume['vol_no'] as num).toInt(),
              title: volume['title'] as String?,
              format: volume['format'] as String,
              adaptation: volume['adaptation'] as String,
              style: volume['style'] as String,
              narrativeVoice: volume['narrative_voice'] as String,
              status: volume['status'] as String,
              targetMu: (volume['target_mu'] as num).toDouble(),
              progressMu: (volume['progress_mu'] as num).toDouble(),
              genreProfile: jsonEncode(volume['genre_profile'] ?? const {}),
              genreDirective: jsonEncode(
                volume['genre_directive'] ?? const {'mode': 'keep'},
              ),
              coverMotifId: volume['cover_motif_id'] as String?,
              coverSeed: (volume['cover_seed'] as num?)?.toInt(),
              authorNote: volume['author_note'] as String?,
              prologueSceneId: volume['prologue_scene_id'] as String?,
              createdAt: _dateTime(volume['created_at']),
              updatedAt: _dateTime(volume['updated_at']),
              completedAt: _nullableDateTime(volume['completed_at']),
            ),
          );

      for (final row in bundle.dreams) {
        await database
            .into(database.dreams)
            .insertOnConflictUpdate(
              LocalDreamRow(
                id: row['id'] as String,
                userId: userId,
                volumeId: row['volume_id'] as String?,
                dreamDate: DateTime.parse(row['dream_date'] as String),
                recordedAt: _dateTime(row['recorded_at']),
                inputMode: row['input_mode'] as String,
                rawText: row['raw_text'] as String,
                rawTextEditedAt: _nullableDateTime(row['raw_text_edited_at']),
                recallAnswers: jsonEncode(row['recall_answers'] ?? const {}),
                clarity: row['clarity'] as String?,
                status: row['status'] as String,
                sensitiveFlags: jsonEncode(row['sensitive_flags'] ?? const []),
                isBackfill: row['is_backfill'] as bool? ?? false,
                createdAt: _dateTime(row['created_at']),
                updatedAt: _dateTime(row['updated_at']),
              ),
            );
      }

      final dreamIds = bundle.dreams.map((row) => row['id'] as String).toList();
      if (dreamIds.isNotEmpty) {
        await (database.delete(
          database.dreamElements,
        )..where((row) => row.dreamId.isIn(dreamIds))).go();
      }
      for (final row in bundle.elements) {
        await database
            .into(database.dreamElements)
            .insertOnConflictUpdate(
              LocalDreamElementRow(
                id: row['id'] as String,
                dreamId: row['dream_id'] as String,
                type: row['type'] as String,
                label: row['label'] as String,
                detail: row['detail'] as String?,
                salience: row['salience'] as String,
                source: row['source'] as String,
                span: row['span']?.toString(),
                createdAt: _dateTime(row['created_at']),
              ),
            );
      }

      for (final row in bundle.scenes) {
        await database
            .into(database.scenes)
            .insertOnConflictUpdate(
              LocalSceneRow(
                id: row['id'] as String,
                volumeId: row['volume_id'] as String,
                orderKey: row['order_key'] as String,
                chapterNo: (row['chapter_no'] as num?)?.toInt(),
                kind: row['kind'] as String,
                placement: row['placement'] as String,
                title: row['title'] as String?,
                sourceDreamIds: jsonEncode(row['source_dream_ids'] ?? const []),
                version: (row['version'] as num?)?.toInt() ?? 1,
                openImage: row['open_image'] as String?,
                createdAt: _dateTime(row['created_at']),
                updatedAt: _dateTime(row['updated_at']),
              ),
            );
      }

      final sceneIds = bundle.scenes.map((row) => row['id'] as String).toList();
      if (sceneIds.isNotEmpty) {
        await (database.delete(
          database.passages,
        )..where((row) => row.sceneId.isIn(sceneIds))).go();
      }
      for (final row in bundle.passages) {
        await database
            .into(database.passages)
            .insertOnConflictUpdate(
              LocalPassageRow(
                id: row['id'] as String,
                userId: userId,
                sceneId: row['scene_id'] as String,
                orderKey: row['order_key'] as String,
                content: row['text'] as String,
                origin: row['origin'] as String,
                sourceDreamId: row['source_dream_id'] as String?,
                sourceElementIds: jsonEncode(
                  row['source_element_ids'] ?? const [],
                ),
                cReason: row['c_reason'] as String?,
                originalText: row['original_text'] as String?,
                locked: row['locked'] as bool? ?? false,
                createdBy: row['created_by'] as String,
                firstReadAt: _nullableDateTime(row['first_read_at']),
                createdAt: _dateTime(row['created_at']),
                updatedAt: _dateTime(row['updated_at']),
              ),
            );
      }

      for (final row in bundle.progressEvents) {
        await database
            .into(database.progressEvents)
            .insertOnConflictUpdate(
              LocalProgressEventRow(
                id: row['id'] as String,
                userId: userId,
                volumeId: row['volume_id'] as String,
                dreamId: row['dream_id'] as String?,
                deltaMu: (row['delta_mu'] as num).toDouble(),
                reasons: jsonEncode(row['reasons'] ?? const []),
                createdAt: _dateTime(row['created_at']),
              ),
            );
      }

      for (final row in bundle.linkDecisions) {
        await database
            .into(database.linkDecisions)
            .insertOnConflictUpdate(
              LocalLinkDecisionRow(
                id: row['id'] as String,
                volumeId: row['volume_id'] as String,
                dreamId: row['dream_id'] as String,
                kind: row['kind'] as String,
                payload: jsonEncode(row['payload'] ?? const {}),
                status: row['status'] as String,
                decidedAt: _nullableDateTime(row['decided_at']),
                createdAt: _dateTime(row['created_at']),
              ),
            );
      }
    });
  }
}

List<Map<String, dynamic>> _mapRows(dynamic value) => (value as List)
    .map((row) => Map<String, dynamic>.from(row as Map))
    .toList(growable: false);

DateTime _dateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.parse(value as String).toUtc();
}

DateTime? _nullableDateTime(Object? value) =>
    value == null ? null : _dateTime(value);
