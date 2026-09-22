import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/domain/model/models.dart';

class FakeGateway implements RemoteEngineGateway {
  @override
  String? currentUserId = 'user';
  String? existing;
  bool conflict = false;
  int inserts = 0;
  final changes = StreamController<List<RemoteJobRecord>>.broadcast();
  @override
  Future<String> findDreamVolume(String dreamId) async => 'volume';
  @override
  Future<String?> findJobByKey(String userId, String key) async => existing;
  @override
  Future<String?> insertExtractJob({
    required String id,
    required String userId,
    required String dreamId,
    required String volumeId,
    required String idempotencyKey,
  }) async {
    inserts++;
    if (conflict) {
      existing = 'concurrent';
      return null;
    }
    existing = id;
    return id;
  }

  @override
  Stream<List<RemoteJobRecord>> watchJobs(String dreamId) => changes.stream;
}

void main() {
  test('enqueue is idempotent before and across a concurrent insert', () async {
    final gateway = FakeGateway();
    final client = RemoteEngineClient(
      gateway,
      idGenerator: () => '00000000-0000-4000-8000-000000000999',
    );
    expect(
      await client.enqueue('dream', 'key'),
      '00000000-0000-4000-8000-000000000999',
    );
    expect(
      await client.enqueue('dream', 'key'),
      '00000000-0000-4000-8000-000000000999',
    );
    expect(gateway.inserts, 1);
    gateway.existing = null;
    gateway.conflict = true;
    expect(await client.enqueue('dream', 'other'), 'concurrent');
  });

  test(
    'watch emits actual database stage and suppresses exact duplicates',
    () async {
      final gateway = FakeGateway();
      final client = RemoteEngineClient(gateway);
      final values = <JobProgress>[];
      final subscription = client.watch('dream').listen(values.add);
      const running = RemoteJobRecord(
        id: 'j',
        dreamId: 'dream',
        type: 'write',
        status: 'running',
        attempt: 1,
      );
      gateway.changes.add([running]);
      gateway.changes.add([running]);
      gateway.changes.add(const [
        RemoteJobRecord(
          id: 'j',
          dreamId: 'dream',
          type: 'validate',
          status: 'running',
          attempt: 1,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(values.map((value) => value.type), [
        JobType.write,
        JobType.validate,
      ]);
      expect(values.first.stageLabel, '장면을 쓰는 중');
      await subscription.cancel();
      await gateway.changes.close();
    },
  );

  test('enqueue requires a signed-in owner', () async {
    final gateway = FakeGateway()..currentUserId = null;
    await expectLater(
      RemoteEngineClient(gateway).enqueue('dream', 'key'),
      throwsA(isA<StateError>()),
    );
    await gateway.changes.close();
  });
}
