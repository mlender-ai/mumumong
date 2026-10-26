import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

const desired = GenerationSettings(
  adaptation: AdaptationLevel.faithful,
  style: WritingStyle.lyrical,
  narrativeVoice: NarrativeVoice.thirdPersonPast,
);
DreamDraft draft(String id) => DreamDraft(
  id: id,
  rawText: '가상 꿈: 종이섬에서 유리 배를 띄웠다.',
  inputMode: DreamInputMode.text,
  dreamDate: DateTime(2026, 10, 23),
  isBackfill: false,
  updatedAt: DateTime.utc(2026, 10, 23),
);

void main() {
  test(
    'pending settings and matching outbox survive restart; capture allowed, new generation blocked atomically',
    () async {
      final dir = await Directory.systemTemp.createTemp('mumumong-settings-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/fixture.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftRepository(db, queueCloudMutations: true);
      final volume = (await repo.watchActiveVolume().first)!;
      await repo.saveGenerationSettings(volume.id, desired);
      final mutation = await db
          .select(db.generationSettingsChanges)
          .getSingle();
      final outbox = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(mutation.mutationId))).getSingle();
      expect(jsonDecode(outbox.payload)['aggregate_id'], 'volume:${volume.id}');
      expect(outbox.idempotencyKey, mutation.mutationId);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      repo = DriftRepository(db, queueCloudMutations: true);
      final state = (await repo.watchGenerationSettings(volume.id).first)!;
      expect(state.selected, desired);
      expect(state.status, SettingsSyncStatus.pending);
      expect(state.version, 1);
      expect(state.confirmed.style, volume.style);
      await expectLater(
        repo.saveGenerationSettings(volume.id, desired),
        throwsA(isA<GenerationSettingsPending>()),
      );
      final id = await repo.submitDream(draft('new-synthetic'));
      await expectLater(
        repo.answerRecall(id, {}),
        throwsA(isA<GenerationSettingsPending>()),
      );
      final dream = (await repo.watchDreams(DreamStatusFilter.all).first)
          .singleWhere((d) => d.id == id);
      expect(dream.status, DreamStatus.queued);
      final placeholder = await (db.select(
        db.jobs,
      )..where((j) => j.dreamId.equals(id))).getSingle();
      expect(placeholder.status, 'queued');
      expect(placeholder.attempt, 0);
      expect(jsonDecode(placeholder.payload), isEmpty);
      expect(
        await (db.select(
          db.outbox,
        )..where((o) => o.op.equals('process_dream'))).get(),
        isEmpty,
      );
      await repo.retryGenerationSettings(volume.id);
      expect(
        (await db.select(db.generationSettingsChanges).getSingle()).mutationId,
        mutation.mutationId,
      );
    },
  );

  test(
    'local setting edits preserve U/content; new jobs pin new version, retry pins original',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftRepository(db);
      final volume = (await repo.watchActiveVolume().first)!;
      final scene = (await repo.watchScenes(volume.id).first).last;
      final passages = await repo.watchPassages(scene.id).first;
      await repo.editPassage(passages.first.id, '가상 저자 문장: 구름을 접었다.');
      final before = await repo.watchPassages(scene.id).first;
      final first = await repo.submitDream(draft('first'));
      await repo.answerRecall(first, {});
      await repo.saveGenerationSettings(volume.id, desired);
      final state = (await repo.watchGenerationSettings(volume.id).first)!;
      expect(state.version, 2);
      expect(state.status, SettingsSyncStatus.synced);
      await repo.saveGenerationSettings(volume.id, desired);
      expect((await repo.watchGenerationSettings(volume.id).first)!.version, 2);
      final second = await repo.submitDream(draft('second'));
      await repo.answerRecall(second, {});
      Future<int> pinned(String id) async =>
          jsonDecode(
                (await (db.select(
                  db.jobs,
                )..where((j) => j.dreamId.equals(id))).getSingle()).payload,
              )['generation_settings_version']
              as int;
      expect(await pinned(first), 1);
      expect(await pinned(second), 2);
      await (db.update(db.dreams)..where((d) => d.id.equals(first))).write(
        const DreamsCompanion(status: Value('failed')),
      );
      await (db.update(db.jobs)..where((j) => j.dreamId.equals(first))).write(
        const JobsCompanion(status: Value('failed')),
      );
      await repo.answerRecall(first, {});
      expect(await pinned(first), 1);
      expect(
        (await repo.watchPassages(scene.id).first).map((p) => p.toJson()),
        before.map((p) => p.toJson()),
      );
    },
  );

  test(
    'settings edit and generation intents serialize without mixing versions',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftRepository(db);
      final volume = (await repo.watchActiveVolume().first)!;
      final id = await repo.submitDream(draft('racing'));
      await Future.wait([
        repo.answerRecall(id, {}),
        repo.saveGenerationSettings(volume.id, desired),
      ]);
      final payload = jsonDecode(
        (await (db.select(
          db.jobs,
        )..where((j) => j.dreamId.equals(id))).getSingle()).payload,
      );
      expect(payload['generation_settings_version'], 1);
      expect((await repo.watchActiveVolume().first)!.settingsVersion, 2);
    },
  );

  test(
    'v3 upgrade preserves receipts, locked passages, drafts and outbox; legacy jobs receive v1',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-settings-v3-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/fixture.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftRepository(db, queueCloudMutations: true);
      final volume = (await repo.watchActiveVolume().first)!;
      final scene = (await repo.watchScenes(volume.id).first).last;
      final passage = (await repo.watchPassages(scene.id).first).first;
      await repo.editPassage(passage.id, '가상 저자 문장: 책이 잠들었다.');
      await repo.consumePresentation(
        volumeId: volume.id,
        kind: PresentationKind.reveal,
        sourceId: scene.id,
      );
      final id = await repo.submitDream(draft('legacy-job'));
      await repo.answerRecall(id, {});
      await repo.saveDraft(draft('draft'));
      await db.customStatement(
        "UPDATE jobs SET payload = '{}' WHERE dream_id = ?",
        [id],
      );
      final outboxIds = (await db.select(db.outbox).get())
          .map((o) => o.id)
          .toList();
      final before = await repo.watchPassages(scene.id).first;
      await db.customStatement('DROP TABLE generation_settings_changes');
      await db.customStatement('DROP TABLE completed_books');
      await db.customStatement('DROP TABLE completion_requests');
      await db.customStatement(
        'ALTER TABLE volumes DROP COLUMN settings_version',
      );
      await db.customStatement('PRAGMA user_version = 3');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      repo = DriftRepository(db);
      expect((await repo.watchGenerationSettings(volume.id).first)!.version, 1);
      expect(
        (await repo.watchPassages(scene.id).first).map((p) => p.toJson()),
        before.map((p) => p.toJson()),
      );
      expect(
        await repo.consumePresentation(
          volumeId: volume.id,
          kind: PresentationKind.reveal,
          sourceId: scene.id,
        ),
        isFalse,
      );
      expect((await repo.loadDraft())?.id, 'draft');
      expect((await db.select(db.outbox).get()).map((o) => o.id), outboxIds);
      expect(
        jsonDecode(
          (await (db.select(
            db.jobs,
          )..where((j) => j.dreamId.equals(id))).getSingle()).payload,
        )['generation_settings_version'],
        1,
      );
    },
  );
}
