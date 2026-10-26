// Processing → Reveal → Growth is one narrative (DESIGN.md §9). These tests
// pin that every motion is driven by a real state change, plays once, stops,
// and collapses to its final frame under reduced motion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dot_cover.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/hero_motion.dart';

void main() {
  test(
    'processing halo layouts differ per stage and tighten toward validate',
    () {
      double radius(int stage) {
        var sum = 0.0;
        for (var i = 0; i < ProcessingHaloPainter.dots; i++) {
          sum += ProcessingHaloPainter.layout(stage, i).$1;
        }
        return sum / ProcessingHaloPainter.dots;
      }

      final radii = [for (var s = 0; s < 4; s++) radius(s)];
      expect(radii[0], greaterThan(radii[1]));
      expect(radii[1], greaterThan(radii[2]));
      expect(radii[2], greaterThan(radii[3]));
      // Alpha rises as the scene settles.
      expect(
        ProcessingHaloPainter.layout(3, 0).$3,
        greaterThan(ProcessingHaloPainter.layout(0, 0).$3),
      );
      // Stable: the same stage and index always lay out the same dot.
      expect(
        ProcessingHaloPainter.layout(1, 5),
        ProcessingHaloPainter.layout(1, 5),
      );
    },
  );

  testWidgets('a stage change moves the halo once and then it rests', (
    tester,
  ) async {
    Future<void> pump(int stage) => tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Center(
            child: ProcessingHalo(stage: stage, child: const SizedBox()),
          ),
        ),
      ),
    );
    await pump(0);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);

    await pump(1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(MongMotion.gather);
    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.hasRunningAnimations, isFalse);

    // Reduced motion: a stage change jumps to the final layout.
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: ProcessingHalo(stage: 3, child: const SizedBox()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(ProcessingHalo),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as ProcessingHaloPainter;
    expect(painter.to, 3);
    expect(painter.progress.value, 1);
    expect((painter.progress as AnimationController).isAnimating, isFalse);
  });

  testWidgets('reveal entrance staggers children and ends fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: const Scaffold(
          body: RevealEntrance(
            children: [Text('하나'), Text('둘'), Text('셋'), Text('넷')],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    double opacityOf(String text) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacityOf('하나'), greaterThan(opacityOf('넷')));
    expect(opacityOf('넷'), 0);
    await tester.pumpAndSettle();
    for (final text in ['하나', '둘', '셋', '넷']) {
      expect(opacityOf(text), 1);
    }

    // Reduced motion shows the final frame immediately.
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: RevealEntrance(children: [Text('바로'), Text('보임')]),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(opacityOf('바로'), 1);
    expect(opacityOf('보임'), 1);
    await tester.pump(const Duration(seconds: 1));
    expect(opacityOf('바로'), 1);
  });

  test('memory stamp cells arrive from an origin and land on the grid', () {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: MongMotion.settle,
    );
    addTearDown(controller.dispose);
    final painter = MemoryStampPainter(
      settle: controller,
      arriveColor: MongColor.sky500,
      settleColor: MongColor.sky700,
      from: const Offset(120, 200),
    );
    const size = Size(32, 32);
    final start = painter.cellAt(0, 0, size);
    final end = painter.cellAt(0, 1, size);
    expect(start.dx, greaterThan(100));
    expect(start.dy, greaterThan(180));
    expect(end.dx, lessThanOrEqualTo(32));
    expect(end.dy, lessThanOrEqualTo(32));
    expect(end, const Offset(4, 16));
  });

  test('home cover spec grows with progress and never fully clears', () {
    final zero = homeCoverSpec('vol-a', 0);
    final half = homeCoverSpec('vol-a', .5);
    final full = homeCoverSpec('vol-a', 1);
    expect(zero.seed, half.seed);
    expect(half.density, greaterThan(zero.density));
    expect(full.density, greaterThan(half.density));
    expect(full.effectiveClarity, lessThanOrEqualTo(DotCoverSpec.maxClarity));
    expect(full.dropout, greaterThanOrEqualTo(DotCoverSpec.minDropout));
    expect(homeCoverSpec('vol-b', .5).seed, isNot(half.seed));
  });
}
