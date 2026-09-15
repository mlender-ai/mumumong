import 'package:flutter_test/flutter_test.dart';
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
    final repository = MemoryRepository(processingDelay: Duration.zero);
    addTearDown(repository.dispose);
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
    await Future<void>.delayed(Duration.zero);

    expect((await repository.watchJob(dreamId).first)?.status, JobStatus.done);
    expect(
      await repository.watchScenes(MemorySeedIds.volume).first,
      hasLength(12),
    );
  });
}
