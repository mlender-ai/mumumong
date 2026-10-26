import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

void main() {
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('원고 홈과 보관함을 이동한다', (tester) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MumumongApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이름 없는 원고'), findsOneWidget);
    expect(find.text('꿈 기록하기'), findsOneWidget);

    await tester.tap(find.text('보관함'));
    await tester.pumpAndSettle();

    expect(find.text('꿈 보관함'), findsOneWidget);
    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
  });

  testWidgets('꿈 기록 플로우의 첫 화면을 보여준다', (tester) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('장면 하나만 기억나도 괜찮아요.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('DREAM 008     꿈 기록'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '비가 내리는 골목을 걸었다.');
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ThinkingOrb), findsNothing);
    for (final beam in tester.widgetList<BeamFrame>(find.byType(BeamFrame))) {
      expect(beam.active, isFalse);
    }
  });

  testWidgets('키보드가 열려도 입력창과 저장 버튼이 겹치지 않는다', (tester) async {
    usePhoneViewport(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    addTearDown(tester.view.resetViewInsets);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '책상을 주려고 했다.');
    await tester.pump();

    final input = tester.getRect(find.byType(TextField));
    final save = tester.getRect(find.text('꿈 저장하기'));
    expect(input.bottom, lessThan(save.top));
    expect(save.bottom, lessThan(844 - 340));
    expect(find.bySemanticsLabel('녹음 시작'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
