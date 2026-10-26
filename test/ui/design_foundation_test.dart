// DESIGN.md ↔ design_system.dart 1:1 contract and the shared components'
// states. Values here are the document's; changing one means changing both.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dot_cover.dart';

import '../../tool/ui_catalog.dart';

void main() {
  test('DESIGN.md §2 primitives and §4 type scale are the code tokens', () {
    expect(MongColor.paper, const Color(0xFFFBFAF7));
    expect(MongColor.paperPure, const Color(0xFFFFFFFF));
    expect(MongColor.sky500, const Color(0xFF4FAADD));
    expect(MongColor.sky600, const Color(0xFF2F8FC7));
    expect(MongColor.sky700, const Color(0xFF1F6FA0));
    expect(MongColor.lightSoft, const Color(0xFF5A8DD8));
    expect(MongColor.nightCanvas, const Color(0xFF050C18));
    expect(MongColor.readerNightPaper, const Color(0xFF161513));

    final theme = mumumongTheme();
    final text = theme.textTheme;
    expect(theme.scaffoldBackgroundColor, MongColor.paper);
    expect(text.displayLarge?.fontFamily, 'MaruBuri');
    expect(text.displayLarge?.fontSize, 36);
    expect(text.displayMedium?.fontFamily, 'MaruBuri');
    expect(text.displayMedium?.fontSize, 28);
    expect(text.headlineSmall?.fontFamily, 'MaruBuri');
    expect(text.titleMedium?.fontFamily, 'Pretendard');
    expect(text.bodyLarge?.fontFamily, 'MaruBuri');
    expect(text.bodyLarge?.height, 1.75);
    expect(text.bodyMedium?.fontFamily, 'Pretendard');
    expect(text.bodyMedium?.height, 1.55);
    expect(text.labelLarge?.fontSize, 15);
    expect(text.labelSmall?.letterSpacing, .44);

    expect(MongMotion.micro.inMilliseconds, 120);
    expect(MongMotion.base.inMilliseconds, 240);
    expect(MongMotion.page.inMilliseconds, 420);
    expect(MongMotion.settle.inMilliseconds, 650);
    expect(MongMotion.gather.inMilliseconds, 900);
    expect(MongMotion.growth.inMilliseconds, 1400);
    expect(MongMotion.reveal.inMilliseconds, 2400);
    expect(MongMotion.atmosphere.inSeconds, 14);
    expect(MongMotion.pressScale, .975);

    expect(MongRadius.field, 20);
    expect(MongRadius.tab, 22);
    expect(MongRadius.panel, 28);
    expect(MongRadius.nav, 31);
    expect(MongGlass.blur, 16);
    expect(MongGlass.elevatedBlur, 20);
    expect(MongGlass.frostedAlpha, .72);
    expect(MongGlass.elevatedAlpha, .92);
    expect(MongSize.action, 52);
    expect(MongSize.touch, 44);
    expect(MongSize.actionMaxWidth, 280);

    // The switch no longer falls back to Material green.
    final track = theme.switchTheme.trackColor!;
    expect(track.resolve({WidgetState.selected}), MongColor.sky500);
    expect(track.resolve({}), MongColor.line);
  });

  testWidgets('semantic roles swap between day and night', (tester) async {
    late BuildContext day;
    late BuildContext night;
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Builder(
          builder: (context) {
            day = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(day.canvas, MongColor.paper);
    expect(day.accent, MongColor.sky600);
    expect(day.accentSoft, MongColor.sky100);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            night = context;
            return const SizedBox();
          },
        ),
      ),
    );
    // MaterialApp animates theme changes; settle before reading the roles.
    await tester.pumpAndSettle();
    expect(night.canvas, MongColor.nightCanvas);
    expect(night.accent, MongColor.nightSky);
  });

  for (final variant in MongButtonVariant.values) {
    testWidgets('MongButton.${variant.name} keeps 44/52px, presses to .975 '
        'and goes still under reduced motion', (tester) async {
      var taps = 0;
      Future<void> pump({required bool reduce}) => tester.pumpWidget(
        MaterialApp(
          theme: mumumongTheme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Scaffold(
              body: Center(
                child: MongButton(
                  label: '계속하기',
                  variant: variant,
                  expanded: false,
                  onPressed: () => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      await pump(reduce: false);
      final minHeight = variant == MongButtonVariant.ghost
          ? MongSize.touch
          : MongSize.action;
      expect(
        tester.getSize(find.byType(MongButton)).height,
        greaterThanOrEqualTo(minHeight),
      );
      if (variant != MongButtonVariant.ghost) {
        final press = await tester.startGesture(
          tester.getCenter(find.text('계속하기')),
        );
        await tester.pump(const Duration(milliseconds: 60));
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          MongMotion.pressScale,
        );
        await press.up();
        await tester.pumpAndSettle();
        expect(taps, 1);

        await pump(reduce: true);
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
          Duration.zero,
        );
      } else {
        await tester.tap(find.text('계속하기'));
        expect(taps, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading keeps geometry and blocks taps; disabled dims', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Column(
            children: [
              MongButton(
                key: const Key('loading'),
                label: '저장',
                loadingLabel: '저장하는 중',
                onPressed: () => taps++,
              ),
              const MongButton(
                key: Key('disabled'),
                label: '저장',
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('저장하는 중'), findsOneWidget);
    await tester.tap(find.text('저장하는 중'));
    await tester.pumpAndSettle();
    expect(taps, 0);
    final dim = tester.widget<Opacity>(
      find.descendant(
        of: find.byKey(const Key('disabled')),
        matching: find.byType(Opacity),
      ),
    );
    expect(dim.opacity, .48);
  });

  testWidgets('MongChip carries selection in fill and edge, not colour alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Row(
            children: [
              MongChip(label: '선택', selected: true, onTap: () {}),
              MongChip(label: '기본', selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    BoxDecoration decorationOf(String label) =>
        tester
                .widget<AnimatedContainer>(
                  find.ancestor(
                    of: find.text(label),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
    final selected = decorationOf('선택');
    final plain = decorationOf('기본');
    expect(selected.color, MongColor.sky100);
    expect(selected.border!.top.color, MongColor.sky600);
    expect(plain.color, MongColor.paperShade);
    expect(plain.border!.top.color, MongColor.line);
    expect(
      tester.getSize(find.byType(MongChip).first).height,
      greaterThanOrEqualTo(MongSize.touch),
    );
  });

  testWidgets('recording icon button shows the active edge without pulsing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Center(
            child: MongIconButton(
              icon: Icons.stop_rounded,
              semanticLabel: '녹음 정지',
              variant: MongIconButtonVariant.recording,
              active: true,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, MongColor.sky400);
    expect(decoration.border!.top.width, 1.5);
    expect(tester.getSize(find.byType(MongIconButton)).width, MongSize.action);
    // Nothing keeps ticking after the first frame settles.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('DotCoverSpec never reaches full clarity and keeps a dropout floor', () {
    const spec = DotCoverSpec(seed: 1, clarity: 1.2);
    expect(spec.effectiveClarity, DotCoverSpec.maxClarity);
    expect(spec.dropout, DotCoverSpec.minDropout);
    expect(const DotCoverSpec(seed: 1, clarity: .2).dropout, closeTo(.8, 1e-9));
    expect(dotSeedFor('volume-a'), dotSeedFor('volume-a'));
    expect(dotSeedFor('volume-a'), isNot(dotSeedFor('volume-b')));
  });

  testWidgets('a cover with the same spec paints identical pixels; denser '
      'progress paints more dots', (tester) async {
    Future<ui.Image> render(DotCoverSpec spec) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      DotCoverPainter(
        spec: spec,
        arriveColor: MongColor.sky500,
        settleColor: MongColor.sky700,
      ).paint(canvas, const Size(120, 160));
      return recorder.endRecording().toImage(120, 160);
    }

    Future<int> inkedPixels(ui.Image image) async {
      final bytes = (await image.toByteData())!;
      var count = 0;
      for (var i = 3; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 24) count++;
      }
      return count;
    }

    const base = DotCoverSpec(seed: 42, density: .3, clarity: .4);
    // Image encoding is real async work; FakeAsync would never complete it.
    await tester.runAsync(() async {
      final a = await inkedPixels(await render(base));
      final b = await inkedPixels(await render(base));
      expect(a, b);
      expect(a, greaterThan(0));
      final grown = await inkedPixels(
        await render(base.copyWith(density: .8, clarity: .9)),
      );
      expect(grown, greaterThan(a));
    });
  });

  for (final (size, scale, night, reduce) in [
    (const Size(390, 844), 1.0, false, false),
    (const Size(375, 667), 1.6, true, true),
    (const Size(430, 932), 1.0, true, false),
  ]) {
    testWidgets('the UI catalog renders every state without overflow at '
        '$size ×$scale night=$night reduce=$reduce', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: UiCatalogApp(night: night, reduceMotion: reduce),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('10. Motion 토큰'), findsOneWidget);
    });
  }
}
