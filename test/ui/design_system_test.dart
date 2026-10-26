import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;

void main() {
  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(1200, 800), 1.0),
    (const Size(375, 667), 1.6),
  ]) {
    testWidgets(
      'flow copy/action gap and primary width are stable $size/$scale',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: mumumongTheme(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: MongFlowPage(
                  content: const Text('기억을 남겼어요', key: Key('flow-copy')),
                  actions: MongActionGroup(
                    key: const Key('flow-actions'),
                    primary: GlassActionButton(
                      label: '계속하기',
                      onPressed: () => taps++,
                    ),
                    secondary: [
                      TextButton(onPressed: () {}, child: const Text('나중에')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const Key('flow-actions'))).top -
              tester.getRect(find.byKey(const Key('flow-copy'))).bottom,
          MongSpace.xl,
        );
        expect(
          tester.getSize(find.byType(GlassActionButton)).width,
          MongGlass.actionMaxWidth,
        );
        expect(
          tester.getRect(find.byKey(const Key('flow-copy'))).left,
          MongSpace.screen,
        );
        await tester.tap(find.text('계속하기'));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('long flow content scrolls without compressing the action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: MongFlowPage(
            content: Text(List.filled(60, '합성 화면 설명입니다.').join('\n')),
            actions: MongActionGroup(
              primary: GlassActionButton(label: '읽기', onPressed: () => taps++),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('읽기'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(GlassActionButton)).height,
      greaterThanOrEqualTo(MongSize.action),
    );
    await tester.tap(find.text('읽기'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'glass action compresses on press and releases without a bounce',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: mumumongTheme(),
          home: Scaffold(
            body: Center(
              child: GlassActionButton(
                label: '꿈 저장하기',
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );

      final scale = find.byType(AnimatedScale);
      expect(tester.widget<AnimatedScale>(scale).scale, 1);
      final press = await tester.startGesture(
        tester.getCenter(find.text('꿈 저장하기')),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widget<AnimatedScale>(scale).scale, .975);
      await press.up();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widget<AnimatedScale>(scale).scale, 1);
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  test('one UI scale defines the app type, controls and modal geometry', () {
    final theme = mumumongTheme();
    expect(theme.textTheme.displayLarge?.fontSize, 36);
    expect(theme.textTheme.bodyMedium?.fontSize, 16);
    expect(theme.textTheme.labelLarge?.fontSize, 15);
    expect(theme.textTheme.labelSmall?.fontSize, 12);
    expect(MongSpace.screen, 24);
    expect(MongSize.action, 52);
    expect(MongRadius.sheet, MongRadius.panel);
    expect(theme.dialogTheme.backgroundColor, MongColor.paperPure);
    expect(theme.bottomSheetTheme.backgroundColor, MongColor.paperPure);
  });

  for (final (dreamState, expected) in <(DreamOrbState, orbs.OrbState)>[
    (DreamOrbState.listening, orbs.OrbState.composing),
    (DreamOrbState.gathering, orbs.OrbState.composing),
    (DreamOrbState.connecting, orbs.OrbState.composing),
    (DreamOrbState.composing, orbs.OrbState.composing),
    (DreamOrbState.checking, orbs.OrbState.composing),
  ]) {
    testWidgets('$dreamState uses the reference orb state at native size', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mumumongTheme(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(child: ThinkingOrb(state: dreamState)),
          ),
        ),
      );
      final orb = tester.widget<orbs.ThinkingOrb>(
        find.byType(orbs.ThinkingOrb),
      );
      expect(orb.state, expected);
      expect(orb.size, orbs.OrbSize.size64);
      expect(orb.color, MongColor.orbInk);
    });
  }
}
