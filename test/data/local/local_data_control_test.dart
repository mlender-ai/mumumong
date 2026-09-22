import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/local/local_data_control.dart';

void main() {
  test('clearLocalData removes all manuscript and local-only rows', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftRepository(database);
    await repository.watchActiveVolume().first;
    await database.customStatement(
      "INSERT INTO outbox(id, op, payload, idempotency_key, attempt, next_attempt_at, status) "
      "VALUES ('o', 'x', '{}', 'k', 0, 0, 'pending')",
    );
    await clearLocalData(database);
    for (final table in const [
      'volumes',
      'dreams',
      'dream_elements',
      'scenes',
      'passages',
      'progress_events',
      'link_decisions',
      'jobs',
      'outbox',
    ]) {
      final count = await database
          .customSelect('SELECT COUNT(*) AS n FROM $table')
          .getSingle();
      expect(count.read<int>('n'), 0, reason: table);
    }
  });
}
