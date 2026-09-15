import 'package:drift/native.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/memory/memory_repository.dart';

import 'repository_contract.dart';

void main() {
  runRepositoryContract('DriftRepository', () {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = DriftRepository(
      database,
      now: () => DateTime.utc(2026, 9, 15, 7),
    );
    return RepositoryContractHarness(
      repository: repository,
      dispose: database.close,
      volumeId: MemorySeedIds.volume,
      latestDreamId: MemorySeedIds.latestDream,
      readerSceneId: MemorySeedIds.readerScene,
      editablePassageId: MemorySeedIds.editablePassage,
      linkDecisionId: MemorySeedIds.linkDecision,
    );
  });
}
