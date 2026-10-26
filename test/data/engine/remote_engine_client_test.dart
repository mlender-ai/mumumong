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
  int? insertedSettingsVersion;
  int kicks = 0;
  List<RemoteJobRecord> rows = [];
  final insertedKeys = <String>[];
  final changes = StreamController<List<RemoteJobRecord>>.broadcast();
  @override
  Future<String> findDreamVolume(String dreamId) async => 'volume';
  @override
  Future<String?> findJobByKey(String userId, String key) async => existing;
  @override
  Future<String?> findActiveJob(String dreamId) async => existing;
  @override
  Future<List<RemoteJobRecord>> fetchJobs(String dreamId) async => rows;
  @override
  Future<String?> insertExtractJob({
    required String id,
    required String userId,
    required String dreamId,
    required String volumeId,
    required String idempotencyKey,
    int? settingsVersion,
  }) async {
    inserts++;
    insertedSettingsVersion = settingsVersion;
    insertedKeys.add(idempotencyKey);
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

class FakeSync implements RemoteEngineSync, GenerationSettingsPinSource {
  int? settingsVersion;
  @override
  Future<int?> generationSettingsVersion(String dreamId) async =>
      settingsVersion;
  final pushed = <String>[];
  final pulled = <String>[];
  bool failPull = false;
  Completer<void>? pullBarrier;

  @override
  Future<void> pullDreamResult(String dreamId) async {
    pulled.add(dreamId);
    if (failPull) throw StateError('synthetic_download_failure');
    await pullBarrier?.future;
  }

  @override
  Future<void> pushDream(String dreamId) async => pushed.add(dreamId);
}

void main() {
  test(
    'remote enqueue sends the generation intent version, not current volume settings',
    () async {
      final gateway = FakeGateway();
      final sync = FakeSync()..settingsVersion = 2;
      final engine = RemoteEngineClient(gateway, sync: sync);
      await engine.enqueue('synthetic-dream', 'settings-key');
      expect(gateway.insertedSettingsVersion, 2);
      sync.settingsVersion = 3;
      await engine.enqueue('synthetic-dream', 'settings-key');
      expect(gateway.inserts, 1);
      expect(gateway.insertedSettingsVersion, 2);
      await gateway.changes.close();
    },
  );
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

  test(
    'done waits for local download; failed download can recover without enqueue',
    () async {
      final gateway = FakeGateway();
      final sync = FakeSync()..failPull = true;
      final values = <JobProgress>[];
      final errors = <Object>[];
      final subscription = RemoteEngineClient(
        gateway,
        sync: sync,
      ).watch('dream').listen(values.add, onError: errors.add);
      const done = [
        RemoteJobRecord(
          id: 'commit',
          dreamId: 'dream',
          type: 'commit',
          status: 'done',
          attempt: 1,
        ),
      ];
      gateway.changes.add(done);
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
      expect(values, isEmpty);
      sync.failPull = false;
      sync.pullBarrier = Completer<void>();
      gateway.changes.add(done);
      await Future<void>.delayed(Duration.zero);
      expect(values, isEmpty);
      sync.pullBarrier!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(values.single.status, JobStatus.done);
      gateway.changes.add(done);
      await Future<void>.delayed(Duration.zero);
      expect(
        sync.pulled,
        hasLength(2),
        reason: 'successful download is not repeated every poll',
      );
      expect(gateway.inserts, 0);
      expect(gateway.kicks, 0);
      await subscription.cancel();
      await gateway.changes.close();
    },
  );

  test('retry creates a fresh extract job after a terminal failure', () async {
    final gateway = FakeGateway()
      ..rows = const [
        RemoteJobRecord(
          id: 'failed-job',
          dreamId: 'dream',
          type: 'write',
          status: 'failed',
          attempt: 3,
        ),
      ];
    final sync = FakeSync();
    var sequence = 0;
    final client = RemoteEngineClient(
      gateway,
      sync: sync,
      idGenerator: () =>
          '00000000-0000-4000-8000-${(++sequence).toString().padLeft(12, '0')}',
    );

    final jobId = await client.retry('dream');

    expect(jobId, '00000000-0000-4000-8000-000000000001');
    expect(gateway.inserts, 1);
    expect(gateway.kicks, 1);
    expect(sync.pushed, ['dream']);
  });

  test(
    'retry refuses transport-only errors and reuses any active stage',
    () async {
      final gateway = FakeGateway();
      final client = RemoteEngineClient(gateway);
      await expectLater(client.retry('dream'), throwsStateError);
      expect(gateway.inserts, 0);
      gateway.existing = 'active-write';
      expect(await client.retry('dream'), 'active-write');
      expect(gateway.inserts, 0);
      await gateway.changes.close();
    },
  );

  test('a repeated terminal retry uses the same key across clients', () async {
    final gateway = FakeGateway()
      ..rows = const [
        RemoteJobRecord(
          id: 'failed-job',
          dreamId: 'dream',
          type: 'write',
          status: 'failed',
          attempt: 3,
        ),
      ];
    await RemoteEngineClient(gateway).retry('dream');
    final key = gateway.insertedKeys.single;
    // Simulate a lost response / stale active lookup after process restart.
    gateway.existing = null;
    await RemoteEngineClient(gateway).retry('dream');
    expect(gateway.insertedKeys, [key, key]);
    await gateway.changes.close();
  });

  test(
    'committed manuscript is pulled, never regenerated after remember fails',
    () async {
      final gateway = FakeGateway()
        ..rows = const [
          RemoteJobRecord(
            id: 'commit',
            dreamId: 'dream',
            type: 'commit',
            status: 'done',
            attempt: 1,
          ),
          RemoteJobRecord(
            id: 'remember',
            dreamId: 'dream',
            type: 'remember',
            status: 'failed',
            attempt: 3,
          ),
        ];
      final sync = FakeSync();
      final client = RemoteEngineClient(gateway, sync: sync);
      expect(await client.retry('dream'), 'commit');
      expect(gateway.inserts, 0);
      final values = <JobProgress>[];
      final subscription = client.watch('dream').listen(values.add);
      gateway.changes.add(gateway.rows);
      await Future<void>.delayed(Duration.zero);
      expect(values.single.status, JobStatus.done);
      expect(values.single.type, JobType.commit);
      expect(sync.pulled, ['dream', 'dream']);
      await subscription.cancel();
      await gateway.changes.close();
    },
  );
}
