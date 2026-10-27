// V2 quality matrix: tap targets, labels, contrast, large text, keyboard
// and Reduced Motion on the six core screens. Invented fixtures only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/v2/preview/preview_root.dart';
import 'package:mumumong/v2/screens/reader.dart';

import 'support.dart';

Future<void> openCapture(WidgetTester tester) async {
  await tester.tap(find.text('꿈 기록'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadV2Fonts);

  for (final scale in [1.0, 2.0]) {
    testWidgets('home and archive at text scale $scale', (tester) async {
      await mountV2(tester, scale: scale, reduceMotion: true);
      await expectGuidelines(tester, 'home x$scale');
      await tester.tap(find.text('보관함'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'archive x$scale');
    });

    testWidgets('capture → saved → processing → reveal at text scale $scale', (
      tester,
    ) async {
      await mountV2(tester, scale: scale, reduceMotion: true);
      await openCapture(tester);
      await expectGuidelines(tester, 'capture x$scale');
      await tester.enterText(
        find.byKey(const ValueKey('v2-dream-editor')),
        '가상 테스트: 오래된 엘리베이터 안에서 계절 버튼을 눌렀다.',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('꿈 저장하기'));
      await tester.tap(find.text('꿈 저장하기'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'saved x$scale');
      await tester.ensureVisible(find.text('장면 만들기'));
      await tester.tap(find.text('장면 만들기'));
      await tester.pump(const Duration(milliseconds: 100));
      await expectGuidelines(tester, 'processing x$scale');
      await pumpUntil(tester, find.text('새 장면 읽기'));
      await expectGuidelines(tester, 'reveal x$scale');
    });

    testWidgets('reader at text scale $scale', (tester) async {
      await mountV2(
        tester,
        scale: scale,
        reduceMotion: true,
        home: const V2ReaderScreen(
          volumeId: MemorySeedIds.volume,
          initialSceneId: MemorySeedIds.readerScene,
        ),
      );
      await expectGuidelines(tester, 'reader x$scale');
    });

    testWidgets('onboarding at text scale $scale', (tester) async {
      setV2View(tester, scale: scale, reduceMotion: true);
      await tester.pumpWidget(
        V2PreviewSession(
          config: const PreviewConfig(start: PreviewStart.fresh),
          onExit: () {},
        ),
      );
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'onboarding entry x$scale');
      await tester.ensureVisible(find.text('시작하기'));
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'onboarding consent x$scale');
    });
  }

  testWidgets('capture keeps its editor and save action above the keyboard', (
    tester,
  ) async {
    await mountV2(tester, reduceMotion: true);
    await openCapture(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pumpAndSettle();
    final save = tester.getRect(find.text('꿈 저장하기'));
    final editor = tester.getRect(
      find.byKey(const ValueKey('v2-dream-editor')),
    );
    expect(save.bottom, lessThanOrEqualTo(874 - 336));
    expect(editor.height, greaterThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced Motion: input answers without scheduling frames', (
    tester,
  ) async {
    await mountV2(tester, reduceMotion: true);
    await openCapture(tester);
    await tester.enterText(
      find.byKey(const ValueKey('v2-dream-editor')),
      '가상 테스트: 계단 아래에서 파도 소리가 났다.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    // The text cursor winds down within a frame; V2 adds no tickers.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'dots jump to their state; nothing keeps animating',
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('nothing moves at rest: screens settle without idle loops', (
    tester,
  ) async {
    await mountV2(tester);
    // pumpAndSettle would time out on any perpetual animation.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await openCapture(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
