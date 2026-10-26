import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

void main() {
  test(
    'v2 upgrade quiets historical growth and preserves manuscript/draft/outbox/bookmark',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-presentation-migration-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/synthetic.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftRepository(db, queueCloudMutations: true);
      final volume = (await repo.watchActiveVolume().first)!;
      final scene = (await repo.watchScenes(volume.id).first).last;
      final passages = await repo.watchPassages(scene.id).first;
      await repo.editPassage(passages.last.id, '가상 저자 문장: 종이 구름이 잠시 멈췄다.');
      await repo.saveDraft(
        DreamDraft(
          id: 'synthetic-draft',
          rawText: '가상 초안: 유리숲을 걸었다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 23),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      await repo.saveReaderPosition(
        ReaderPosition(
          volumeId: volume.id,
          sceneId: scene.id,
          updatedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      final before = await repo.watchPassages(scene.id).first;
      final outbox = await db.select(db.outbox).get();
      // Reconstruct only a disposable v2 fixture; no user DB is opened/reset.
      await db.customStatement('DROP TABLE presentation_receipts');
      await db.customStatement('DROP TABLE completed_books');
      await db.customStatement('DROP TABLE completion_requests');
      await db.customStatement('DROP TABLE generation_settings_changes');
      await db.customStatement(
        'ALTER TABLE volumes DROP COLUMN settings_version',
      );
      await db.customStatement('PRAGMA user_version = 2');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftRepository(db, queueCloudMutations: true);
      final historical = await repo.watchRecentProgress(volume.id).first;
      for (final event in historical.where((e) => e.deltaMu > 0)) {
        expect(
          await repo.consumePresentation(
            volumeId: volume.id,
            kind: PresentationKind.growth,
            sourceId: event.id,
          ),
          isFalse,
        );
      }
      expect(
        await repo.consumePresentation(
          volumeId: volume.id,
          kind: PresentationKind.reveal,
          sourceId: scene.id,
        ),
        isTrue,
      );
      expect((await repo.loadDraft())?.id, 'synthetic-draft');
      expect((await repo.loadReaderPosition(volume.id))?.sceneId, scene.id);
      expect(
        (await db.select(db.outbox).get()).map((row) => row.id),
        outbox.map((row) => row.id),
      );
      final after = await repo.watchPassages(scene.id).first;
      expect(
        after.map((p) => (p.id, p.text, p.origin, p.locked, p.firstReadAt)),
        before.map((p) => (p.id, p.text, p.origin, p.locked, p.firstReadAt)),
      );
      expect(after.last.origin, PassageOrigin.user);
      expect(after.last.locked, isTrue);
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      repo = DriftRepository(db);
      expect(
        await repo.consumePresentation(
          volumeId: volume.id,
          kind: PresentationKind.reveal,
          sourceId: scene.id,
        ),
        isFalse,
      );
      expect(
        (await repo.watchPassages(scene.id).first).first.firstReadAt,
        isNull,
      );
    },
  );
}
