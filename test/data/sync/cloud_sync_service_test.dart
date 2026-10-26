import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/sync/cloud_sync_service.dart';
import 'package:mumumong/data/sync/outbox_worker.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

const _userId = '00000000-0000-4000-8000-000000000111';
const _volumeId = '00000000-0000-4000-8000-000000000222';
const _sceneId = '00000000-0000-4000-8000-000000000333';
const _elementId = '00000000-0000-4000-8000-000000000444';
const _passageId = '00000000-0000-4000-8000-000000000555';
const _eventId = '00000000-0000-4000-8000-000000000666';

class _FakeCloudGateway implements CloudSyncGateway {
  final settingsReceipts = <String, Map<String, dynamic>>{};
  bool loseSettingsResponse = false;
  bool settingsOffline = false;
  Completer<void>? settingsEntered;
  Completer<void>? settingsBarrier;
  @override
  Future<Map<String, dynamic>> updateGenerationSettings(
    Map<String, dynamic> request,
  ) async {
    if (settingsOffline) throw StateError('synthetic_offline');
    settingsEntered?.complete();
    await settingsBarrier?.future;
    final key = request['mutation_id'] as String;
    final prior = settingsReceipts[key];
    if (prior != null) return prior;
    final current = volumes.single;
    final version = current['settings_version'] as int? ?? 1;
    if (request['expected_version'] != version) {
      throw const GenerationSettingsConflict();
    }
    final result = <String, dynamic>{
      'version': version + 1,
      'adaptation': request['adaptation'],
      'style': request['style'],
      'narrative_voice': request['narrative_voice'],
    };
    current.addAll({...result, 'settings_version': version + 1});
    settingsReceipts[key] = result;
    if (loseSettingsResponse) throw StateError('synthetic_ack_lost');
    return result;
  }

  @override
  Future<Map<String, dynamic>> fetchGenerationSettings(String volumeId) async =>
      {...volumes.single, 'version': volumes.single['settings_version'] ?? 1};
  @override
  String? currentUserId = _userId;
  final volumes = <Map<String, dynamic>>[];
  final dreams = <Map<String, dynamic>>[];
  CloudVolumeBundle? bundle;
  bool loseCreateResponse = false;
  Completer<void>? fetchEntered;
  Completer<void>? fetchBarrier;
  final interactions = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    required NarrativeVoice narrativeVoice,
  }) async {
    final row = _volume(
      adaptation: adaptation.databaseValue,
      style: style.databaseValue,
      narrativeVoice: narrativeVoice.databaseValue,
    );
    volumes.add(row);
    if (loseCreateResponse) throw StateError('response_lost');
    return row;
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveVolume() async =>
      volumes.isEmpty ? null : volumes.last;

  @override
  Future<CloudVolumeBundle> fetchVolumeBundle(String volumeId) async {
    fetchEntered?.complete();
    await fetchBarrier?.future;
    return bundle ??
        CloudVolumeBundle(
          volume: volumes.single,
          dreams: const [],
          elements: const [],
          scenes: const [],
          passages: const [],
          progressEvents: const [],
          linkDecisions: const [],
        );
  }

  @override
  Future<void> upsertDream(Map<String, dynamic> dream) async {
    dreams.removeWhere((row) => row['id'] == dream['id']);
    dreams.add(dream);
  }

  @override
  Future<void> updateDreamText(
    String dreamId,
    String text,
    DateTime editedAt,
  ) async {
    interactions.add({
      'operation': 'edit_dream',
      'dream_id': dreamId,
      'text': text,
      'edited_at': editedAt,
    });
  }

  @override
  Future<void> decideLink(String decisionId, String status) async {
    interactions.add({
      'operation': 'decide_link',
      'decision_id': decisionId,
      'status': status,
    });
  }

  @override
  Future<void> updateScenePlacement(String sceneId, String placement) async {
    interactions.add({
      'operation': 'change_placement',
      'scene_id': sceneId,
      'placement': placement,
    });
  }

  @override
  Future<void> editPassage(String passageId, String text) async {
    interactions.add({
      'operation': 'edit_passage',
      'passage_id': passageId,
      'text': text,
    });
  }

  @override
  Future<void> revertPassage(String passageId) async {
    interactions.add({'operation': 'revert_passage', 'passage_id': passageId});
  }

  @override
  Future<void> markPassageRead(String passageId, DateTime firstReadAt) async {
    interactions.add({
      'operation': 'mark_passage_read',
      'passage_id': passageId,
      'first_read_at': firstReadAt,
    });
  }

  @override
  Future<void> removeDreamFromManuscript(String dreamId) async {
    interactions.add({'operation': 'remove_dream', 'dream_id': dreamId});
  }

  @override
  Future<void> deleteDream(String dreamId, {required bool keepDerived}) async {
    interactions.add({
      'operation': 'delete_dream',
      'dream_id': dreamId,
      'keep_derived': keepDerived,
    });
  }
}

void main() {
  const desired = GenerationSettings(
    adaptation: AdaptationLevel.faithful,
    style: WritingStyle.cinematic,
    narrativeVoice: NarrativeVoice.thirdPersonPast,
  );
  Future<(AppDatabase, DriftRepository, CloudSyncService, _FakeCloudGateway)>
  fixture() async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeCloudGateway()..volumes.add(_volume());
    final cloud = CloudSyncService(database, gateway);
    await cloud.bootstrapCurrentAccount();
    final repo = DriftRepository(
      database,
      seedPrototype: false,
      queueCloudMutations: true,
    );
    return (database, repo, cloud, gateway);
  }

  Future<Map<String, dynamic>> request(AppDatabase db) async {
    final change = await db.select(db.generationSettingsChanges).getSingle();
    final row = await (db.select(
      db.outbox,
    )..where((o) => o.id.equals(change.mutationId))).getSingle();
    return Map<String, dynamic>.from(jsonDecode(row.payload)['body'] as Map);
  }

  test(
    'settings Outbox reaches failed safely and explicit retry keeps original mutation',
    () async {
      final (db, repo, cloud, gateway) = await fixture();
      var clock = DateTime.now().toUtc().add(const Duration(hours: 1));
      final worker = OutboxWorker(db, (operation, body, key) async {
        await cloud.deliverInteraction(operation, body);
        return DeliveryReceipt.applied;
      }, now: () => clock);
      addTearDown(worker.dispose);
      await repo.saveGenerationSettings(_volumeId, desired);
      final original = await request(db);
      gateway.settingsOffline = true;
      for (var i = 0; i < 6; i++) {
        await worker.drain();
        clock = clock.add(const Duration(hours: 1));
      }
      expect((await db.select(db.outbox).getSingle()).status, 'failed');
      expect(
        (await repo.watchGenerationSettings(_volumeId).first)!.status,
        SettingsSyncStatus.pending,
      );
      await repo.retryGenerationSettings(_volumeId);
      expect(await request(db), original);
      gateway.settingsOffline = false;
      await worker.drain();
      expect((await db.select(db.outbox).getSingle()).status, 'done');
      expect((await repo.watchGenerationSettings(_volumeId).first)!.version, 2);
    },
  );

  test(
    'settings lost ACK retries same mutation; no manuscript writes or optimistic confirmation',
    () async {
      final (db, repo, cloud, gateway) = await fixture();
      gateway.bundle = _generatedBundle('synthetic-dream');
      await cloud.bootstrapCurrentAccount();
      await repo.editPassage(_passageId, '가상 저자 문장: 유리 달이 떴다.');
      final before = await repo.watchPassages(_sceneId).first;
      await repo.saveGenerationSettings(_volumeId, desired);
      final pending = (await repo.watchGenerationSettings(_volumeId).first)!;
      expect(pending.status, SettingsSyncStatus.pending);
      expect(pending.confirmed.style, WritingStyle.plain);
      expect(pending.selected, desired);
      final body = await request(db);
      gateway.loseSettingsResponse = true;
      await expectLater(
        cloud.deliverInteraction('update_generation_settings', body),
        throwsStateError,
      );
      expect((await repo.watchGenerationSettings(_volumeId).first)!.version, 1);
      await repo.retryGenerationSettings(_volumeId);
      expect(await request(db), body);
      gateway.loseSettingsResponse = false;
      await cloud.deliverInteraction('update_generation_settings', body);
      await cloud.deliverInteraction('update_generation_settings', body);
      final state = (await repo.watchGenerationSettings(_volumeId).first)!;
      expect(state.version, 2);
      expect(state.status, SettingsSyncStatus.synced);
      expect(state.confirmed, desired);
      expect(gateway.settingsReceipts.length, 1);
      expect(
        (await repo.watchPassages(_sceneId).first).map((p) => p.toJson()),
        before.map((p) => p.toJson()),
      );
    },
  );

  for (final keepLocal in [true, false]) {
    test(
      'settings conflict requires explicit resolution keepLocal=$keepLocal',
      () async {
        final (db, repo, cloud, gateway) = await fixture();
        await repo.saveGenerationSettings(_volumeId, desired);
        final old = await request(db);
        gateway.volumes.single.addAll({
          'settings_version': 2,
          'style': 'lyrical',
        });
        await cloud.deliverInteraction('update_generation_settings', old);
        var state = (await repo.watchGenerationSettings(_volumeId).first)!;
        expect(state.status, SettingsSyncStatus.conflict);
        expect(state.confirmed.style, WritingStyle.lyrical);
        expect(state.selected, desired);
        await repo.resolveGenerationSettingsConflict(
          _volumeId,
          keepLocal: keepLocal,
        );
        if (keepLocal) {
          final next = await request(db);
          expect(next['expected_version'], 2);
          expect(next['mutation_id'], isNot(old['mutation_id']));
          await cloud.deliverInteraction('update_generation_settings', old);
          expect(await request(db), next);
          await cloud.deliverInteraction('update_generation_settings', next);
        }
        state = (await repo.watchGenerationSettings(_volumeId).first)!;
        expect(state.status, SettingsSyncStatus.synced);
        expect(state.version, keepLocal ? 3 : 2);
        expect(
          state.confirmed.style,
          keepLocal ? WritingStyle.cinematic : WritingStyle.lyrical,
        );
      },
    );
  }

  test(
    'stale server bundle and late ACK cannot regress a newer confirmed settings version',
    () async {
      final (db, repo, cloud, gateway) = await fixture();
      await repo.saveGenerationSettings(_volumeId, desired);
      final body = await request(db);
      gateway.settingsEntered = Completer<void>();
      gateway.settingsBarrier = Completer<void>();
      final delivery = cloud.deliverInteraction(
        'update_generation_settings',
        body,
      );
      await gateway.settingsEntered!.future;
      await (db.update(db.volumes)..where((v) => v.id.equals(_volumeId))).write(
        const VolumesCompanion(
          settingsVersion: Value(3),
          style: Value('lyrical'),
        ),
      );
      gateway.settingsBarrier!.complete();
      await delivery;
      gateway.bundle = CloudVolumeBundle(
        volume: _volume(),
        dreams: [],
        elements: [],
        scenes: [],
        passages: [],
        progressEvents: [],
        linkDecisions: [],
      );
      await cloud.bootstrapCurrentAccount();
      final state = (await repo.watchGenerationSettings(_volumeId).first)!;
      expect(state.version, 3);
      expect(state.confirmed.style, WritingStyle.lyrical);
    },
  );

  test('settings response arriving after account change is rejected', () async {
    final (db, repo, cloud, gateway) = await fixture();
    await repo.saveGenerationSettings(_volumeId, desired);
    gateway.settingsEntered = Completer<void>();
    gateway.settingsBarrier = Completer<void>();
    final delivery = cloud.deliverInteraction(
      'update_generation_settings',
      await request(db),
    );
    await gateway.settingsEntered!.future;
    gateway.currentUserId = 'different-owner';
    gateway.settingsBarrier!.complete();
    await expectLater(delivery, throwsStateError);
    expect((await repo.watchGenerationSettings(_volumeId).first)!.version, 1);
  });

  test(
    'account bootstrap clears the previous owner reading bookmark',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repo = DriftRepository(database, queueCloudMutations: true);
      final old = (await repo.watchActiveVolume().first)!;
      await repo.saveGenerationSettings(old.id, desired);
      final scene = (await repo.watchScenes(old.id).first).last;
      await repo.saveReaderPosition(
        ReaderPosition(
          volumeId: old.id,
          sceneId: scene.id,
          updatedAt: DateTime.utc(2026, 10, 15),
        ),
      );
      final event = (await repo.watchRecentProgress(old.id).first).first;
      await repo.consumePresentation(
        volumeId: old.id,
        kind: PresentationKind.growth,
        sourceId: event.id,
      );
      final gateway = _FakeCloudGateway()..volumes.add(_volume());
      await CloudSyncService(database, gateway).bootstrapCurrentAccount();
      expect(await repo.loadReaderPosition(old.id), isNull);
      expect(await database.select(database.readerPositions).get(), isEmpty);
      expect(
        await database.select(database.presentationReceipts).get(),
        isEmpty,
      );
      expect(
        await database.select(database.generationSettingsChanges).get(),
        isEmpty,
      );
    },
  );
  test('S02 creates a short cloud volume and mirrors it to Drift', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeCloudGateway();
    final sync = CloudSyncService(database, gateway);

    await sync.createVolume(
      adaptation: AdaptationLevel.faithful,
      style: WritingStyle.lyrical,
    );

    final volume = await database.select(database.volumes).getSingle();
    expect(volume.id, _volumeId);
    expect(volume.userId, _userId);
    expect(volume.format, 'short');
    expect(volume.targetMu, 20);
    expect(volume.adaptation, 'faithful');
    expect(volume.style, 'lyrical');
    expect(volume.narrativeVoice, 'first_person_past');
  });

  test('S02 recovers an active volume after a lost create response', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final gateway = _FakeCloudGateway()..loseCreateResponse = true;

    await CloudSyncService(database, gateway).createVolume(
      adaptation: AdaptationLevel.balanced,
      style: WritingStyle.plain,
    );

    expect(gateway.volumes, hasLength(1));
    expect((await database.select(database.volumes).getSingle()).id, _volumeId);
  });

  test(
    'local dream queues stable delivery and cloud result replaces manuscript',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final gateway = _FakeCloudGateway();
      final sync = CloudSyncService(database, gateway);
      await sync.createVolume(
        adaptation: AdaptationLevel.balanced,
        style: WritingStyle.plain,
      );
      final repository = DriftRepository(
        database,
        seedPrototype: false,
        queueCloudMutations: true,
      );
      final dreamId = await repository.submitDream(
        DreamDraft(
          id: '00000000-0000-4000-8000-000000000777',
          rawText: '비가 오는 복도에서 붉은 문을 보았다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime.utc(2026, 9, 26),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 9, 26, 7),
        ),
      );
      await repository.answerRecall(dreamId, const {'light': '어두움'});

      final queued = await database.select(database.outbox).get();
      expect(queued.map((row) => row.op), ['create_dream', 'process_dream']);
      expect(queued.last.idempotencyKey, dreamId);

      await sync.pushDream(dreamId);
      expect(gateway.dreams.single['id'], dreamId);
      expect(gateway.dreams.single['recall_answers'], {'light': '어두움'});

      gateway.bundle = _generatedBundle(dreamId);
      await sync.pullDreamResult(dreamId);

      final elements = await repository.watchDreamElements(dreamId).first;
      final scenes = await repository.watchScenes(_volumeId).first;
      final passages = await repository.watchPassages(_sceneId).first;
      final progress = await repository.watchRecentProgress(_volumeId).first;
      expect(elements.single.id, _elementId);
      expect(scenes.single.sourceDreamIds, [dreamId]);
      expect(passages.single.origin, PassageOrigin.dream);
      expect(passages.single.sourceElementIds, [_elementId]);
      expect(progress.single.deltaMu, 2.25);
      expect((await repository.watchActiveVolume().first)!.progressMu, 2.25);

      await repository.updateDreamText(dreamId, '수정한 꿈 원문');
      await repository.editPassage(_passageId, '사용자가 고친 문장');
      await repository.markPassageRead(_passageId);
      await repository.changePlacement(_sceneId, PlacementKind.interlude);

      final interactionRows =
          await (database.select(database.outbox)..where(
                (row) =>
                    row.op.isNotIn(const ['create_dream', 'process_dream']),
              ))
              .get();
      expect(interactionRows.map((row) => row.op), [
        'edit_dream',
        'edit_passage',
        'mark_passage_read',
        'change_placement',
      ]);
    },
  );

  test(
    'in-flight result download preserves queued U edits, revert and read markers',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final gateway = _FakeCloudGateway();
      final sync = CloudSyncService(database, gateway);
      await sync.createVolume(
        adaptation: AdaptationLevel.balanced,
        style: WritingStyle.plain,
      );
      final repository = DriftRepository(
        database,
        seedPrototype: false,
        queueCloudMutations: true,
      );
      const dreamId = 'p4-synthetic-sync';
      await repository.submitDream(
        DreamDraft(
          id: dreamId,
          rawText: '나는 종이 고래를 따라갔다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime.utc(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      gateway.bundle = _generatedBundle(dreamId);
      await sync.pullDreamResult(dreamId);
      await repository.editPassage(_passageId, '나는 고래의 종이 날개를 접었다.');
      await repository.markPassageRead(_passageId);
      gateway.fetchEntered = Completer<void>();
      gateway.fetchBarrier = Completer<void>();
      final downloading = sync.pullDreamResult(dreamId);
      await gateway.fetchEntered!.future;
      // The edit is acknowledged while an older result snapshot is in flight.
      await (database.update(database.outbox)
            ..where((r) => r.op.equals('edit_passage')))
          .write(const OutboxCompanion(status: Value('done')));
      gateway.fetchBarrier!.complete();
      await downloading;
      gateway.fetchEntered = null;
      gateway.fetchBarrier = null;
      var passage = (await repository.watchPassages(_sceneId).first).single;
      expect(passage.origin, PassageOrigin.user);
      expect(passage.locked, isTrue);
      expect(passage.text, '나는 고래의 종이 날개를 접었다.');
      expect(passage.firstReadAt, isNotNull);
      await repository.revertPassage(_passageId);
      await sync.pullDreamResult(dreamId);
      passage = (await repository.watchPassages(_sceneId).first).single;
      expect(passage.origin, PassageOrigin.dream);
      expect(passage.locked, isFalse);
      expect(passage.originalText, isNull);
      expect(passage.firstReadAt, isNotNull);
    },
  );

  test(
    'durable interaction payloads are delivered through the cloud gateway',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final gateway = _FakeCloudGateway();
      final sync = CloudSyncService(database, gateway);

      await sync.deliverInteraction('edit_passage', {
        'passage_id': _passageId,
        'text': '사용자가 고친 문장',
      });
      await sync.deliverInteraction('change_placement', {
        'scene_id': _sceneId,
        'placement': 'interlude',
      });
      final editedAt = DateTime.utc(2026, 9, 27, 3);
      await sync.deliverInteraction('edit_dream', {
        'dream_id': 'dream-id',
        'text': '수정한 꿈',
        'edited_at': editedAt.toIso8601String(),
      });

      expect(gateway.interactions, [
        {
          'operation': 'edit_passage',
          'passage_id': _passageId,
          'text': '사용자가 고친 문장',
        },
        {
          'operation': 'change_placement',
          'scene_id': _sceneId,
          'placement': 'interlude',
        },
        {
          'operation': 'edit_dream',
          'dream_id': 'dream-id',
          'text': '수정한 꿈',
          'edited_at': editedAt,
        },
      ]);
    },
  );
}

Map<String, dynamic> _volume({
  String adaptation = 'balanced',
  String style = 'plain',
  String narrativeVoice = 'first_person_past',
  double progressMu = 0,
}) => {
  'id': _volumeId,
  'user_id': _userId,
  'vol_no': 1,
  'title': null,
  'format': 'short',
  'adaptation': adaptation,
  'style': style,
  'narrative_voice': narrativeVoice,
  'status': 'active',
  'target_mu': 20,
  'progress_mu': progressMu,
  'genre_profile': <String, double>{},
  'genre_directive': const {'mode': 'keep'},
  'cover_motif_id': null,
  'cover_seed': 23,
  'author_note': null,
  'prologue_scene_id': null,
  'created_at': '2026-09-26T07:00:00Z',
  'updated_at': '2026-09-26T07:00:00Z',
  'completed_at': null,
};

CloudVolumeBundle _generatedBundle(String dreamId) => CloudVolumeBundle(
  volume: _volume(progressMu: 2.25),
  dreams: [
    {
      'id': dreamId,
      'user_id': _userId,
      'volume_id': _volumeId,
      'dream_date': '2026-09-26',
      'recorded_at': '2026-09-26T07:00:00Z',
      'input_mode': 'text',
      'raw_text': '비가 오는 복도에서 붉은 문을 보았다.',
      'raw_text_edited_at': null,
      'recall_answers': const {'light': '어두움'},
      'clarity': 'partial',
      'status': 'in_manuscript',
      'sensitive_flags': const <String>[],
      'is_backfill': false,
      'created_at': '2026-09-26T07:00:00Z',
      'updated_at': '2026-09-26T07:01:00Z',
    },
  ],
  elements: [
    {
      'id': _elementId,
      'dream_id': dreamId,
      'type': 'object',
      'label': '붉은 문',
      'detail': null,
      'salience': 'high',
      'source': 'raw',
      'span': '[11,15)',
      'created_at': '2026-09-26T07:01:00Z',
    },
  ],
  scenes: [
    {
      'id': _sceneId,
      'volume_id': _volumeId,
      'order_key': 'a0',
      'chapter_no': null,
      'kind': 'prologue',
      'placement': 'standalone',
      'title': null,
      'source_dream_ids': [dreamId],
      'version': 1,
      'open_image': '붉은 문 앞에 멈췄다.',
      'created_at': '2026-09-26T07:01:00Z',
      'updated_at': '2026-09-26T07:01:00Z',
    },
  ],
  passages: [
    {
      'id': _passageId,
      'user_id': _userId,
      'scene_id': _sceneId,
      'order_key': 'a0',
      'text': '복도 끝의 붉은 문이 젖은 빛을 머금었다.',
      'origin': 'D',
      'source_dream_id': dreamId,
      'source_element_ids': const [_elementId],
      'c_reason': null,
      'original_text': null,
      'locked': false,
      'created_by': 'engine',
      'first_read_at': null,
      'created_at': '2026-09-26T07:01:00Z',
      'updated_at': '2026-09-26T07:01:00Z',
    },
  ],
  progressEvents: [
    {
      'id': _eventId,
      'user_id': _userId,
      'volume_id': _volumeId,
      'dream_id': dreamId,
      'delta_mu': 2.25,
      'reasons': const [
        {'type': 'new_scene', 'n': 1},
        {'type': 'recall', 'n': 1},
      ],
      'created_at': '2026-09-26T07:01:00Z',
    },
  ],
  linkDecisions: const [],
);
