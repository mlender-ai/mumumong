import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/sync/outbox_worker.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

void main() {
  test(
    'saved-only dream reopens queued and outbox never starts generation without intent',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-saved-only-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fixture.sqlite');
      final first = AppDatabase.forTesting(NativeDatabase(file));
      final repo = DriftRepository(first, queueCloudMutations: true);
      final id = await repo.submitDream(
        DreamDraft(
          id: 'p3-synthetic-saved',
          rawText: '투명한 계단 위로 종이 우산이 올라갔다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      final delivered = <String>[];
      final worker = OutboxWorker(first, (op, payload, key) async {
        delivered.add(op);
        return DeliveryReceipt.applied;
      });
      await worker.drain();
      expect(delivered, ['create_dream']);
      expect((await repo.watchJob(id).first)?.status, JobStatus.queued);
      await repo.saveRecallAnswers(id, {'light': '밝음'});
      await worker.drain();
      expect(delivered, ['create_dream', 'create_dream']);
      await worker.dispose();
      await first.close();

      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(reopened.close);
      final restored = DriftRepository(reopened, queueCloudMutations: true);
      final saved = (await restored.watchDreams(DreamStatusFilter.all).first)
          .singleWhere((d) => d.id == id);
      expect(saved.status, DreamStatus.queued);
      expect(saved.recallAnswers, {'light': '밝음'});
      final nextWorker = OutboxWorker(reopened, (op, payload, key) async {
        delivered.add(op);
        return DeliveryReceipt.applied;
      });
      await nextWorker.drain();
      expect(delivered, ['create_dream', 'create_dream']);
      await restored.answerRecall(id, {'light': '밝음'});
      await nextWorker.drain();
      expect(delivered, ['create_dream', 'create_dream', 'process_dream']);
      expect(
        (await restored.watchDreams(DreamStatusFilter.all).first)
            .singleWhere((d) => d.id == id)
            .recallAnswers,
        {'light': '밝음'},
      );
      await nextWorker.dispose();
    },
  );
}
