import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/sync/outbox_worker.dart';

void main() {
  test(
    'three offline dreams drain once in order with stable duplicate keys',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final sent = <String>[];
      final worker = OutboxWorker(db, (op, payload, key) async {
        sent.add(key);
        return DeliveryReceipt.applied;
      });
      for (var i = 0; i < 3; i++) {
        await worker.enqueue(
          operation: 'dream',
          aggregateId: '$i',
          payload: {'id': i},
          idempotencyKey: 'key$i',
        );
      }
      await worker.enqueue(
        operation: 'dream',
        aggregateId: '0',
        payload: {'id': 0},
        idempotencyKey: 'key0',
      );
      await Future.wait([worker.drain(), worker.drain()]);
      await worker.drain();
      expect(sent, ['key0', 'key1', 'key2']);
      await worker.dispose();
    },
  );
  test(
    'failed predecessor blocks its lane but not other dreams; six failures stop',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime.utc(2026);
      final sent = <String>[];
      final worker = OutboxWorker(db, (op, payload, key) async {
        sent.add(key);
        if (key == 'first') throw StateError('offline');
        return DeliveryReceipt.applied;
      }, now: () => now);
      for (final (key, lane) in [
        ('first', 'a'),
        ('second', 'a'),
        ('other', 'b'),
      ]) {
        await worker.enqueue(
          operation: 'dream',
          aggregateId: lane,
          payload: {},
          idempotencyKey: key,
        );
      }
      for (var i = 0; i < 6; i++) {
        await worker.drain();
        now = now.add(Duration(seconds: OutboxWorker.backoffSeconds[i]));
      }
      await worker.drain();
      expect(sent.where((key) => key == 'first'), hasLength(6));
      expect(sent.where((key) => key == 'other'), hasLength(1));
      expect(sent.contains('second'), false);
      final first = await (db.select(
        db.outbox,
      )..where((r) => r.id.equals('first'))).getSingle();
      expect(first.status, 'failed');
      await worker.dispose();
    },
  );
  test(
    'ambiguous response survives reopen and retries the identical key',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-outbox-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/queue.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      var now = DateTime.utc(2026);
      final keys = <String>[];
      final first = OutboxWorker(db, (op, payload, key) async {
        keys.add(key);
        throw TimeoutException('response lost');
      }, now: () => now);
      await first.enqueue(
        operation: 'dream',
        aggregateId: 'a',
        payload: {},
        idempotencyKey: 'stable',
      );
      await first.drain();
      await first.dispose();
      await db.close();
      now = now.add(const Duration(seconds: 1));
      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      final second = OutboxWorker(reopened, (op, payload, key) async {
        keys.add(key);
        return DeliveryReceipt.alreadyApplied;
      }, now: () => now);
      await second.drain();
      expect(keys, ['stable', 'stable']);
      expect(
        (await reopened.select(reopened.outbox).getSingle()).status,
        'done',
      );
      await second.dispose();
      await reopened.close();
    },
  );
}
