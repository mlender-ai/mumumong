import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/local/data_export.dart';

void main() {
  test(
    'export includes manuscript provenance but no credentials or job payloads',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftRepository(database);
      await repository.watchActiveVolume().first;
      final data = jsonDecode(await exportLocalManuscript(database)) as Map;
      expect(data['version'], 1);
      final tables = data['tables'] as Map;
      expect(tables['dreams'], hasLength(7));
      expect(tables['scenes'], hasLength(11));
      expect(tables['passages'], isNotEmpty);
      expect(tables.containsKey('jobs'), false);
      expect(tables.containsKey('outbox'), false);
      expect(tables.containsKey('auth'), false);
    },
  );
}
