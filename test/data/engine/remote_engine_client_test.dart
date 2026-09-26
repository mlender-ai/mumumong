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
  int kicks = 0;
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
  Future<void> kickWorker() async {
    kicks++;
  }

  @override
  Stream<List<RemoteJobRecord>> watchJobs(String dreamId) => changes.stream;
}

class FakeSync implements RemoteEngineSync {
  final pushed = <String>[];
  final pulled = <String>[];

  @override
  Future<void> pullDreamResult(String dreamId) async => pulled.add(dreamId);

  @override
  Future<void> pushDream(String dreamId) async => pushed.add(dreamId);
}

void main() {
  test('enqueue is idempotent before and across a concurrent insert', () async {
    final gateway = FakeGateway();
    final sync = FakeSync();
    final client = RemoteEngineClient(
      gateway,
      sync: sync,
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
    expect(gateway.kicks, 2);
    expect(sync.pushed, ['dream', 'dream']);
    gateway.existing = null;
    gateway.conflict = true;
    expect(await client.enqueue('dream', 'other'), 'concurrent');
    expect(gateway.kicks, 3);
  });

  test(
    'watch emits actual database stage and suppresses exact duplicates',
    () async {
      final gateway = FakeGateway();
      final sync = FakeSync();
      final client = RemoteEngineClient(gateway, sync: sync);
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
      gateway.changes.add(const [
        RemoteJobRecord(
          id: 'j',
          dreamId: 'dream',
          type: 'commit',
          status: 'done',
          attempt: 1,
          archivedOnly: true,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(values.map((value) => value.type), [
        JobType.write,
        JobType.validate,
        JobType.commit,
      ]);
      expect(values.first.stageLabel, '장면을 쓰는 중');
      expect(values.last.archivedOnly, true);
      expect(sync.pulled, ['dream']);
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
