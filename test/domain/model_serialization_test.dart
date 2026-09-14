import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/model/models.dart';

void main() {
  void expectRoundTrip(
    Map<String, dynamic> json,
    Map<String, dynamic> Function(Map<String, dynamic>) roundTrip,
  ) {
    expect(roundTrip(json), equals(json));
  }

  group('domain model serialization', () {
    test('Volume round-trips DB field names and values', () {
      final volume = Volume(
        id: 'volume-1',
        volNo: 1,
        title: '비가 멈춘 자리',
        format: VolumeFormat.novella,
        adaptation: AdaptationLevel.balanced,
        style: WritingStyle.cinematic,
        narrativeVoice: NarrativeVoice.firstPersonPast,
        status: VolumeStatus.completable,
        progressMu: 32.75,
        targetMu: 80,
        genreProfile: const {'mystery': 0.7, 'fantasy': 0.3},
        coverMotifId: 'rain-window',
        prologueSceneId: 'scene-prologue',
      );

      expectRoundTrip(
        volume.toJson(),
        (json) => Volume.fromJson(json).toJson(),
      );
    });

    test('Dream round-trips nullable clarity and date types', () {
      final dream = Dream(
        id: 'dream-1',
        volumeId: 'volume-1',
        dreamDate: DateTime(2026, 9, 15),
        recordedAt: DateTime.utc(2026, 9, 15, 6, 30),
        inputMode: DreamInputMode.voice,
        rawText: '붉은 우산을 든 사람이 플랫폼 끝에 서 있었다.',
        recallAnswers: const {'object': '붉은 우산', 'light': '새벽빛'},
        clarity: DreamClarity.partial,
        status: DreamStatus.inManuscript,
        isBackfill: false,
      );

      expectRoundTrip(dream.toJson(), (json) => Dream.fromJson(json).toJson());
    });

    test('DreamElement round-trips its PostgreSQL int4range span', () {
      const element = DreamElement(
        id: 'element-1',
        dreamId: 'dream-1',
        type: DreamElementType.sensory,
        label: '젖은 철 냄새',
        detail: '기차가 지나간 뒤 남은 냄새',
        salience: DreamElementSalience.high,
        source: DreamElementSource.raw,
        span: (12, 22),
      );

      expectRoundTrip(
        element.toJson(),
        (json) => DreamElement.fromJson(json).toJson(),
      );
      expect(element.toJson()['span'], '[12,22)');
    });

    test('Scene round-trips placement and source IDs', () {
      final scene = Scene(
        id: 'scene-1',
        volumeId: 'volume-1',
        orderKey: 'a1',
        chapterNo: 2,
        kind: SceneKind.interlude,
        placement: PlacementKind.fragmentAttach,
        title: '빈 플랫폼',
        sourceDreamIds: const ['dream-1', 'dream-2'],
        openImage: '플랫폼 위로 번지는 푸른빛',
      );

      expectRoundTrip(scene.toJson(), (json) => Scene.fromJson(json).toJson());
    });

    test('Passage round-trips origin and optional source fields', () {
      final passage = Passage(
        id: 'passage-1',
        sceneId: 'scene-1',
        orderKey: 'a1',
        text: '나는 우산 아래에서 오래 기다렸다.',
        origin: PassageOrigin.connection,
        sourceDreamId: 'dream-1',
        sourceElementIds: const ['element-1'],
        cReason: '반복된 비의 모티프를 연결',
        originalText: null,
        locked: false,
        firstReadAt: DateTime.utc(2026, 9, 15, 7),
      );

      expectRoundTrip(
        passage.toJson(),
        (json) => Passage.fromJson(json).toJson(),
      );
    });

    test('StoryEntity round-trips aliases and status', () {
      final entity = StoryEntity(
        id: 'entity-1',
        volumeId: 'volume-1',
        type: 'person',
        roleName: '우산 든 여자',
        description: null,
        aliases: const ['플랫폼의 여자', '붉은 우산'],
        status: StoryEntityStatus.confirmed,
        mentionCount: 3,
      );

      expectRoundTrip(
        entity.toJson(),
        (json) => StoryEntity.fromJson(json).toJson(),
      );
    });

    test('LinkDecision round-trips JSON payload and status', () {
      final decision = LinkDecision(
        id: 'decision-1',
        dreamId: 'dream-1',
        kind: LinkDecisionKind.entityMerge,
        payload: const {
          'element_id': 'element-1',
          'candidate_entity_id': 'entity-1',
          'confidence': 0.84,
        },
        status: LinkDecisionStatus.unsure,
      );

      expectRoundTrip(
        decision.toJson(),
        (json) => LinkDecision.fromJson(json).toJson(),
      );
    });

    test('ProgressEvent round-trips numeric MU and structured reasons', () {
      final event = ProgressEvent(
        id: 'progress-1',
        volumeId: 'volume-1',
        dreamId: 'dream-1',
        deltaMu: 2.5,
        reasons: const [
          {'type': 'new_scene', 'n': 1},
          {'type': 'recall', 'n': 2},
        ],
        createdAt: DateTime.utc(2026, 9, 15, 7, 5),
      );

      expectRoundTrip(
        event.toJson(),
        (json) => ProgressEvent.fromJson(json).toJson(),
      );
    });

    test('JobProgress round-trips pipeline stage values', () {
      const progress = JobProgress(
        dreamId: 'dream-1',
        type: JobType.linkPatch,
        status: JobStatus.running,
        attempt: 2,
        stageLabel: '연결을 다시 정리하는 중',
      );

      expectRoundTrip(
        progress.toJson(),
        (json) => JobProgress.fromJson(json).toJson(),
      );
    });
  });

  test('enum mappings preserve every non-identity DB value', () {
    expect(PassageOrigin.dream.databaseValue, 'D');
    expect(PassageOrigin.connection.databaseValue, 'C');
    expect(PassageOrigin.user.databaseValue, 'U');
    expect(DreamStatus.inManuscript.databaseValue, 'in_manuscript');
    expect(DreamStatus.archivedOnly.databaseValue, 'archived_only');
    expect(PlacementKind.fragmentAttach.databaseValue, 'fragment_attach');
    expect(NarrativeVoice.thirdPersonPast.databaseValue, 'third_person_past');
    expect(JobType.linkPatch.databaseValue, 'link_patch');
    expect(LinkDecisionKind.entityMerge.databaseValue, 'entity_merge');
  });

  group('Passage invariants', () {
    test('dream-origin passages require a source element', () {
      expect(
        () => Passage(
          id: 'passage-d',
          sceneId: 'scene-1',
          orderKey: 'a1',
          text: '꿈에서 온 문장',
          origin: PassageOrigin.dream,
          sourceDreamId: 'dream-1',
          sourceElementIds: const [],
          cReason: null,
          originalText: null,
          locked: false,
          firstReadAt: null,
        ),
        throwsArgumentError,
      );
    });

    test('user-origin passages must be locked', () {
      expect(
        () => Passage(
          id: 'passage-u',
          sceneId: 'scene-1',
          orderKey: 'a1',
          text: '사용자가 쓴 문장',
          origin: PassageOrigin.user,
          sourceDreamId: null,
          sourceElementIds: const [],
          cReason: null,
          originalText: null,
          locked: false,
          firstReadAt: null,
        ),
        throwsArgumentError,
      );
    });
  });
}
