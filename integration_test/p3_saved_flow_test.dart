import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/ui_preferences.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'saved dream and recall survive SQLite close/reopen before explicit generation',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-p3-fixture-',
      );
      final file = File('${directory.path}/saved.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final repository = DriftRepository(db);
      await repository.ready;
      Future<void> mount(
        DriftRepository repo, {
        Dream? dream,
        MockEngineClient? engine,
      }) async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              if (engine != null)
                engineClientProvider.overrideWithValue(engine),
            ],
            child: MaterialApp(
              theme: mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: CaptureFlow(
                dreamNumber: 8,
                sceneNumber: 12,
                savedDream: dream,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount(repository);
      await tester.enterText(
        find.byType(TextField),
        '종이 우산이 투명한 계단 위에 놓여 있었다.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('꿈 저장하기'));
      await _wait(tester, find.text('꿈이 저장됐어요'));
      await tester.tap(find.text('기억 더 보강하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('밝음'));
      await tester.ensureVisible(find.text('보강 마치기'));
      await tester.tap(find.text('보강 마치기'));
      await _wait(tester, find.text('장면 만들기'));
      final dreams = (await tester.runAsync(
        () => repository.watchDreams(DreamStatusFilter.all).first,
      ))!;
      final saved = dreams.firstWhere((d) => d.rawText.startsWith('종이 우산'));
      expect(saved.status, DreamStatus.queued);
      expect(saved.recallAnswers['light'], '밝음');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      final restored = DriftRepository(reopened);
      final preserved = (await tester.runAsync(
        () => restored.watchDreams(DreamStatusFilter.all).first,
      ))!.singleWhere((d) => d.id == saved.id);
      expect(preserved.status, DreamStatus.queued);
      expect(preserved.recallAnswers['light'], '밝음');
      final engine = MockEngineClient(
        store: restored,
        stageDelay: Duration.zero,
      );
      await mount(restored, dream: preserved, engine: engine);
      expect(find.text('꿈이 저장됐어요'), findsOneWidget);
      await tester.tap(find.text('장면 만들기'));
      await _wait(tester, find.text('새 장면 읽기'));
      expect(
        find.text('문 밖의 여자'),
        findsOneWidget,
      ); // Explicit fixed mock engine, not AI fidelity.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      engine.dispose();
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );

  testWidgets(
    'native preference channel reload retains theme and reading size',
    (tester) async {
      const key = 'mumumong.integration.p3.appearance';
      final platform = await SharedPreferences.getInstance();
      final previous = platform.getString(key);
      final first = UiPreferences(DeviceUiPreferenceStore(storageKey: key));
      await first.ready;
      expect(
        await first.save(theme: ThemeMode.dark, scale: 1.4, origins: true),
        isTrue,
      );
      first.dispose();
      await platform.reload();
      final restored = UiPreferences(DeviceUiPreferenceStore(storageKey: key));
      await restored.ready;
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.readerScale, 1.4);
      expect(restored.showOrigins, isTrue);
      restored.dispose();
      if (previous == null) {
        await platform.remove(key);
      } else {
        await platform.setString(key, previous);
      }
    },
  );
}

Future<void> _wait(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('P3 fixture state did not arrive');
}
