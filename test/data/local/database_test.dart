import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

void main() {
  test('v1 upgrade preserves old offset, manuscripts and drafts', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mumumong-v1-upgrade-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fixture.sqlite');
    final old = AppDatabase.forTesting(NativeDatabase(file));
    final repository = DriftRepository(old);
    final volume = (await repository.watchActiveVolume().first)!;
    await repository.saveDraft(_draft('migration-draft'));
    final count = (await old.select(old.passages).get()).length;
    // Reconstruct the original v1 local-only table without touching user data.
    await old.customStatement('DROP TABLE presentation_receipts');
    await old.customStatement('DROP TABLE completed_books');
    await old.customStatement('DROP TABLE completion_requests');
    await old.customStatement('DROP TABLE generation_settings_changes');
    await old.customStatement(
      'ALTER TABLE volumes DROP COLUMN settings_version',
    );
    await old.customStatement('DROP TABLE reader_positions');
    await old.customStatement(
      'CREATE TABLE reader_positions ('
      'volume_id TEXT NOT NULL REFERENCES volumes(id) PRIMARY KEY, '
      'offset REAL NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL)',
    );
    await old.customStatement('INSERT INTO reader_positions VALUES (?, ?, ?)', [
      volume.id,
      135.0,
      1792022400,
    ]);
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final restored = DriftRepository(upgraded);
    final bookmark = await restored.loadReaderPosition(volume.id);
    expect(bookmark?.offset, 135);
    expect(bookmark?.sceneId, isNull);
    expect(bookmark?.passageFraction, 0);
    expect((await upgraded.select(upgraded.passages).get()).length, count);
    expect((await restored.loadDraft())?.id, 'migration-draft');
    final version = await upgraded
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 5);
  });

  test('anchored bookmark survives a database restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mumumong-reader-restart-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fixture.sqlite');
    final first = AppDatabase.forTesting(NativeDatabase(file));
    final repo = DriftRepository(first);
    final volume = (await repo.watchActiveVolume().first)!;
    final scene = (await repo.watchScenes(volume.id).first).last;
    final passage = (await repo.watchPassages(scene.id).first)[2];
    await repo.saveReaderPosition(
      ReaderPosition(
        volumeId: volume.id,
        sceneId: scene.id,
        sceneOrderKey: scene.orderKey,
        passageId: passage.id,
        passageOrderKey: passage.orderKey,
        passageFraction: .55,
        offset: 240,
        updatedAt: DateTime.utc(2026, 10, 15),
      ),
    );
    await first.close();
    final second = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(second.close);
    final loaded = await DriftRepository(second).loadReaderPosition(volume.id);
    expect(loaded?.sceneId, scene.id);
    expect(loaded?.passageId, passage.id);
    expect(loaded?.passageFraction, .55);
  });
  test(
    'schema version 5 creates every remote mirror and local table',
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

      expect(database.schemaVersion, 5);
      expect(rows.map((row) => row.read<String>('name')), {
        'dream_drafts',
        'dream_elements',
        'dreams',
        'entities',
        'jobs',
        'generation_settings_changes',
        'completed_books',
        'completion_requests',
        'link_decisions',
        'outbox',
        'passages',
        'progress_events',
        'presentation_receipts',
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
