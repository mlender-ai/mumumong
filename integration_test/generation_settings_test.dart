// Native SQLite + real settings UI. Synthetic fixtures; no hosted AI call.
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/settings/generation_settings_screen.dart';
import 'package:mumumong/ui/settings/settings_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native settings save, SQLite reopen and future-job version preserve manuscript and U',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-p4-settings-native-',
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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: mumumongTheme(),
              home: const Scaffold(body: SettingsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('이후 장면 설정'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 50 && find.text('서정적으로').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(GenerationSettingsScreen), findsOneWidget);
        await tester.tap(find.text('서정적으로'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('설정 저장'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => repo
              .watchGenerationSettings(volume.id)
              .firstWhere((s) => s?.version == 2),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
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
            id: 'native-next',
            rawText: '가상 꿈: 종이배가 노래했다.',
            inputMode: DreamInputMode.text,
            dreamDate: DateTime(2026, 10, 23),
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
        await tester.pumpWidget(const SizedBox());
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
