import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/flowing_gradient.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';

void main() {
  test(
    'the gradient repaints for motion or palette strength, not identity',
    () {
      const still = FlowingGradientPainter(phase: .35, intensity: 1);
      expect(still.shouldRepaint(still), isFalse);
      expect(
        const FlowingGradientPainter(
          phase: .6,
          intensity: 1,
        ).shouldRepaint(still),
        isTrue,
      );
      expect(
        const FlowingGradientPainter(
          phase: .35,
          intensity: .4,
        ).shouldRepaint(still),
        isTrue,
      );
    },
  );

  testWidgets('reduced motion keeps the gradient at a stable frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 240, height: 320, child: FlowingGradient()),
        ),
      ),
    );
    final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
    expect((paint.painter! as FlowingGradientPainter).phase, .35);
    await tester.pump(const Duration(seconds: 3));
    final still = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
    expect((still.painter! as FlowingGradientPainter).phase, .35);
  });

  testWidgets('gradient is still moving after its first fourteen seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 240, height: 320, child: FlowingGradient()),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    final first = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
    final painter = first.painter;
    final phaseAfterLoop = (first.painter! as FlowingGradientPainter).phase;
    await tester.pump(const Duration(seconds: 1));
    final second = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
    final phaseLater = (second.painter! as FlowingGradientPainter).phase;
    expect(identical(second.painter, painter), isTrue);
    expect(phaseAfterLoop, greaterThan(0));
    expect(phaseLater, greaterThan(phaseAfterLoop));
  });

  testWidgets('rendered field changes after the first full loop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 320,
          child: FlowingGradient(immersive: true),
        ),
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    Future<Uint8List> pixels() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.pump(const Duration(seconds: 16));
    final before = (await tester.runAsync(pixels))!;
    await tester.pump(const Duration(seconds: 3));
    final after = (await tester.runAsync(pixels))!;
    expect(listEquals(before, after), isFalse);
    var changed = 0;
    var totalDelta = 0;
    var sampled = 0;
    for (var i = 0; i < before.length; i += 16) {
      final delta =
          (before[i] - after[i]).abs() +
          (before[i + 1] - after[i + 1]).abs() +
          (before[i + 2] - after[i + 2]).abs();
      totalDelta += delta;
      if (delta > 24) changed++;
      sampled++;
    }
    // A one-pixel difference is not perceptible motion. A substantial share
    // of the field must visibly change after a quarter of the cycle.
    expect(changed / sampled, greaterThan(.2));
    expect(totalDelta / sampled, greaterThan(20));
  });

  testWidgets('home has one content action and opens dream capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    expect(find.byType(DreamAtmosphere), findsOneWidget);
    final coverRect = tester.getRect(find.byType(DreamAtmosphere).first);
    expect(coverRect.left, 16);
    expect(coverRect.top, 10);
    expect(coverRect.width, 358);
    expect(find.text('꿈 기록하기'), findsOneWidget);
    expect(find.text('원고 읽기'), findsNothing);
    expect(find.text('열린 장면'), findsNothing);
    await tester.tap(find.text('꿈 기록하기'));
    await tester.pumpAndSettle();
    expect(find.text('장면 하나만 기억나도 괜찮아요.'), findsOneWidget);
  });
}
