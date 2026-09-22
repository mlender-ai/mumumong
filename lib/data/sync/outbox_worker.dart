import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import '../local/database.dart';

enum DeliveryReceipt { applied, alreadyApplied }

typedef OutboxDelivery =
    Future<DeliveryReceipt> Function(
      String operation,
      Map<String, dynamic> payload,
      String idempotencyKey,
    );

/// Durable FIFO with independent dream lanes. Transport must acknowledge the
/// exact idempotency key; an arbitrary HTTP 409 is not proof of prior success.
class OutboxWorker with WidgetsBindingObserver {
  OutboxWorker(this.database, this.deliver, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppDatabase database;
  final OutboxDelivery deliver;
  final DateTime Function() now;
  Future<void>? _draining;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  bool _disposed = false;
  bool _online = false;
  static const backoffSeconds = [1, 4, 15, 60, 300, 900];

  /// Call inside the same Drift transaction as the corresponding local edit.
  Future<void> enqueue({
    required String operation,
    required String aggregateId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final existing = await (database.select(
      database.outbox,
    )..where((row) => row.id.equals(idempotencyKey))).getSingleOrNull();
    if (existing != null) {
      final envelope = jsonDecode(existing.payload) as Map<String, dynamic>;
      if (existing.op != operation ||
          envelope['aggregate_id'] != aggregateId ||
          jsonEncode(envelope['body']) != jsonEncode(payload)) {
        throw StateError('idempotency_key_reused');
      }
      return;
    }
    final timestamp = now().toUtc();
    await database
        .into(database.outbox)
        .insert(
          OutboxCompanion.insert(
            id: idempotencyKey,
            op: operation,
            payload: jsonEncode({
              'aggregate_id': aggregateId,
              'created_at': timestamp.toIso8601String(),
              'body': payload,
            }),
            idempotencyKey: idempotencyKey,
            nextAttemptAt: timestamp,
            status: 'pending',
          ),
        );
  }

  Future<void> start() async {
    if (_connectivity != null || _disposed) return;
    WidgetsBinding.instance.addObserver(this);
    _connectivity = Connectivity().onConnectivityChanged.listen((state) {
      _online = !state.contains(ConnectivityResult.none);
      if (_online) unawaited(_safeDrain());
    });
    _online = !(await Connectivity().checkConnectivity()).contains(
      ConnectivityResult.none,
    );
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_safeDrain()),
    );
    await _safeDrain();
  }

  Future<void> _safeDrain() async {
    if (!_online) return;
    try {
      await drain();
    } on Object {
      /* Keep durable entries for the next wakeup. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_safeDrain());
  }

  Future<void> drain() {
    if (_disposed) return Future.value();
    return _draining ??= _drain().whenComplete(() => _draining = null);
  }

  Future<void> _drain() async {
    // SQLite rowid is persistent insertion order, including equal timestamps.
    final rows =
        await (database.select(database.outbox)
              ..where((row) => row.status.isNotValue('done'))
              ..orderBy([
                (_) => OrderingTerm(expression: CustomExpression<int>('rowid')),
              ]))
            .get();
    final blocked = <String>{};
    for (final row in rows) {
      if (_disposed) return;
      final envelope = jsonDecode(row.payload) as Map<String, dynamic>;
      final aggregate = envelope['aggregate_id'] as String;
      if (blocked.contains(aggregate)) continue;
      if (row.status == 'failed' || row.nextAttemptAt.isAfter(now().toUtc())) {
        blocked.add(aggregate);
        continue;
      }
      try {
        await deliver(
          row.op,
          Map<String, dynamic>.from(envelope['body'] as Map),
          row.idempotencyKey,
        ).timeout(const Duration(seconds: 30));
        await (database.update(database.outbox)
              ..where((r) => r.id.equals(row.id)))
            .write(const OutboxCompanion(status: Value('done')));
      } on Object {
        final attempt = row.attempt + 1;
        await (database.update(
          database.outbox,
        )..where((r) => r.id.equals(row.id))).write(
          OutboxCompanion(
            attempt: Value(attempt),
            status: Value(attempt >= 6 ? 'failed' : 'pending'),
            nextAttemptAt: Value(
              now().toUtc().add(
                Duration(seconds: backoffSeconds[(attempt - 1).clamp(0, 5)]),
              ),
            ),
          ),
        );
        blocked.add(aggregate);
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    if (_connectivity != null) WidgetsBinding.instance.removeObserver(this);
    await _connectivity?.cancel();
    await _draining;
  }
}
