import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/model/enums.dart';
import '../../domain/model/serialization.dart';
import '../../domain/model/generation_settings.dart';
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

  Future<void> updateDreamText(String dreamId, String text, DateTime editedAt);

  Future<void> decideLink(String decisionId, String status);

  Future<void> updateScenePlacement(String sceneId, String placement);

  Future<void> editPassage(String passageId, String text);

  Future<void> revertPassage(String passageId);

  Future<void> markPassageRead(String passageId, DateTime firstReadAt);

  Future<void> removeDreamFromManuscript(String dreamId);

  Future<void> deleteDream(String dreamId, {required bool keepDerived});

  Future<CloudVolumeBundle> fetchVolumeBundle(String volumeId);
  Future<Map<String, dynamic>> updateGenerationSettings(
    Map<String, dynamic> request,
  );
  Future<Map<String, dynamic>> fetchGenerationSettings(String volumeId);
}

class SupabaseCloudSyncGateway implements CloudSyncGateway {
  const SupabaseCloudSyncGateway(this.client);

  final SupabaseClient client;

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> updateGenerationSettings(
    Map<String, dynamic> request,
  ) async {
    try {
      final result = await client.rpc(
        'user_update_generation_settings',
        params: {
          'p_volume_id': request['volume_id'],
          'p_expected_version': request['expected_version'],
          'p_mutation_id': request['mutation_id'],
          'p_adaptation': request['adaptation'],
          'p_style': request['style'],
          'p_narrative_voice': request['narrative_voice'],
        },
      );
      return Map<String, dynamic>.from(result as Map);
    } on PostgrestException catch (error) {
      if (['PT409', '40001'].contains(error.code) &&
          error.message == 'settings_version_conflict') {
        throw const GenerationSettingsConflict();
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchGenerationSettings(String volumeId) async {
    final row = await client
        .from('volumes')
        .select('settings_version,adaptation,style,narrative_voice')
        .eq('id', volumeId)
        .single();
    return {...row, 'version': row['settings_version']};
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveVolume() async {
    final row = await client
        .from('volumes')
        .select()
        .inFilter('status', const ['active', 'completable', 'completing'])
        .order('vol_no', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    final latest = await client
        .from('volumes')
        .select()
        .eq('status', 'completed')
        .order('vol_no', ascending: false)
        .limit(1)
        .maybeSingle();
    return latest == null ? null : Map<String, dynamic>.from(latest);
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
    await client.rpc('user_upsert_dream', params: {'p_payload': dream});
  }

  @override
  Future<void> updateDreamText(
    String dreamId,
    String text,
    DateTime editedAt,
  ) async {
    await client
        .from('dreams')
        .update({
          'raw_text': text,
          'raw_text_edited_at': editedAt.toUtc().toIso8601String(),
          'updated_at': editedAt.toUtc().toIso8601String(),
        })
        .eq('id', dreamId)
        .select('id')
        .single();
  }

  @override
  Future<void> decideLink(String decisionId, String status) async {
    await client.rpc(
      'user_decide_link',
      params: {'p_decision_id': decisionId, 'p_status': status},
    );
  }

  @override
  Future<void> updateScenePlacement(String sceneId, String placement) async {
    await client
        .from('scenes')
        .update({
          'placement': placement,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sceneId)
        .select('id')
        .single();
  }

  @override
  Future<void> editPassage(String passageId, String text) async {
    await client.rpc(
      'user_edit_passage',
      params: {'p_passage_id': passageId, 'p_text': text},
    );
  }

  @override
  Future<void> revertPassage(String passageId) async {
    await client.rpc(
      'user_revert_passage',
      params: {'p_passage_id': passageId},
    );
  }

  @override
  Future<void> markPassageRead(String passageId, DateTime firstReadAt) async {
    await client.rpc(
      'user_mark_passage_read',
      params: {
        'p_passage_id': passageId,
        'p_first_read_at': firstReadAt.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> removeDreamFromManuscript(String dreamId) async {
    await client.rpc(
      'user_remove_dream_from_manuscript',
      params: {'p_dream_id': dreamId},
    );
  }

  @override
  Future<void> deleteDream(String dreamId, {required bool keepDerived}) async {
    await client.rpc(
      'user_delete_dream',
      params: {'p_dream_id': dreamId, 'p_keep_derived': keepDerived},
    );
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
class CloudSyncService
    implements RemoteEngineSync, GenerationSettingsPinSource {
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
    NarrativeVoice narrativeVoice = NarrativeVoice.firstPersonPast,
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
    // Capture pending author mutations before HTTP: delivery may acknowledge
    // them while this older server snapshot is still in flight.
    final protectedIds = await _pendingPassageIds();
    final requestedAt = DateTime.now().toUtc();
    await _apply(
      await gateway.fetchVolumeBundle(volumeId),
      protectedPassageIds: protectedIds,
      requestedAt: requestedAt,
    );
  }

  Future<void> deliverInteraction(
    String operation,
    Map<String, dynamic> payload,
  ) async {
    _requireUser();
    switch (operation) {
      case 'update_generation_settings':
        await _deliverGenerationSettings(payload);
      case 'decide_link':
        await gateway.decideLink(
          payload['decision_id'] as String,
          payload['status'] as String,
        );
      case 'change_placement':
        await gateway.updateScenePlacement(
          payload['scene_id'] as String,
          payload['placement'] as String,
        );
      case 'edit_passage':
        await gateway.editPassage(
          payload['passage_id'] as String,
          payload['text'] as String,
        );
      case 'revert_passage':
        await gateway.revertPassage(payload['passage_id'] as String);
      case 'mark_passage_read':
        await gateway.markPassageRead(
          payload['passage_id'] as String,
          DateTime.parse(payload['first_read_at'] as String),
        );
      case 'edit_dream':
        await gateway.updateDreamText(
          payload['dream_id'] as String,
          payload['text'] as String,
          DateTime.parse(payload['edited_at'] as String),
        );
      case 'remove_dream':
        await gateway.removeDreamFromManuscript(payload['dream_id'] as String);
      case 'delete_dream':
        await gateway.deleteDream(
          payload['dream_id'] as String,
          keepDerived: payload['keep_derived'] as bool,
        );
      default:
        throw StateError('unsupported_cloud_interaction');
    }
  }

  @override
  Future<int?> generationSettingsVersion(String dreamId) async {
    final row =
        await (database.select(database.jobs)
              ..where((j) => j.dreamId.equals(dreamId))
              ..orderBy([(j) => OrderingTerm.desc(j.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.payload)['generation_settings_version'] as num?)
        ?.toInt();
  }

  Future<void> _deliverGenerationSettings(Map<String, dynamic> request) async {
    final userId = _requireUser();
    final volumeId = request['volume_id'] as String;
    final mutationId = request['mutation_id'] as String;
    final pending = await (database.select(
      database.generationSettingsChanges,
    )..where((c) => c.volumeId.equals(volumeId))).getSingleOrNull();
    if (pending == null || pending.mutationId != mutationId) return;
    final owner = await (database.select(
      database.volumes,
    )..where((v) => v.id.equals(volumeId))).getSingle();
    if (owner.userId != userId) throw StateError('cloud_owner_changed');
    var conflict = false;
    late Map<String, dynamic> snapshot;
    try {
      snapshot = await gateway.updateGenerationSettings(request);
      if ((snapshot['version'] as num).toInt() !=
          (request['expected_version'] as num).toInt() + 1) {
        throw StateError('settings_ack_mismatch');
      }
    } on GenerationSettingsConflict {
      snapshot = await gateway.fetchGenerationSettings(volumeId);
      conflict = true;
    }
    final settings = GenerationSettings.fromJson(snapshot);
    final version = (snapshot['version'] as num).toInt();
    if (version < 1 || _requireUser() != userId) {
      throw StateError('cloud_owner_changed');
    }
    await database.transaction(() async {
      final current = await (database.select(
        database.volumes,
      )..where((v) => v.id.equals(volumeId))).getSingleOrNull();
      if (current == null || current.userId != userId) {
        throw StateError('cloud_owner_changed');
      }
      if (version >= current.settingsVersion) {
        await (database.update(
          database.volumes,
        )..where((v) => v.id.equals(volumeId))).write(
          VolumesCompanion(
            adaptation: Value(settings.adaptation.databaseValue),
            style: Value(settings.style.databaseValue),
            narrativeVoice: Value(settings.narrativeVoice.databaseValue),
            settingsVersion: Value(version),
          ),
        );
      }
      final change = await (database.select(
        database.generationSettingsChanges,
      )..where((c) => c.volumeId.equals(volumeId))).getSingleOrNull();
      if (change?.mutationId != mutationId) return;
      if (conflict) {
        await (database.update(
          database.generationSettingsChanges,
        )..where((c) => c.volumeId.equals(volumeId))).write(
          const GenerationSettingsChangesCompanion(status: Value('conflict')),
        );
      } else {
        await (database.delete(
          database.generationSettingsChanges,
        )..where((c) => c.volumeId.equals(volumeId))).go();
      }
    });
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
      await database.delete(database.completedBooks).go();
      await database.delete(database.completionRequests).go();
      await database.delete(database.passages).go();
      await database.delete(database.linkDecisions).go();
      await database.delete(database.jobs).go();
      await database.delete(database.dreamElements).go();
      await database.delete(database.progressEvents).go();
      await database.delete(database.entities).go();
      await database.delete(database.readerPositions).go();
      await database.delete(database.presentationReceipts).go();
      await database.delete(database.generationSettingsChanges).go();
      await database.delete(database.scenes).go();
      await database.delete(database.dreams).go();
      await database.delete(database.volumes).go();
      await database.delete(database.outbox).go();
      await database.delete(database.dreamDrafts).go();
    });
  }

  Future<Set<String>> _pendingPassageIds({DateTime? since}) async {
    final rows = await (database.select(
      database.outbox,
    )..where((row) => row.op.isIn(['edit_passage', 'revert_passage']))).get();
    final ids = <String>{};
    for (final row in rows) {
      final envelope = jsonDecode(row.payload) as Map;
      final createdAt = DateTime.tryParse(
        envelope['created_at'] as String? ?? '',
      );
      if (row.status != 'done' ||
          (since != null && createdAt != null && !createdAt.isBefore(since))) {
        ids.add((envelope['body'] as Map)['passage_id'] as String);
      }
    }
    return ids;
  }

  Future<void> _apply(
    CloudVolumeBundle bundle, {
    Set<String> protectedPassageIds = const {},
    DateTime? requestedAt,
  }) async {
    final userId = _requireUser();
    final volume = bundle.volume;
    final volumeId = volume['id'] as String;
    if (volume['user_id'] != userId) throw StateError('cloud_owner_changed');
    await database.transaction(() async {
      final preservedIds = {
        ...protectedPassageIds,
        ...await _pendingPassageIds(since: requestedAt),
      };
      final localPassages = {
        for (final passage in await database.select(database.passages).get())
          passage.id: passage,
      };
      for (final row in bundle.passages) {
        final local = localPassages[row['id']];
        if (local == null) continue;
        // Also protect edits that started and were acknowledged during HTTP,
        // and a locked U against an older generated snapshot.
        if (local.locked &&
            local.origin == 'U' &&
            row['origin'] != 'U' &&
            local.updatedAt.isAfter(_dateTime(row['updated_at']))) {
          preservedIds.add(local.id);
        }
      }
      final localVolume = await (database.select(
        database.volumes,
      )..where((v) => v.id.equals(volumeId))).getSingleOrNull();
      final remoteSettingsVersion =
          (volume['settings_version'] as num?)?.toInt() ?? 1;
      final keepSettings =
          localVolume != null &&
          localVolume.settingsVersion > remoteSettingsVersion;
      final completionRequest = await (database.select(
        database.completionRequests,
      )..where((r) => r.volumeId.equals(volumeId))).getSingleOrNull();
      final preserveCompletion =
          localVolume != null &&
          (localVolume.status == 'completed' ||
              (localVolume.status == 'completing' &&
                  completionRequest?.status == 'pending'));
      await database
          .into(database.volumes)
          .insertOnConflictUpdate(
            LocalVolumeRow(
              id: volumeId,
              userId: userId,
              volNo: (volume['vol_no'] as num).toInt(),
              title: volume['title'] as String?,
              format: volume['format'] as String,
              adaptation: keepSettings
                  ? localVolume.adaptation
                  : volume['adaptation'] as String,
              style: keepSettings
                  ? localVolume.style
                  : volume['style'] as String,
              narrativeVoice: keepSettings
                  ? localVolume.narrativeVoice
                  : volume['narrative_voice'] as String,
              settingsVersion: keepSettings
                  ? localVolume.settingsVersion
                  : remoteSettingsVersion,
              status: preserveCompletion
                  ? localVolume.status
                  : volume['status'] as String,
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
        await (database.delete(database.passages)..where(
              (row) =>
                  row.sceneId.isIn(sceneIds) & row.id.isNotIn(preservedIds),
            ))
            .go();
      }
      for (final row in bundle.passages) {
        final id = row['id'] as String;
        if (preservedIds.contains(id) && localPassages.containsKey(id)) {
          continue;
        }
        // Opening a result is monotonic, even if a stale snapshot has no mark.
        final localRead = localPassages[id]?.firstReadAt;
        final remoteRead = _nullableDateTime(row['first_read_at']);
        final firstRead = localRead == null
            ? remoteRead
            : remoteRead == null || localRead.isBefore(remoteRead)
            ? localRead
            : remoteRead;
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
                firstReadAt: firstRead,
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
