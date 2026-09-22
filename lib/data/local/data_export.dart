import 'dart:convert';
import 'database.dart';

/// A consistent local snapshot. Authentication material and job payloads are excluded.
Future<String> exportLocalManuscript(AppDatabase database) =>
    database.transaction(() async {
      final tables = <String, Object?>{};
      for (final table in const [
        'volumes',
        'dreams',
        'dream_elements',
        'scenes',
        'passages',
        'progress_events',
        'link_decisions',
        'dream_drafts',
      ]) {
        final rows = await database.customSelect('SELECT * FROM $table').get();
        tables[table] = rows.map((row) => row.data).toList();
      }
      return const JsonEncoder.withIndent('  ').convert({
        'format': 'mumumong-local-export',
        'version': 1,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'timestamp_unit': 'unix_seconds',
        'tables': tables,
      });
    });
