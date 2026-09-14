import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../domain/repository/mumumong_repository.dart';

abstract final class MemorySeedIds {
  static const volume = '00000000-0000-4000-8000-000000000001';
  static const latestDream = '00000000-0000-4000-8000-000000000107';
  static const readerScene = '00000000-0000-4000-8000-000000000211';
  static const editablePassage = '00000000-0000-4000-8000-000000000302';
  static const linkDecision = '00000000-0000-4000-8000-000000000501';
}

class MemoryRepository implements MumumongRepository {
  MemoryRepository({DateTime Function()? now, Uuid? uuid})
    : _now = now ?? DateTime.now,
      _uuid = uuid ?? const Uuid(),
      _volume = _seedVolume(),
      _dreams = _seedDreams(),
      _scenes = _seedScenes(),
      _passages = _seedPassages(),
      _progressEvents = _seedProgressEvents(),
      _linkDecisions = _seedLinkDecisions();

  final DateTime Function() _now;
  final Uuid _uuid;
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );
  final Map<String, JobProgress> _jobs = {};
  final Map<String, PassageOrigin> _originBeforeEdit = {};

  Volume? _volume;
  DreamDraft? _draft;
  final List<Dream> _dreams;
  final List<Scene> _scenes;
  final List<Passage> _passages;
  final List<ProgressEvent> _progressEvents;
  final List<LinkDecision> _linkDecisions;
  bool _disposed = false;

  @override
  Stream<Volume?> watchActiveVolume() {
    return _watch(() {
      final volume = _volume;
      if (volume == null || volume.status == VolumeStatus.completed) {
        return null;
      }
      return volume;
    });
  }

  @override
  Stream<List<Dream>> watchDreams(DreamStatusFilter filter) {
    return _watch(() {
      final dreams =
          _dreams.where((dream) {
            return switch (filter) {
              DreamStatusFilter.all => true,
              DreamStatusFilter.inManuscript =>
                dream.status == DreamStatus.inManuscript,
              DreamStatusFilter.archivedOnly =>
                dream.status == DreamStatus.archivedOnly,
            };
          }).toList()..sort((a, b) {
            final byDate = b.dreamDate.compareTo(a.dreamDate);
            return byDate != 0 ? byDate : b.recordedAt.compareTo(a.recordedAt);
          });
      return List.unmodifiable(dreams);
    });
  }

  @override
  Stream<List<Scene>> watchScenes(String volumeId) {
    return _watch(() {
      final scenes =
          _scenes.where((scene) => scene.volumeId == volumeId).toList()
            ..sort((a, b) => a.orderKey.compareTo(b.orderKey));
      return List.unmodifiable(scenes);
    });
  }

  @override
  Stream<List<Passage>> watchPassages(String sceneId) {
    return _watch(() {
      final passages =
          _passages.where((passage) => passage.sceneId == sceneId).toList()
            ..sort((a, b) => a.orderKey.compareTo(b.orderKey));
      return List.unmodifiable(passages);
    });
  }

  @override
  Stream<List<ProgressEvent>> watchRecentProgress(String volumeId) {
    return _watch(() {
      final events =
          _progressEvents.where((event) => event.volumeId == volumeId).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(events);
    });
  }

  @override
  Stream<JobProgress?> watchJob(String dreamId) {
    return _watch(() => _jobs[dreamId]);
  }

  @override
  Future<void> saveDraft(DreamDraft draft) async {
    _ensureOpen();
    _draft = draft;
    _notify();
  }

  @override
  Future<DreamDraft?> loadDraft() async {
    _ensureOpen();
    return _draft;
  }

  @override
  Future<void> clearDraft() async {
    _ensureOpen();
    if (_draft == null) {
      return;
    }
    _draft = null;
    _notify();
  }

  @override
  Future<String> submitDream(DreamDraft draft) async {
    _ensureOpen();
    if (draft.rawText.trim().isEmpty) {
      throw ArgumentError.value(
        draft.rawText,
        'draft.rawText',
        'a dream cannot be empty',
      );
    }

    final dreamId = draft.id.isEmpty ? _uuid.v4() : draft.id;
    if (_dreams.any((dream) => dream.id == dreamId)) {
      _draft = null;
      return dreamId;
    }

    final volume = _volume;
    if (volume == null) {
      throw StateError('An active volume is required to submit a dream');
    }

    _dreams.add(
      Dream(
        id: dreamId,
        volumeId: volume.id,
        dreamDate: draft.dreamDate,
        recordedAt: _now().toUtc(),
        inputMode: draft.inputMode,
        rawText: draft.rawText,
        recallAnswers: const {},
        clarity: null,
        status: DreamStatus.queued,
        isBackfill: draft.isBackfill,
      ),
    );
    _jobs[dreamId] = JobProgress(
      dreamId: dreamId,
      type: JobType.extract,
      status: JobStatus.queued,
      attempt: 0,
      stageLabel: '꿈을 읽을 준비 중',
    );
    _draft = null;
    _notify();
    return dreamId;
  }

  @override
  Future<void> answerRecall(String dreamId, Map<String, String> answers) async {
    _ensureOpen();
    final index = _dreamIndex(dreamId);
    final dream = _dreams[index];
    _dreams[index] = dream.copyWith(
      recallAnswers: answers,
      status: DreamStatus.processing,
    );
    _jobs[dreamId] = JobProgress(
      dreamId: dreamId,
      type: JobType.extract,
      status: JobStatus.running,
      attempt: (_jobs[dreamId]?.attempt ?? 0) + 1,
      stageLabel: '꿈을 읽는 중',
    );
    _notify();
  }

  @override
  Future<void> decideLink(String decisionId, LinkChoice choice) async {
    _ensureOpen();
    final index = _linkDecisions.indexWhere(
      (decision) => decision.id == decisionId,
    );
    if (index < 0) {
      throw StateError('Link decision not found: $decisionId');
    }

    final decision = _linkDecisions[index];
    if (decision.status != LinkDecisionStatus.pending &&
        decision.status != LinkDecisionStatus.auto) {
      throw StateError('Link decision was already answered: $decisionId');
    }
    final status = switch (choice) {
      LinkChoice.same => LinkDecisionStatus.same,
      LinkChoice.different => LinkDecisionStatus.different,
      LinkChoice.unsure => LinkDecisionStatus.unsure,
    };
    _linkDecisions[index] = decision.copyWith(status: status);

    final dream = _dreams[_dreamIndex(decision.dreamId)];
    final volume = _volume;
    if (volume != null && dream.volumeId == volume.id) {
      _volume = volume.copyWith(progressMu: volume.progressMu + 0.5);
      _progressEvents.add(
        ProgressEvent(
          id: _uuid.v4(),
          volumeId: volume.id,
          dreamId: dream.id,
          deltaMu: 0.5,
          reasons: const [
            {'type': 'link_decision', 'n': 1},
          ],
          createdAt: _now().toUtc(),
        ),
      );
    }
    _notify();
  }

  @override
  Future<void> changePlacement(String sceneId, PlacementKind kind) async {
    _ensureOpen();
    final index = _sceneIndex(sceneId);
    _scenes[index] = _scenes[index].copyWith(placement: kind);
    _notify();
  }

  @override
  Future<void> editPassage(String passageId, String text) async {
    _ensureOpen();
    final index = _passageIndex(passageId);
    final passage = _passages[index];
    _originBeforeEdit.putIfAbsent(passageId, () => passage.origin);
    _passages[index] = passage.copyWith(
      text: text,
      origin: PassageOrigin.user,
      originalText: passage.originalText ?? passage.text,
      locked: true,
    );
    _notify();
  }

  @override
  Future<void> revertPassage(String passageId) async {
    _ensureOpen();
    final index = _passageIndex(passageId);
    final passage = _passages[index];
    final originalText = passage.originalText;
    final originalOrigin = _originBeforeEdit[passageId];
    if (originalText == null || originalOrigin == null) {
      throw StateError('Passage has no edit to revert: $passageId');
    }
    _passages[index] = passage.copyWith(
      text: originalText,
      origin: originalOrigin,
      originalText: null,
      locked: originalOrigin == PassageOrigin.user,
    );
    _originBeforeEdit.remove(passageId);
    _notify();
  }

  @override
  Future<void> markPassageRead(String passageId) async {
    _ensureOpen();
    final index = _passageIndex(passageId);
    final passage = _passages[index];
    if (passage.firstReadAt != null) {
      return;
    }
    _passages[index] = passage.copyWith(firstReadAt: _now().toUtc());
    _notify();
  }

  @override
  Future<void> removeDreamFromManuscript(String dreamId) async {
    _ensureOpen();
    final index = _dreamIndex(dreamId);
    final dream = _dreams[index];
    if (dream.status == DreamStatus.archivedOnly) {
      return;
    }
    _removeDerivedContent(dreamId);
    _dreams[index] = dream.copyWith(status: DreamStatus.archivedOnly);
    _cancelDreamProgress(dream, keepDreamReference: true);
    _notify();
  }

  @override
  Future<void> deleteDream(String dreamId, DeleteMode mode) async {
    _ensureOpen();
    final index = _dreamIndex(dreamId);
    final dream = _dreams[index];

    switch (mode) {
      case DeleteMode.deleteDerivedContent:
        _removeDerivedContent(dreamId);
      case DeleteMode.keepDerivedContent:
        _detachDreamSources(dreamId);
    }

    _dreams.removeAt(index);
    _jobs.remove(dreamId);
    _linkDecisions.removeWhere((decision) => decision.dreamId == dreamId);
    _cancelDreamProgress(dream, keepDreamReference: false);
    _notify();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _changes.close();
  }

  Stream<T> _watch<T>(T Function() snapshot) {
    _ensureOpen();
    return Stream<T>.multi((controller) {
      controller.add(snapshot());
      final subscription = _changes.stream.listen((_) {
        controller.add(snapshot());
      }, onDone: controller.close);
      controller.onCancel = subscription.cancel;
    });
  }

  void _notify() {
    _changes.add(null);
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError('MemoryRepository has been disposed');
    }
  }

  int _dreamIndex(String dreamId) {
    final index = _dreams.indexWhere((dream) => dream.id == dreamId);
    if (index < 0) {
      throw StateError('Dream not found: $dreamId');
    }
    return index;
  }

  int _sceneIndex(String sceneId) {
    final index = _scenes.indexWhere((scene) => scene.id == sceneId);
    if (index < 0) {
      throw StateError('Scene not found: $sceneId');
    }
    return index;
  }

  int _passageIndex(String passageId) {
    final index = _passages.indexWhere((passage) => passage.id == passageId);
    if (index < 0) {
      throw StateError('Passage not found: $passageId');
    }
    return index;
  }

  void _removeDerivedContent(String dreamId) {
    final sceneIds = _scenes
        .where((scene) => scene.sourceDreamIds.contains(dreamId))
        .map((scene) => scene.id)
        .toSet();
    _scenes.removeWhere((scene) => sceneIds.contains(scene.id));
    _passages.removeWhere((passage) => sceneIds.contains(passage.sceneId));
  }

  void _detachDreamSources(String dreamId) {
    for (var index = 0; index < _scenes.length; index++) {
      final scene = _scenes[index];
      if (scene.sourceDreamIds.contains(dreamId)) {
        _scenes[index] = scene.copyWith(
          sourceDreamIds: [
            for (final id in scene.sourceDreamIds)
              if (id != dreamId) id,
          ],
        );
      }
    }

    for (var index = 0; index < _passages.length; index++) {
      final passage = _passages[index];
      if (passage.sourceDreamId != dreamId) {
        continue;
      }
      if (passage.origin == PassageOrigin.dream) {
        _passages[index] = passage.copyWith(
          origin: PassageOrigin.connection,
          sourceDreamId: null,
          sourceElementIds: const [],
          cReason: '출처 꿈이 삭제되었습니다',
        );
      } else {
        _passages[index] = passage.copyWith(sourceDreamId: null);
      }
    }
  }

  void _cancelDreamProgress(Dream dream, {required bool keepDreamReference}) {
    final volume = _volume;
    if (volume == null || dream.volumeId != volume.id) {
      return;
    }
    final validRecallAnswers = dream.recallAnswers.values
        .where((answer) => answer.trim().isNotEmpty && answer != '모름')
        .length;
    final delta = materialUnits(
      clarity: dream.clarity ?? DreamClarity.fragment,
      recallAnswers: validRecallAnswers,
      userPassages: 0,
    );
    _volume = volume.copyWith(
      progressMu: (volume.progressMu - delta).clamp(0, volume.targetMu),
    );
    _progressEvents.add(
      ProgressEvent(
        id: _uuid.v4(),
        volumeId: volume.id,
        dreamId: keepDreamReference ? dream.id : null,
        deltaMu: -delta,
        reasons: const [
          {'type': 'dream_removed', 'n': 1},
        ],
        createdAt: _now().toUtc(),
      ),
    );
  }

  static Volume _seedVolume() {
    return Volume(
      id: MemorySeedIds.volume,
      volNo: 1,
      title: null,
      format: VolumeFormat.novella,
      adaptation: AdaptationLevel.balanced,
      style: WritingStyle.plain,
      narrativeVoice: NarrativeVoice.thirdPersonPast,
      status: VolumeStatus.active,
      progressMu: 33.5,
      targetMu: 80,
      genreProfile: const {'미스터리': 0.6, '초현실': 0.4},
      coverMotifId: 'red-door-water',
      prologueSceneId: '00000000-0000-4000-8000-000000000201',
    );
  }

  static List<Dream> _seedDreams() {
    return [
      _seedDream(
        suffix: '107',
        date: DateTime(2026, 9, 13),
        rawText: '복도 바닥에 물이 차 있었고 끝에 붉은 문이 있었다.',
        clarity: DreamClarity.vivid,
        recallAnswers: const {
          'light': '어두움',
          'company': '모르는 사람',
          'feeling': '불안',
        },
      ),
      _seedDream(
        suffix: '106',
        date: DateTime(2026, 9, 11),
        rawText: '비어 있는 학교 복도를 계속 걸었다.',
        clarity: DreamClarity.partial,
      ),
      _seedDream(
        suffix: '105',
        date: DateTime(2026, 9, 7),
        rawText: '전화기에서 누군가의 숨소리만 들렸다.',
        clarity: DreamClarity.partial,
      ),
      _seedDream(
        suffix: '104',
        date: DateTime(2026, 9, 3),
        rawText: '이름 모를 역에서 우산을 든 사람을 봤다.',
        clarity: DreamClarity.vivid,
      ),
      _seedDream(
        suffix: '103',
        date: DateTime(2026, 9, 1),
        rawText: '작은 열쇠가 손바닥 위에 있었다.',
        clarity: DreamClarity.fragment,
        status: DreamStatus.archivedOnly,
      ),
      _seedDream(
        suffix: '102',
        date: DateTime(2026, 8, 28),
        rawText: '버스의 맨 뒷자리에 혼자 앉아 있었다.',
        clarity: DreamClarity.partial,
      ),
      _seedDream(
        suffix: '101',
        date: DateTime(2026, 8, 23),
        rawText: '계단 아래에서 파도 소리가 들려왔다.',
        clarity: DreamClarity.vivid,
      ),
    ];
  }

  static Dream _seedDream({
    required String suffix,
    required DateTime date,
    required String rawText,
    required DreamClarity clarity,
    Map<String, String> recallAnswers = const {},
    DreamStatus status = DreamStatus.inManuscript,
  }) {
    return Dream(
      id: '00000000-0000-4000-8000-000000000$suffix',
      volumeId: MemorySeedIds.volume,
      dreamDate: date,
      recordedAt: DateTime.utc(date.year, date.month, date.day, 6, 30),
      inputMode: DreamInputMode.voice,
      rawText: rawText,
      recallAnswers: recallAnswers,
      clarity: clarity,
      status: status,
      isBackfill: false,
    );
  }

  static List<Scene> _seedScenes() {
    const titles = [
      '문이 생기기 전',
      '젖은 계단',
      '마지막 버스',
      '손바닥의 열쇠',
      '이름 모를 역',
      '전화기 너머',
      '빈 교실',
      '잠긴 창문',
      '물 위의 종소리',
      '긴 복도',
      '붉은 문',
    ];
    const dreamSuffixes = [
      '101',
      '101',
      '102',
      '103',
      '104',
      '105',
      '106',
      '106',
      '107',
      '107',
      '107',
    ];

    return [
      for (var index = 0; index < titles.length; index++)
        Scene(
          id: '00000000-0000-4000-8000-${(201 + index).toString().padLeft(12, '0')}',
          volumeId: MemorySeedIds.volume,
          orderKey: 'a${(index + 1).toString().padLeft(2, '0')}',
          chapterNo: index < 4 ? 1 : (index < 8 ? 2 : 3),
          kind: index == 0 ? SceneKind.prologue : SceneKind.dream,
          placement: index == 0
              ? PlacementKind.standalone
              : PlacementKind.continuation,
          title: titles[index],
          sourceDreamIds: [
            '00000000-0000-4000-8000-000000000${dreamSuffixes[index]}',
          ],
          openImage: index == titles.length - 1
              ? '문틈으로 물소리가 새어 나오고 있었다.'
              : null,
        ),
    ];
  }

  static List<Passage> _seedPassages() {
    const dreamId = MemorySeedIds.latestDream;
    const sceneId = MemorySeedIds.readerScene;
    return [
      Passage(
        id: '00000000-0000-4000-8000-000000000301',
        sceneId: sceneId,
        orderKey: 'a01',
        text: '복도는 생각보다 길었다. 발밑의 물은 발목까지 차 있었고, 걸음을 옮길 때마다 어딜가서 작은 종소리가 났다.',
        origin: PassageOrigin.dream,
        sourceDreamId: dreamId,
        sourceElementIds: const ['00000000-0000-4000-8000-000000000401'],
        cReason: null,
        originalText: null,
        locked: false,
        firstReadAt: null,
      ),
      Passage(
        id: MemorySeedIds.editablePassage,
        sceneId: sceneId,
        orderKey: 'a02',
        text: '그 문은 2장에서 본 적 있는 색이었다. 가까이 갈수록 붉은 색은 물 위로 번져, 복도 전체가 느리게 밝아졌다.',
        origin: PassageOrigin.connection,
        sourceDreamId: dreamId,
        sourceElementIds: const [],
        cReason: '2장의 붉은 문과 오늘의 문을 잇는 문장',
        originalText: null,
        locked: false,
        firstReadAt: null,
      ),
      Passage(
        id: '00000000-0000-4000-8000-000000000303',
        sceneId: sceneId,
        orderKey: 'a03',
        text: '우산을 든 여자가 문 옆에 서 있었다. 여자는 고개를 들지 않은 채 손잡이를 세 번 두드렸다.',
        origin: PassageOrigin.dream,
        sourceDreamId: dreamId,
        sourceElementIds: const ['00000000-0000-4000-8000-000000000402'],
        cReason: null,
        originalText: null,
        locked: false,
        firstReadAt: null,
      ),
      Passage(
        id: '00000000-0000-4000-8000-000000000304',
        sceneId: sceneId,
        orderKey: 'a04',
        text: '나는 그 소리가 안에서 나는 것이 아니라는 걸 알고 있었다.',
        origin: PassageOrigin.user,
        sourceDreamId: null,
        sourceElementIds: const [],
        cReason: null,
        originalText: null,
        locked: true,
        firstReadAt: null,
      ),
      Passage(
        id: '00000000-0000-4000-8000-000000000305',
        sceneId: sceneId,
        orderKey: 'a05',
        text: '문틈으로 물소리가 새어 나오고 있었다.',
        origin: PassageOrigin.dream,
        sourceDreamId: dreamId,
        sourceElementIds: const ['00000000-0000-4000-8000-000000000403'],
        cReason: null,
        originalText: null,
        locked: false,
        firstReadAt: null,
      ),
    ];
  }

  static List<ProgressEvent> _seedProgressEvents() {
    return [
      ProgressEvent(
        id: '00000000-0000-4000-8000-000000000601',
        volumeId: MemorySeedIds.volume,
        dreamId: MemorySeedIds.latestDream,
        deltaMu: 3.75,
        reasons: const [
          {'type': 'new_scene', 'n': 1},
          {'type': 'recall', 'n': 3},
        ],
        createdAt: DateTime.utc(2026, 9, 13, 7),
      ),
      ProgressEvent(
        id: '00000000-0000-4000-8000-000000000602',
        volumeId: MemorySeedIds.volume,
        dreamId: '00000000-0000-4000-8000-000000000106',
        deltaMu: 2,
        reasons: const [
          {'type': 'new_scene', 'n': 1},
        ],
        createdAt: DateTime.utc(2026, 9, 11, 7),
      ),
    ];
  }

  static List<LinkDecision> _seedLinkDecisions() {
    return [
      LinkDecision(
        id: MemorySeedIds.linkDecision,
        dreamId: MemorySeedIds.latestDream,
        kind: LinkDecisionKind.entityMerge,
        payload: const {
          'element_id': '00000000-0000-4000-8000-000000000402',
          'candidate_entity_id': '00000000-0000-4000-8000-000000000701',
        },
        status: LinkDecisionStatus.pending,
      ),
    ];
  }
}
