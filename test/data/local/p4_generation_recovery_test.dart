import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

class _ObservationOnlyEngine implements EngineClient {
  final controller = StreamController<JobProgress>.broadcast();
  int watches = 0;
  @override
  Future<String> enqueue(String dreamId, String key) =>
      throw StateError('unexpected_enqueue');
  @override
  Future<String> retry(String dreamId) => throw StateError('unexpected_retry');
  @override
  Stream<JobProgress> watch(String dreamId) {
    watches++;
    return controller.stream;
  }
}

void main() {
  test(
    'SQLite close/reopen restores observation and terminal failure metadata',
    () async {
      final directory = await Directory.systemTemp.createTemp('mumumong-p4-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/synthetic.sqlite');
      final first = AppDatabase.forTesting(NativeDatabase(file));
      final repo = DriftRepository(first, queueCloudMutations: true);
      final id = await repo.submitDream(
        DreamDraft(
          id: 'p4-sqlite-dream',
          rawText: '나는 물 위의 작은 도서관 문을 열었다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      await repo.answerRecall(id, {});
      await first.close();

      final second = AppDatabase.forTesting(NativeDatabase(file));
      final restored = DriftRepository(second, queueCloudMutations: true);
      final engine = _ObservationOnlyEngine();
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(restored),
          engineClientProvider.overrideWithValue(engine),
        ],
      );
      container.listen(generationRecoveryProvider, (_, _) {});
      await container.read(dreamsProvider(DreamStatusFilter.all).future);
      await container.pump();
      await container.read(jobProgressProvider(id).future);
      expect(engine.watches, 1);
      final terminal = restored
          .watchDreams(DreamStatusFilter.all)
          .firstWhere(
            (dreams) =>
                dreams.any((d) => d.id == id && d.status == DreamStatus.failed),
          );
      engine.controller.add(
        JobProgress(
          dreamId: id,
          type: JobType.validate,
          status: JobStatus.failed,
          attempt: 3,
          stageLabel: '실제 실패 fixture',
        ),
      );
      await terminal.timeout(const Duration(seconds: 5));
      container.dispose();
      await engine.controller.close();
      await second.close();

      final third = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(third.close);
      final finalRepo = DriftRepository(third, queueCloudMutations: true);
      expect((await finalRepo.watchJob(id).first)?.status, JobStatus.failed);
      expect(
        (await finalRepo.watchDreams(DreamStatusFilter.all).first)
            .singleWhere((d) => d.id == id)
            .status,
        DreamStatus.failed,
      );
      final operations = await third.select(third.outbox).get();
      expect(operations.map((op) => op.op), ['create_dream', 'process_dream']);
    },
  );
}
