import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

import 'repository_contract.dart';

void main() {
  runRepositoryContract('MemoryRepository', () {
    final repository = MemoryRepository(
      now: () => DateTime.utc(2026, 9, 15, 7),
    );
    return RepositoryContractHarness(
      repository: repository,
      dispose: repository.dispose,
      volumeId: MemorySeedIds.volume,
      latestDreamId: MemorySeedIds.latestDream,
      readerSceneId: MemorySeedIds.readerScene,
      editablePassageId: MemorySeedIds.editablePassage,
      linkDecisionId: MemorySeedIds.linkDecision,
    );
  });

  test('MemoryRepository completes its screen-wiring mock path', () async {
    final repository = MemoryRepository();
    final engine = MockEngineClient(
      store: repository,
      stageDelay: Duration.zero,
    );
    addTearDown(repository.dispose);
    addTearDown(engine.dispose);
    const dreamId = '00000000-0000-4000-8000-000000009999';
    final dream = DreamDraft(
      id: dreamId,
      rawText: '복도 끝에 파란 문이 있었다.',
      inputMode: DreamInputMode.text,
      dreamDate: DateTime(2026, 9, 15),
      isBackfill: false,
      updatedAt: DateTime.utc(2026, 9, 15, 6),
    );

    await repository.submitDream(dream);
    await repository.answerRecall(dreamId, const {});
    await engine.enqueue(dreamId, 'mock:$dreamId');
    await engine
        .watch(dreamId)
        .firstWhere((job) => job.status == JobStatus.done);

    expect((await repository.watchJob(dreamId).first)?.status, JobStatus.done);
    expect(
      await repository.watchScenes(MemorySeedIds.volume).first,
      hasLength(12),
    );
  });

  test(
    'generated D passages reference existing elements and deletion clears them',
    () async {
      final repository = MemoryRepository();
      final engine = MockEngineClient(
        store: repository,
        stageDelay: Duration.zero,
      );
      addTearDown(repository.dispose);
      addTearDown(engine.dispose);
      const dreamId = '00000000-0000-4000-8000-000000009998';

      await _processDream(repository, engine, dreamId);

      final elements = await repository.watchDreamElements(dreamId).first;
      final elementIds = elements.map((element) => element.id).toSet();
      final scenes = await repository.watchScenes(MemorySeedIds.volume).first;
      final scene = scenes.singleWhere(
        (candidate) => candidate.sourceDreamIds.contains(dreamId),
      );
      final dreamPassages = (await repository.watchPassages(scene.id).first)
          .where((passage) => passage.origin == PassageOrigin.dream);

      expect(elements, hasLength(4));
      expect(dreamPassages, isNotEmpty);
      for (final passage in dreamPassages) {
        expect(passage.sourceElementIds, hasLength(1));
        expect(elementIds, containsAll(passage.sourceElementIds));
      }

      await repository.deleteDream(dreamId, DeleteMode.deleteDerivedContent);
      expect(await repository.watchDreamElements(dreamId).first, isEmpty);
    },
  );

  test(
    'raw progress equals the event sum above target and after removal',
    () async {
      final repository = MemoryRepository();
      final engine = MockEngineClient(
        store: repository,
        stageDelay: Duration.zero,
      );
      addTearDown(repository.dispose);
      addTearDown(engine.dispose);

      String? lastDreamId;
      for (var index = 0; index < 16; index++) {
        lastDreamId =
            '00000000-0000-4000-8000-${(9900 + index).toString().padLeft(12, '0')}';
        await _processDream(repository, engine, lastDreamId);
      }

      final aboveTarget = await repository.watchActiveVolume().first;
      expect(aboveTarget!.progressMu, greaterThan(aboveTarget.targetMu));

      await repository.removeDreamFromManuscript(lastDreamId!);

      final afterRemoval = await repository.watchActiveVolume().first;
      final events = await repository
          .watchRecentProgress(MemorySeedIds.volume)
          .first;
      final eventSum = events.fold<double>(
        0,
        (sum, event) => sum + event.deltaMu,
      );
      expect(afterRemoval!.progressMu, closeTo(eventSum, 1e-9));
      expect(await repository.watchDreamElements(lastDreamId).first, isEmpty);
    },
  );
}

Future<void> _processDream(
  MemoryRepository repository,
  MockEngineClient engine,
  String dreamId,
) async {
  await repository.submitDream(
    DreamDraft(
      id: dreamId,
      rawText: '복도 끝에 파란 문이 있었다.',
      inputMode: DreamInputMode.text,
      dreamDate: DateTime(2026, 9, 15),
      isBackfill: false,
      updatedAt: DateTime.utc(2026, 9, 15, 6),
    ),
  );
  await repository.answerRecall(dreamId, const {});
  await engine.enqueue(dreamId, 'mock:$dreamId');
  await engine.watch(dreamId).firstWhere((job) => job.status == JobStatus.done);
}
