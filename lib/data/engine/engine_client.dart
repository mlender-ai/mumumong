import '../../domain/model/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

class RemoteJobRecord {
  const RemoteJobRecord({
    required this.id,
    required this.dreamId,
    required this.type,
    required this.status,
    required this.attempt,
  });
  final String id;
  final String dreamId;
  final String type;
  final String status;
  final int attempt;
}

abstract interface class RemoteEngineGateway {
  String? get currentUserId;
  Future<String> findDreamVolume(String dreamId);
  Future<String?> insertExtractJob({
    required String id,
    required String userId,
    required String dreamId,
    required String volumeId,
    required String idempotencyKey,
  });
  Future<String?> findJobByKey(String userId, String idempotencyKey);
  Stream<List<RemoteJobRecord>> watchJobs(String dreamId);
}

class SupabaseRemoteEngineGateway implements RemoteEngineGateway {
  SupabaseRemoteEngineGateway(this.client);
  final SupabaseClient client;
  @override
  String? get currentUserId => client.auth.currentUser?.id;
  @override
  Future<String> findDreamVolume(String dreamId) async {
    final row = await client
        .from('dreams')
        .select('volume_id')
        .eq('id', dreamId)
        .single();
    return row['volume_id'] as String;
  }

  @override
  Future<String?> insertExtractJob({
    required String id,
    required String userId,
    required String dreamId,
    required String volumeId,
    required String idempotencyKey,
  }) async {
    try {
      await client.from('jobs').insert({
        'id': id,
        'user_id': userId,
        'dream_id': dreamId,
        'volume_id': volumeId,
        'type': 'extract',
        'status': 'queued',
        'attempt': 0,
        'idempotency_key': idempotencyKey,
        'payload': <String, Object?>{},
      });
      return id;
    } on PostgrestException catch (error) {
      if (error.code == '23505') return null;
      rethrow;
    }
  }

  @override
  Future<String?> findJobByKey(String userId, String idempotencyKey) async {
    final row = await client
        .from('jobs')
        .select('id')
        .eq('user_id', userId)
        .eq('idempotency_key', idempotencyKey)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Stream<List<RemoteJobRecord>> watchJobs(String dreamId) => client
      .from('jobs')
      .stream(primaryKey: ['id'])
      .eq('dream_id', dreamId)
      .order('updated_at')
      .map(
        (rows) => rows
            .map(
              (row) => RemoteJobRecord(
                id: row['id'] as String,
                dreamId: row['dream_id'] as String,
                type: row['type'] as String,
                status: row['status'] as String,
                attempt: row['attempt'] as int,
              ),
            )
            .toList(),
      );
}

class RemoteEngineClient implements EngineClient {
  RemoteEngineClient(this.gateway, {String Function()? idGenerator})
    : _idGenerator = idGenerator ?? const Uuid().v4;
  final RemoteEngineGateway gateway;
  final String Function() _idGenerator;

  @override
  Future<String> enqueue(String dreamId, String idempotencyKey) async {
    final userId = gateway.currentUserId;
    if (userId == null) throw StateError('authentication_required');
    final existing = await gateway.findJobByKey(userId, idempotencyKey);
    if (existing != null) return existing;
    final volumeId = await gateway.findDreamVolume(dreamId);
    final inserted = await gateway.insertExtractJob(
      id: _idGenerator(),
      userId: userId,
      dreamId: dreamId,
      volumeId: volumeId,
      idempotencyKey: idempotencyKey,
    );
    if (inserted != null) return inserted;
    final concurrent = await gateway.findJobByKey(userId, idempotencyKey);
    if (concurrent == null) throw StateError('idempotent_job_missing');
    return concurrent;
  }

  @override
  Stream<JobProgress> watch(String dreamId) => gateway
      .watchJobs(dreamId)
      .where((rows) => rows.isNotEmpty)
      .map((rows) {
        final row = rows.last;
        final type = enumFromDatabase(row.type, JobType.values);
        final status = enumFromDatabase(row.status, JobStatus.values);
        return JobProgress(
          dreamId: row.dreamId,
          type: type,
          status: status,
          attempt: row.attempt,
          stageLabel: _stageLabel(type, status),
        );
      })
      .distinct(
        (a, b) =>
            a.type == b.type && a.status == b.status && a.attempt == b.attempt,
      );
}

String _stageLabel(JobType type, JobStatus status) {
  if (status == JobStatus.failed) return '장면을 만들지 못했어요';
  if (status == JobStatus.done && type == JobType.commit) {
    return '장면이 원고에 들어갔어요';
  }
  return switch (type) {
    JobType.extract => '꿈을 읽는 중',
    JobType.link => '이어질 곳을 찾는 중',
    JobType.plan => '장면의 자리를 정하는 중',
    JobType.write || JobType.linkPatch => '장면을 쓰는 중',
    JobType.validate => '확인하는 중',
    JobType.commit => '원고에 넣는 중',
    JobType.remember => '원고를 기억하는 중',
  };
}
