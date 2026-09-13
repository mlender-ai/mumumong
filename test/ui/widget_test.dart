import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
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
    await tester.pumpWidget(const MumumongApp());
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
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
      ),
    );
    await tester.pump();

    expect(find.text('장면 하나만 기억나도 괜찮아요.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('DREAM 008     꿈 기록'), findsOneWidget);
  });
}
