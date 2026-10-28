// Migrated from integration_test/generation_settings_test.dart (V1). V2
// settings on native SQLite: the next-scene style saves, survives a reopen
// and stamps the next job, while the existing manuscript and the user's
// locked paragraph stay exactly as they were. No hosted AI call.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/screens/settings.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 settings save, SQLite reopen and next-job version preserve manuscript and U',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-v2-settings-',
      );
      final file = File('${dir.path}/synthetic.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftRepository(db);
      try {
        await repo.ready;
        final volume = (await repo.watchActiveVolume().first)!;
        final scene = (await repo.watchScenes(volume.id).first).last;
        final passage = (await repo.watchPassages(scene.id).first).first;
        await repo.editPassage(passage.id, '가상 저자 문장: 바다 위에 책을 폈다.');
        final before = (await repo.watchPassages(scene.id).first)
            .map((p) => p.toJson())
            .toList();

        await mountV2Native(
          tester,
          const V2SettingsScreen(),
          overrides: [
            databaseProvider.overrideWithValue(db),
            repositoryProvider.overrideWithValue(repo),
          ],
        );
        await waitFor(tester, v2Text('이후 장면 설정'));
        await tapNative(tester, v2Text('이후 장면 설정'));
        expect(find.byType(V2GenerationSettingsPage), findsOneWidget);
        await waitFor(tester, find.text('서정적으로'));
        await tapNative(tester, find.text('서정적으로'));
        await tapNative(tester, v2Text('설정 저장'));
        await tester.runAsync(
          () => repo
              .watchGenerationSettings(volume.id)
              .firstWhere((s) => s?.version == 2)
              .timeout(const Duration(seconds: 10)),
        );
        await unmount(tester);
        await db.close();

        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = DriftRepository(db);
        final restored = (await repo.watchActiveVolume().first)!;
        expect(restored.settingsVersion, 2);
        expect(restored.style, WritingStyle.lyrical);
        expect(
          (await repo.watchPassages(scene.id).first).map((p) => p.toJson()),
          before,
        );
        final id = await repo.submitDream(
          DreamDraft(
            id: 'native-v2-next',
            rawText: '가상 꿈: 종이배가 노래했다.',
            inputMode: DreamInputMode.text,
            dreamDate: DateTime(2026, 10, 28),
            isBackfill: false,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await repo.answerRecall(id, {});
        final job = await (db.select(
          db.jobs,
        )..where((j) => j.dreamId.equals(id))).getSingle();
        expect(jsonDecode(job.payload)['generation_settings_version'], 2);
        expect((await repo.watchPassages(scene.id).first).first.locked, isTrue);
      } finally {
        await unmount(tester);
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
