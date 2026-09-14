import 'package:mumumong/data/memory/memory_repository.dart';

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
}
