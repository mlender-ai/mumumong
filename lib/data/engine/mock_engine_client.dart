import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/model/models.dart';
import 'engine_client.dart';

enum MockEngineCase { success, retry, fallback, fail }

extension MockEngineCaseParsing on MockEngineCase {
  static MockEngineCase fromName(String value) => switch (value) {
    'success' => MockEngineCase.success,
    'retry' => MockEngineCase.retry,
    'fallback' => MockEngineCase.fallback,
    'fail' => MockEngineCase.fail,
    _ => throw StateError('Unsupported MOCK_CASE: $value'),
  };
}

class MockEngineClient implements EngineClient {
  factory MockEngineClient({
    required MockEngineStore store,
    MockEngineCase scenario = MockEngineCase.success,
    Duration stageDelay = const Duration(seconds: 2),
    Uuid uuid = const Uuid(),
  }) => MockEngineClient._(store, scenario, stageDelay, uuid);

  MockEngineClient._(this._store, this._scenario, this._stageDelay, this._uuid);

  final MockEngineStore _store;
  final MockEngineCase _scenario;
  final Duration _stageDelay;
  final Uuid _uuid;
  final Map<String, String> _jobIdsByIdempotencyKey = {};
  final Map<String, JobProgress> _latestByDreamId = {};
  final Map<String, StreamController<JobProgress>> _controllers = {};
  bool _disposed = false;

  @override
  Future<String> enqueue(String dreamId, String idempotencyKey) async {
    _ensureOpen();
    final existing = _jobIdsByIdempotencyKey[idempotencyKey];
    if (existing != null) return existing;

    final jobId = _uuid.v4();
    _jobIdsByIdempotencyKey[idempotencyKey] = jobId;
    unawaited(_run(dreamId));
    return jobId;
  }

  @override
  Stream<JobProgress> watch(String dreamId) async* {
    _ensureOpen();
    final latest = _latestByDreamId[dreamId];
    if (latest != null) yield latest;
    yield* _controllerFor(dreamId).stream;
  }

  Future<void> _run(String dreamId) async {
    try {
      await _stage(dreamId, JobType.extract, '꿈을 읽는 중');
      await _stage(dreamId, JobType.link, '이어질 곳을 찾는 중');
      await _stage(dreamId, JobType.plan, '장면의 자리를 정하는 중');
      await _stage(dreamId, JobType.write, '장면을 쓰는 중');
      await _stage(dreamId, JobType.validate, '확인하는 중');

      if (_scenario != MockEngineCase.success) {
        await _stage(dreamId, JobType.write, '장면을 다시 쓰는 중', attempt: 2);
        await _stage(dreamId, JobType.validate, '다시 확인하는 중', attempt: 2);
      }

      if (_scenario == MockEngineCase.fallback ||
          _scenario == MockEngineCase.fail) {
        await _stage(dreamId, JobType.write, '꿈에 충실한 짧은 장면을 쓰는 중', attempt: 3);
        await _stage(dreamId, JobType.validate, '마지막으로 확인하는 중', attempt: 3);
      }

      if (_scenario == MockEngineCase.fail) {
        await _store.failMockDream(dreamId);
        await _emit(
          JobProgress(
            dreamId: dreamId,
            type: JobType.validate,
            status: JobStatus.failed,
            attempt: 3,
            stageLabel: '장면을 만들지 못했어요',
          ),
        );
        return;
      }

      await _store.commitMockResult(
        dreamId,
        result: MockEngineResult(
          isFallback: _scenario == MockEngineCase.fallback,
        ),
      );
      await _emit(
        JobProgress(
          dreamId: dreamId,
          type: JobType.commit,
          status: JobStatus.done,
          attempt: switch (_scenario) {
            MockEngineCase.success => 1,
            MockEngineCase.retry => 2,
            MockEngineCase.fallback || MockEngineCase.fail => 3,
          },
          stageLabel: '장면이 원고에 들어갔어요',
        ),
      );
    } on Object {
      if (_disposed) return;
      await _store.failMockDream(dreamId);
      await _emit(
        JobProgress(
          dreamId: dreamId,
          type: JobType.validate,
          status: JobStatus.failed,
          attempt: 3,
          stageLabel: '장면을 만들지 못했어요',
        ),
      );
    }
  }

  Future<void> _stage(
    String dreamId,
    JobType type,
    String label, {
    int attempt = 1,
  }) async {
    await _emit(
      JobProgress(
        dreamId: dreamId,
        type: type,
        status: JobStatus.running,
        attempt: attempt,
        stageLabel: label,
      ),
    );
    if (_stageDelay > Duration.zero) await Future<void>.delayed(_stageDelay);
  }

  Future<void> _emit(JobProgress progress) async {
    if (_disposed) return;
    await _store.writeEngineProgress(progress);
    if (_disposed) return;
    _latestByDreamId[progress.dreamId] = progress;
    _controllerFor(progress.dreamId).add(progress);
  }

  StreamController<JobProgress> _controllerFor(String dreamId) {
    return _controllers.putIfAbsent(
      dreamId,
      () => StreamController<JobProgress>.broadcast(sync: true),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final controller in _controllers.values) {
      unawaited(controller.close());
    }
    _controllers.clear();
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('MockEngineClient is disposed');
  }
}
