// Migrated from integration_test/capture_to_reveal_test.dart (V1). The V2
// capture flow on native SQLite: write, save, make the scene and read it, for
// each fixed mock engine case. Not AI fidelity.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/reader.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in MockEngineCase.values) {
    testWidgets('V2 capture to reveal: ${scenario.name}', (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = DriftRepository(database);
      final engine = MockEngineClient(
        store: repository,
        scenario: scenario,
        stageDelay: Duration.zero,
      );
      addTearDown(database.close);
      addTearDown(engine.dispose);

      await mountV2Native(
        tester,
        const V2CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        overrides: [
          databaseProvider.overrideWithValue(database),
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(engine),
        ],
      );
      await waitFor(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), '복도 끝에 붉은 문이 있었다.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tapNative(tester, v2Text('꿈 저장하기'));
      await waitFor(tester, v2Text('장면 만들기'));
      await tapNative(tester, v2Text('장면 만들기'));

      if (scenario == MockEngineCase.fail) {
        await waitFor(tester, v2Text('장면을 만들지 못했어요'));
        expect(find.byKey(const ValueKey('v2-reveal')), findsNothing);
        expect(v2Text('다시 시도'), findsOneWidget);
        expect(v2Text('꿈은 보관함에 저장되어 있어요.'), findsOneWidget);
        await unmount(tester);
        return;
      }

      await waitFor(tester, find.byKey(const ValueKey('v2-reveal')));
      expect(find.bySemanticsLabel('꿈 8번에서 장면 12'), findsOneWidget);
      await tapNative(tester, v2Text('새 장면 읽기'));
      await waitFor(tester, find.byType(V2ReaderScreen));
      if (scenario == MockEngineCase.fallback) {
        await waitFor(tester, v2TextContaining('복도에 물이 차 있었다.'));
        expect(v2Text('붉은 문'), findsWidgets);
      } else {
        await waitFor(tester, v2TextContaining('그때 문틈으로 물소리가 새어 나오기 시작했다.'));
        expect(v2Text('문 밖의 여자'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}
