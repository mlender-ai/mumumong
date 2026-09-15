import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

void main() {
  test(
    'schema version 1 creates every remote mirror and local table',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
            'ORDER BY name',
          )
          .get();

      expect(database.schemaVersion, 1);
      expect(rows.map((row) => row.read<String>('name')), {
        'dream_drafts',
        'dream_elements',
        'dreams',
        'entities',
        'jobs',
        'link_decisions',
        'outbox',
        'passages',
        'progress_events',
        'reader_positions',
        'scenes',
        'sync_state',
        'volumes',
      });
    },
  );

  test('draft and submitted dream survive a database restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mumumong-drift-restart-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/mumumong.sqlite');
    const dreamId = '00000000-0000-4000-8000-000000008001';
    const draftId = '00000000-0000-4000-8000-000000008002';

    final firstDatabase = AppDatabase.forTesting(NativeDatabase(file));
    final firstRepository = DriftRepository(firstDatabase);
    await firstRepository.submitDream(_draft(dreamId));
    await firstRepository.saveDraft(_draft(draftId));
    await firstDatabase.close();

    final secondDatabase = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(secondDatabase.close);
    final secondRepository = DriftRepository(secondDatabase);

    final dreams = await secondRepository
        .watchDreams(DreamStatusFilter.all)
        .first;
    expect(dreams.any((dream) => dream.id == dreamId), isTrue);
    expect((await secondRepository.loadDraft())?.id, draftId);
  });
}

DreamDraft _draft(String id) => DreamDraft(
  id: id,
  rawText: '재실행 뒤에도 남아야 하는 꿈',
  inputMode: DreamInputMode.text,
  dreamDate: DateTime(2026, 9, 15),
  isBackfill: false,
  updatedAt: DateTime.utc(2026, 9, 15, 6),
);
