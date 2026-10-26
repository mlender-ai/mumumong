import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

class RepositoryContractHarness {
  const RepositoryContractHarness({
    required this.repository,
    required this.dispose,
    required this.volumeId,
    required this.latestDreamId,
    required this.readerSceneId,
    required this.editablePassageId,
    required this.linkDecisionId,
  });

  final MumumongRepository repository;
  final FutureOr<void> Function() dispose;
  final String volumeId;
  final String latestDreamId;
  final String readerSceneId;
  final String editablePassageId;
  final String linkDecisionId;
}

typedef RepositoryContractFactory =
    FutureOr<RepositoryContractHarness> Function();

void runRepositoryContract(
  String implementationName,
  RepositoryContractFactory createHarness,
) {
  group('$implementationName repository contract', () {
    late RepositoryContractHarness harness;
    late MumumongRepository repository;

    setUp(() async {
      harness = await createHarness();
      repository = harness.repository;
    });

    tearDown(() async {
      await harness.dispose();
    });

    test(
      'presentation reservation is atomic, per kind, and never marks reading',
      () async {
        final scenes = await repository.watchScenes(harness.volumeId).first;
        final scene = scenes.last;
        final before = await repository.watchPassages(scene.id).first;
        final claims = await Future.wait(
          List.generate(
            8,
            (_) => repository.consumePresentation(
              volumeId: harness.volumeId,
              kind: PresentationKind.reveal,
              sourceId: scene.id,
            ),
          ),
        );
        expect(claims.where((fresh) => fresh), hasLength(1));
        final after = await repository.watchPassages(scene.id).first;
        expect(
          after.map((p) => (p.id, p.text, p.origin, p.locked, p.firstReadAt)),
          before.map((p) => (p.id, p.text, p.origin, p.locked, p.firstReadAt)),
        );
        final event =
            (await repository.watchRecentProgress(harness.volumeId).first)
                .firstWhere((e) => e.deltaMu > 0);
        expect(
          await repository.consumePresentation(
            volumeId: harness.volumeId,
            kind: PresentationKind.growth,
            sourceId: event.id,
          ),
          isTrue,
        );
        expect(
          await repository.consumePresentation(
            volumeId: harness.volumeId,
            kind: PresentationKind.growth,
            sourceId: event.id,
          ),
          isFalse,
        );
      },
    );

    test(
      'already read scene is not celebrated; foreign/missing sources are rejected',
      () async {
        final scene =
            (await repository.watchScenes(harness.volumeId).first).last;
        final first = (await repository.watchPassages(scene.id).first).first;
        await repository.markPassageRead(first.id);
        expect(
          await repository.consumePresentation(
            volumeId: harness.volumeId,
            kind: PresentationKind.reveal,
            sourceId: scene.id,
          ),
          isFalse,
        );
        for (final (volumeId, sourceId) in [
          ('foreign-volume', scene.id),
          (harness.volumeId, 'missing-scene'),
        ]) {
          await expectLater(
            repository.consumePresentation(
              volumeId: volumeId,
              kind: PresentationKind.reveal,
              sourceId: sourceId,
            ),
            throwsStateError,
          );
        }
        await expectLater(
          repository.consumePresentation(
            volumeId: harness.volumeId,
            kind: PresentationKind.growth,
            sourceId: scene.id,
          ),
          throwsStateError,
        );
      },
    );

    test('exposes the complete prototype fixture in stable order', () async {
      final volume = await repository.watchActiveVolume().first;
      expect(volume?.id, harness.volumeId);
      expect(((volume!.progressMu / volume.targetMu) * 100).round(), 42);

      final dreams = await repository.watchDreams(DreamStatusFilter.all).first;
      expect(dreams, hasLength(7));
      expect(dreams.first.id, harness.latestDreamId);

      final scenes = await repository.watchScenes(harness.volumeId).first;
      expect(scenes, hasLength(11));
      expect(scenes.last.id, harness.readerSceneId);

      final passages = await repository
          .watchPassages(harness.readerSceneId)
          .first;
      expect(passages, hasLength(5));
      expect(passages.map((passage) => passage.origin), [
        PassageOrigin.dream,
        PassageOrigin.connection,
        PassageOrigin.dream,
        PassageOrigin.user,
        PassageOrigin.dream,
      ]);
    });

    test('filters manuscript and archive dreams with typed statuses', () async {
      final manuscript = await repository
          .watchDreams(DreamStatusFilter.inManuscript)
          .first;
      final archived = await repository
          .watchDreams(DreamStatusFilter.archivedOnly)
          .first;

      expect(manuscript, hasLength(6));
      expect(
        manuscript.every((dream) => dream.status == DreamStatus.inManuscript),
        isTrue,
      );
      expect(archived, hasLength(1));
      expect(archived.single.status, DreamStatus.archivedOnly);
    });

    test('saves, replaces, loads, and clears one draft', () async {
      final draft = _draft('draft-save');
      await repository.saveDraft(draft);

      var loaded = await repository.loadDraft();
      expect(loaded?.id, draft.id);
      expect(loaded?.rawText, draft.rawText);

      await repository.saveDraft(draft.copyWith(rawText: '수정된 초안'));
      loaded = await repository.loadDraft();
      expect(loaded?.rawText, '수정된 초안');

      await repository.clearDraft();
      expect(await repository.loadDraft(), isNull);
      await repository.clearDraft();
      expect(await repository.loadDraft(), isNull);
    });

    test(
      'optional recall persists without starting processing and then locks',
      () async {
        final id = await repository.submitDream(_draft('p3-recall-only'));
        await repository.saveRecallAnswers(id, {'light': '밝음'});
        final dream =
            (await repository.watchDreams(DreamStatusFilter.all).first)
                .firstWhere((d) => d.id == id);
        expect(dream.status, DreamStatus.queued);
        expect(dream.recallAnswers, {'light': '밝음'});
        expect((await repository.watchJob(id).first)?.status, JobStatus.queued);
        await repository.answerRecall(id, dream.recallAnswers);
        await expectLater(
          repository.saveRecallAnswers(id, {'light': '어두움'}),
          throwsStateError,
        );
      },
    );

    test(
      'actual job failure persists; stale failures and starts cannot downgrade completed dreams',
      () async {
        final id = await repository.submitDream(_draft('p4-job-state'));
        await repository.answerRecall(id, {'light': '밝음'});
        await repository.answerRecall(id, {'light': '어두움'});
        expect(
          (await repository.watchDreams(DreamStatusFilter.all).first)
              .singleWhere((d) => d.id == id)
              .recallAnswers,
          {'light': '밝음'},
        );
        await repository.recordJobProgress(
          JobProgress(
            dreamId: id,
            type: JobType.validate,
            status: JobStatus.failed,
            attempt: 3,
            stageLabel: '장면을 만들지 못했어요',
          ),
        );
        expect((await repository.watchJob(id).first)?.status, JobStatus.failed);
        expect(
          (await repository.watchDreams(DreamStatusFilter.all).first)
              .singleWhere((d) => d.id == id)
              .status,
          DreamStatus.failed,
        );
        // A real retry (including one started on another client) must rejoin
        // shell recovery instead of remaining stuck in a cached failed state.
        await repository.recordJobProgress(
          JobProgress(
            dreamId: id,
            type: JobType.extract,
            status: JobStatus.queued,
            attempt: 0,
            stageLabel: '재시도 접수됨',
          ),
        );
        expect(
          (await repository.watchDreams(DreamStatusFilter.all).first)
              .singleWhere((d) => d.id == id)
              .status,
          DreamStatus.processing,
        );
        await repository.recordJobProgress(
          JobProgress(
            dreamId: harness.latestDreamId,
            type: JobType.validate,
            status: JobStatus.failed,
            attempt: 3,
            stageLabel: '오래된 실패',
          ),
        );
        final completed =
            (await repository.watchDreams(DreamStatusFilter.all).first)
                .singleWhere((d) => d.id == harness.latestDreamId);
        expect(completed.status, DreamStatus.inManuscript);
        await expectLater(
          repository.answerRecall(completed.id, {}),
          throwsStateError,
        );
      },
    );

    test('stores a volume-specific scene and paragraph bookmark', () async {
      expect(await repository.loadReaderPosition(harness.volumeId), isNull);
      final scene = (await repository.watchScenes(harness.volumeId).first).last;
      final passage = (await repository.watchPassages(scene.id).first).first;
      final position = ReaderPosition(
        volumeId: harness.volumeId,
        sceneId: scene.id,
        sceneOrderKey: scene.orderKey,
        passageId: passage.id,
        passageOrderKey: passage.orderKey,
        passageFraction: .4,
        offset: 120,
        updatedAt: DateTime.utc(2026, 10, 15),
      );
      await repository.saveReaderPosition(position);
      final loaded = await repository.loadReaderPosition(harness.volumeId);
      expect(loaded?.sceneId, scene.id);
      expect(loaded?.passageId, passage.id);
      expect(loaded?.passageFraction, .4);
      expect(
        await repository.loadReaderPosition('another-owner-volume'),
        isNull,
      );
    });

    test('rejects foreign or invalid reading anchors', () async {
      final scene = (await repository.watchScenes(harness.volumeId).first).last;
      for (final position in [
        ReaderPosition(
          volumeId: 'foreign',
          sceneId: scene.id,
          updatedAt: DateTime.utc(2026),
        ),
        ReaderPosition(
          volumeId: harness.volumeId,
          sceneId: scene.id,
          passageId: 'foreign-passage',
          updatedAt: DateTime.utc(2026),
        ),
        ReaderPosition(
          volumeId: harness.volumeId,
          sceneId: scene.id,
          passageFraction: 2,
          updatedAt: DateTime.utc(2026),
        ),
      ]) {
        await expectLater(
          repository.saveReaderPosition(position),
          throwsStateError,
        );
      }
      expect(await repository.loadReaderPosition(harness.volumeId), isNull);
    });

    test('submits a dream idempotently and exposes its queued job', () async {
      final draft = _draft('00000000-0000-4000-8000-000000009001');
      await repository.saveDraft(draft);
      final emitted = repository
          .watchDreams(DreamStatusFilter.all)
          .firstWhere((dreams) => dreams.any((dream) => dream.id == draft.id));

      final dreamId = await repository.submitDream(draft);
      expect(dreamId, draft.id);
      expect(await emitted, hasLength(8));
      expect(await repository.loadDraft(), isNull);

      expect(await repository.submitDream(draft), draft.id);
      final dreams = await repository.watchDreams(DreamStatusFilter.all).first;
      expect(dreams.where((dream) => dream.id == draft.id), hasLength(1));

      final job = await repository.watchJob(dreamId).first;
      expect(job?.type, JobType.extract);
      expect(job?.status, JobStatus.queued);
      expect(job?.attempt, 0);
    });

    test('stores recall answers and advances the processing state', () async {
      final draft = _draft('00000000-0000-4000-8000-000000009002');
      final dreamId = await repository.submitDream(draft);
      final processing = repository
          .watchDreams(DreamStatusFilter.all)
          .firstWhere(
            (dreams) => dreams.any(
              (dream) =>
                  dream.id == dreamId && dream.status == DreamStatus.processing,
            ),
          );

      await repository.answerRecall(dreamId, const {
        'light': '어두움',
        'company': '모르는 사람',
      });

      final dream = (await processing).singleWhere(
        (dream) => dream.id == dreamId,
      );
      expect(dream.recallAnswers['light'], '어두움');
      final job = await repository.watchJob(dreamId).first;
      expect(job?.status, JobStatus.running);
      expect(job?.attempt, 1);
    });

    test('edits a stored dream without changing its derived status', () async {
      final before = (await repository.watchDreams(DreamStatusFilter.all).first)
          .singleWhere((dream) => dream.id == harness.latestDreamId);

      await repository.updateDreamText(harness.latestDreamId, '수정한 꿈 원문');

      final after = (await repository.watchDreams(DreamStatusFilter.all).first)
          .singleWhere((dream) => dream.id == harness.latestDreamId);
      expect(after.rawText, '수정한 꿈 원문');
      expect(after.status, before.status);
      expect(after.clarity, before.clarity);
    });

    test('changes placement and emits a new scene snapshot', () async {
      final changed = repository
          .watchScenes(harness.volumeId)
          .firstWhere(
            (scenes) => scenes.any(
              (scene) =>
                  scene.id == harness.readerSceneId &&
                  scene.placement == PlacementKind.interlude,
            ),
          );

      await repository.changePlacement(
        harness.readerSceneId,
        PlacementKind.interlude,
      );

      final scene = (await changed).singleWhere(
        (scene) => scene.id == harness.readerSceneId,
      );
      expect(scene.placement, PlacementKind.interlude);
    });

    test('edits to locked U, reverts, and records first read once', () async {
      final before =
          (await repository.watchPassages(harness.readerSceneId).first)
              .singleWhere(
                (passage) => passage.id == harness.editablePassageId,
              );

      await repository.editPassage(harness.editablePassageId, '내가 고친 문장');
      var passage =
          (await repository.watchPassages(harness.readerSceneId).first)
              .singleWhere((item) => item.id == harness.editablePassageId);
      expect(passage.text, '내가 고친 문장');
      expect(passage.origin, PassageOrigin.user);
      expect(passage.locked, isTrue);
      expect(passage.originalText, before.text);

      await repository.revertPassage(harness.editablePassageId);
      passage = (await repository.watchPassages(harness.readerSceneId).first)
          .singleWhere((item) => item.id == harness.editablePassageId);
      expect(passage.text, before.text);
      expect(passage.origin, before.origin);
      expect(passage.locked, isFalse);
      expect(passage.originalText, isNull);

      await repository.markPassageRead(harness.editablePassageId);
      final firstReadAt =
          (await repository.watchPassages(harness.readerSceneId).first)
              .singleWhere((item) => item.id == harness.editablePassageId)
              .firstReadAt;
      expect(firstReadAt, isNotNull);

      await repository.markPassageRead(harness.editablePassageId);
      passage = (await repository.watchPassages(harness.readerSceneId).first)
          .singleWhere((item) => item.id == harness.editablePassageId);
      expect(passage.firstReadAt, firstReadAt);
    });

    test('records a link choice once and adds explainable MU', () async {
      final before = await repository.watchActiveVolume().first;
      final progress = repository
          .watchRecentProgress(harness.volumeId)
          .firstWhere(
            (events) => events.any(
              (event) => event.reasons.any(
                (reason) => reason['type'] == 'link_decision',
              ),
            ),
          );

      await repository.decideLink(harness.linkDecisionId, LinkChoice.same);

      final after = await repository.watchActiveVolume().first;
      expect(after!.progressMu, before!.progressMu + 0.5);
      expect((await progress).first.deltaMu, 0.5);
      await expectLater(
        repository.decideLink(harness.linkDecisionId, LinkChoice.different),
        throwsStateError,
      );
    });

    test(
      'removes a dream-derived scene but keeps the archived dream',
      () async {
        await repository.removeDreamFromManuscript(harness.latestDreamId);

        final archived = await repository
            .watchDreams(DreamStatusFilter.archivedOnly)
            .first;
        expect(
          archived.any((dream) => dream.id == harness.latestDreamId),
          isTrue,
        );
        final scenes = await repository.watchScenes(harness.volumeId).first;
        expect(
          scenes.any((scene) => scene.id == harness.readerSceneId),
          isFalse,
        );
        expect(
          await repository.watchPassages(harness.readerSceneId).first,
          isEmpty,
        );
        expect(
          (await repository.watchActiveVolume().first)!.progressMu,
          lessThan(33.5),
        );
      },
    );

    test('default deletion removes the dream and derived scene', () async {
      await repository.deleteDream(
        harness.latestDreamId,
        DeleteMode.deleteDerivedContent,
      );

      final dreams = await repository.watchDreams(DreamStatusFilter.all).first;
      expect(dreams.any((dream) => dream.id == harness.latestDreamId), isFalse);
      final scenes = await repository.watchScenes(harness.volumeId).first;
      expect(scenes.any((scene) => scene.id == harness.readerSceneId), isFalse);
    });

    test(
      'keep deletion detaches sources and converts D passages to C',
      () async {
        await repository.deleteDream(
          harness.latestDreamId,
          DeleteMode.keepDerivedContent,
        );

        final scenes = await repository.watchScenes(harness.volumeId).first;
        final scene = scenes.singleWhere(
          (scene) => scene.id == harness.readerSceneId,
        );
        expect(scene.sourceDreamIds, isNot(contains(harness.latestDreamId)));

        final passages = await repository
            .watchPassages(harness.readerSceneId)
            .first;
        expect(passages, hasLength(5));
        for (final passage in passages) {
          expect(passage.sourceDreamId, isNot(harness.latestDreamId));
        }
        final detachedDreamPassages = passages.where(
          (passage) => passage.cReason == '출처 꿈이 삭제되었습니다',
        );
        expect(detachedDreamPassages, hasLength(3));
        expect(
          detachedDreamPassages.every(
            (passage) =>
                passage.origin == PassageOrigin.connection &&
                passage.sourceElementIds.isEmpty,
          ),
          isTrue,
        );
        final userPassage = passages.singleWhere(
          (passage) => passage.origin == PassageOrigin.user,
        );
        expect(userPassage.locked, isTrue);
      },
    );
  });
}

DreamDraft _draft(String id) {
  return DreamDraft(
    id: id,
    rawText: '유리창 너머로 파란 새가 날아갔다.',
    inputMode: DreamInputMode.text,
    dreamDate: DateTime(2026, 9, 15),
    isBackfill: false,
    updatedAt: DateTime.utc(2026, 9, 15, 6),
  );
}
