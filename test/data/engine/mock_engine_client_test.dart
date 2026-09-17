import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

void main() {
  for (final scenario in MockEngineCase.values) {
    test('mock engine completes the ${scenario.name} scenario', () async {
      final repository = MemoryRepository();
      final engine = MockEngineClient(
        store: repository,
        scenario: scenario,
        stageDelay: Duration.zero,
      );
      addTearDown(repository.dispose);
      addTearDown(engine.dispose);

      final dreamId = 'mock-${scenario.name}';
      await _prepareDream(repository, dreamId);
      final events = <JobProgress>[];
      final terminal = Completer<JobProgress>();
      final subscription = engine.watch(dreamId).listen((progress) {
        events.add(progress);
        if (!terminal.isCompleted &&
            (progress.status == JobStatus.done ||
                progress.status == JobStatus.failed)) {
          terminal.complete(progress);
        }
      });
      addTearDown(subscription.cancel);

      await engine.enqueue(dreamId, 'engine:$dreamId');
      final result = await terminal.future.timeout(const Duration(seconds: 2));

      final dream = (await repository.watchDreams(DreamStatusFilter.all).first)
          .singleWhere((candidate) => candidate.id == dreamId);
      final scenes = await repository.watchScenes(MemorySeedIds.volume).first;
      final generated = scenes
          .where((scene) => scene.sourceDreamIds.contains(dreamId))
          .toList();

      if (scenario == MockEngineCase.fail) {
        expect(result.status, JobStatus.failed);
        expect(dream.status, DreamStatus.failed);
        expect(generated, isEmpty);
        expect(
          events.where(
            (event) =>
                event.type == JobType.validate &&
                event.status == JobStatus.running,
          ),
          hasLength(3),
        );
        return;
      }

      expect(result.status, JobStatus.done);
      expect(dream.status, DreamStatus.inManuscript);
      expect(generated, hasLength(1));
      final passages = await repository
          .watchPassages(generated.single.id)
          .first;
      final elements = await repository.watchDreamElements(dreamId).first;
      final elementIds = elements.map((element) => element.id).toSet();

      if (scenario == MockEngineCase.fallback) {
        expect(passages, hasLength(3));
        expect(
          passages.every((passage) => passage.origin == PassageOrigin.dream),
          isTrue,
        );
      } else {
        expect(passages, hasLength(5));
        expect(
          passages.where((passage) => passage.origin == PassageOrigin.dream),
          hasLength(4),
        );
        expect(
          passages.where(
            (passage) => passage.origin == PassageOrigin.connection,
          ),
          hasLength(1),
        );
      }
      for (final passage in passages.where(
        (passage) => passage.origin == PassageOrigin.dream,
      )) {
        expect(passage.sourceElementIds, hasLength(1));
        expect(elementIds, containsAll(passage.sourceElementIds));
      }

      final expectedAttempts = switch (scenario) {
        MockEngineCase.success => 1,
        MockEngineCase.retry => 2,
        MockEngineCase.fallback => 3,
        MockEngineCase.fail => 3,
      };
      expect(result.attempt, expectedAttempts);
      expect(
        events.where(
          (event) =>
              event.type == JobType.validate &&
              event.status == JobStatus.running,
        ),
        hasLength(expectedAttempts),
      );
    });
  }

  test('enqueue is idempotent for the same key', () async {
    final repository = MemoryRepository();
    final engine = MockEngineClient(
      store: repository,
      stageDelay: const Duration(milliseconds: 1),
    );
    addTearDown(repository.dispose);
    addTearDown(engine.dispose);
    const dreamId = 'mock-idempotent';
    await _prepareDream(repository, dreamId);
    final completed = engine
        .watch(dreamId)
        .firstWhere((progress) => progress.status == JobStatus.done);

    final first = await engine.enqueue(dreamId, 'same-key');
    final second = await engine.enqueue(dreamId, 'same-key');
    await completed.timeout(const Duration(seconds: 2));

    expect(second, first);
    final scenes = await repository.watchScenes(MemorySeedIds.volume).first;
    expect(
      scenes.where((scene) => scene.sourceDreamIds.contains(dreamId)),
      hasLength(1),
    );
  });
}

Future<void> _prepareDream(MemoryRepository repository, String dreamId) async {
  await repository.submitDream(
    DreamDraft(
      id: dreamId,
      rawText: '복도 끝에 붉은 문과 우산을 든 여자가 있었다.',
      inputMode: DreamInputMode.text,
      dreamDate: DateTime(2026, 9, 18),
      isBackfill: false,
      updatedAt: DateTime.utc(2026, 9, 18, 7),
    ),
  );
  await repository.answerRecall(dreamId, const {'light': '어두움'});
}
