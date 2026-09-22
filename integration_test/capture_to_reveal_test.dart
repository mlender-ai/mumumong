import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in MockEngineCase.values) {
    testWidgets('capture to reveal: ${scenario.name}', (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = DriftRepository(database);
      final engine = MockEngineClient(
        store: repository,
        scenario: scenario,
        stageDelay: Duration.zero,
      );
      addTearDown(database.close);
      addTearDown(engine.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            engineClientProvider.overrideWithValue(engine),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '복도 끝에 붉은 문이 있었다.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.tap(find.text('기록 저장'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final skip = find.text('전체 건너뛰기');
      await tester.ensureVisible(skip);
      await tester.pump();
      await tester.tap(skip);
      await tester.pump();

      if (scenario == MockEngineCase.fail) {
        await _pumpUntil(tester, find.text('장면을 만들지 못했어요.'));
        expect(find.byKey(const ValueKey('reveal')), findsNothing);
        expect(find.text('다시 시도'), findsOneWidget);
        return;
      }

      await _pumpUntil(tester, find.byKey(const ValueKey('reveal')));
      expect(find.text('DREAM 008  →  SCENE 12'), findsOneWidget);
      if (scenario == MockEngineCase.fallback) {
        expect(find.text('붉은 문'), findsOneWidget);
        expect(find.text('복도에 물이 차 있었다.'), findsOneWidget);
      } else {
        expect(find.text('문 밖의 여자'), findsOneWidget);
        expect(find.text('그때 문틈으로 물소리가 새어 나오기 시작했다.'), findsOneWidget);
      }
    });
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}
