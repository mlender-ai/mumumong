import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/auth/auth_loading_screen.dart';

void main() {
  testWidgets('account loading uses one orb and one stable state line', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: mumumongTheme(),
          home: const AuthLoadingScreen(title: '원고를 불러오는 중'),
        ),
      );
      expect(find.byType(ThinkingOrb), findsOneWidget);
      expect(find.text('원고를 불러오는 중'), findsOneWidget);
      expect(find.bySemanticsLabel('원고를 불러오는 중'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('first-volume choices fit the design system on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: VolumeSetupScreen(onComplete: () {}),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('꿈과 이야기의 거리'), findsNothing);
    expect(find.text('문장의 느낌'), findsNothing);
    expect(find.text('이야기의 시점'), findsNothing);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('ADAPTATION'), findsNothing);
    expect(find.text('WRITING STYLE'), findsNothing);
  });
}
