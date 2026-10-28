// What keeps moving in V2 (DESIGN_V2.md §6): V1's flowing light drifts in
// every sky while it is on screen, and V1's Thinking Orb turns while real
// work waits. Reduce Motion holds both still. Invented fixtures only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/v2/components/orb.dart';
import 'package:mumumong/v2/design/atmosphere.dart';
import 'package:mumumong/v2/screens/gates.dart';

import 'support.dart';

V2FlowingLightPainter _flowing(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<V2FlowingLightPainter>()
    .first;

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('the sky keeps V1 flowing light drifting on home', (
    tester,
  ) async {
    await mountV2(tester, reduceMotion: false);
    final painter = _flowing(tester);
    expect(painter.clock, isNotNull);
    expect(painter.strength, greaterThan(.5), reason: 'home shows it fully');
    final before = painter.phase;
    await tester.pump(const Duration(seconds: 3));
    expect(_flowing(tester).phase, isNot(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reduce Motion holds the flowing light on one still frame', (
    tester,
  ) async {
    await mountV2(tester);
    final painter = _flowing(tester);
    expect(painter.clock, isNull);
    expect(painter.phase, painter.stillPhase);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('opening the app shows the Thinking Orb', (tester) async {
    setV2View(tester, reduceMotion: true);
    await tester.pumpWidget(
      const MaterialApp(home: V2WaitPage(title: '원고를 여는 중')),
    );
    await tester.pump();
    expect(find.byType(V2ThinkingOrb), findsOneWidget);
    expect(find.bySemanticsLabel('원고를 여는 중'), findsOneWidget);
  });
}
