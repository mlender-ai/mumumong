import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/sync/cloud_sync_service.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

const _userId = '00000000-0000-4000-8000-000000000111';
const _volumeId = '00000000-0000-4000-8000-000000000222';
const _sceneId = '00000000-0000-4000-8000-000000000333';
const _elementId = '00000000-0000-4000-8000-000000000444';
const _passageId = '00000000-0000-4000-8000-000000000555';
const _eventId = '00000000-0000-4000-8000-000000000666';

class _FakeCloudGateway implements CloudSyncGateway {
  @override
  String? currentUserId = _userId;
  final volumes = <Map<String, dynamic>>[];
  final dreams = <Map<String, dynamic>>[];
  CloudVolumeBundle? bundle;
  bool loseCreateResponse = false;

  @override
  Future<Map<String, dynamic>> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    required NarrativeVoice narrativeVoice,
  }) async {
    final row = _volume(
      adaptation: adaptation.databaseValue,
      style: style.databaseValue,
    );
    volumes.add(row);
    if (loseCreateResponse) throw StateError('response_lost');
    return row;
  }

  @override
  Future<Map<String, dynamic>?> fetchActiveVolume() async =>
      volumes.isEmpty ? null : volumes.last;

  @override
  Future<CloudVolumeBundle> fetchVolumeBundle(String volumeId) async =>
      bundle ??
      CloudVolumeBundle(
        volume: volumes.single,
        dreams: const [],
        elements: const [],
        scenes: const [],
        passages: const [],
        progressEvents: const [],
        linkDecisions: const [],
      );

  @override
  Future<void> upsertDream(Map<String, dynamic> dream) async {
    dreams.removeWhere((row) => row['id'] == dream['id']);
    dreams.add(dream);
  }
}

void main() {
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
    },
  );
}

Map<String, dynamic> _volume({
  String adaptation = 'balanced',
  String style = 'plain',
  double progressMu = 0,
}) => {
  'id': _volumeId,
  'user_id': _userId,
  'vol_no': 1,
  'title': null,
  'format': 'short',
  'adaptation': adaptation,
  'style': style,
  'narrative_voice': 'third_person_past',
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
