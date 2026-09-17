import '../../domain/model/models.dart';

abstract interface class EngineClient {
  Future<String> enqueue(String dreamId, String idempotencyKey);

  Stream<JobProgress> watch(String dreamId);
}

abstract interface class MockEngineStore {
  Future<void> writeEngineProgress(JobProgress progress);

  Future<void> commitMockResult(
    String dreamId, {
    required MockEngineResult result,
  });

  Future<void> failMockDream(String dreamId);
}

class MockEngineResult {
  const MockEngineResult({required this.isFallback});

  final bool isFallback;
}

class PendingRemoteEngineClient implements EngineClient {
  const PendingRemoteEngineClient();

  @override
  Future<String> enqueue(String dreamId, String idempotencyKey) {
    throw UnsupportedError('The remote engine is not connected yet');
  }

  @override
  Stream<JobProgress> watch(String dreamId) => const Stream.empty();
}
