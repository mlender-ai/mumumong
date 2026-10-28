// Shared V2 test harness. Invented fixtures only (MemoryRepository seed and
// the mock engine's fixed scene); no account, network or AI.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/preview/preview_root.dart';

Future<void> loadV2Fonts() async {
  for (final (family, path) in [
    ('Pretendard', 'assets/fonts/Pretendard-Regular.otf'),
    ('Pretendard', 'assets/fonts/Pretendard-Medium.otf'),
    ('MaruBuri', 'assets/fonts/MaruBuri-Regular.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(path))).load();
  }
}

/// Finds a Text whose displayed string equals [text] once the keep-all
/// word joiners are removed.
Finder v2Text(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '').replaceAll(
            '⁠',
            '',
          ) ==
          text,
  description: 'V2 text "$text"',
);

Finder v2TextContaining(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .replaceAll('⁠', '')
          .contains(text),
  description: 'V2 text containing "$text"',
);

void setV2View(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  double scale = 1,
  bool reduceMotion = false,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

class SilentSpeech implements SpeechInput {
  final _updates = StreamController<SpeechUpdate>.broadcast();
  @override
  Stream<SpeechUpdate> get updates => _updates.stream;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

/// Mounts the V2 shell (or [home]) with the preview isolation overrides.
/// Motion is reduced by default: the sky drifts on a loop otherwise, so a
/// test that turns motion on gets pumped frames instead of a settle.
Future<MemoryRepository> mountV2(
  WidgetTester tester, {
  bool seeded = true,
  Size size = const Size(402, 874),
  double scale = 1,
  bool reduceMotion = true,
  MockEngineCase engine = MockEngineCase.success,
  Widget? home,
  bool scriptedVoice = false,
}) async {
  setV2View(tester, size: size, scale: scale, reduceMotion: reduceMotion);
  final repository = MemoryRepository(seedPrototype: seeded);
  addTearDown(repository.dispose);
  final config = PreviewConfig(
    start: seeded ? PreviewStart.continued : PreviewStart.fresh,
    engine: engine,
    voice: scriptedVoice ? PreviewVoice.scripted : PreviewVoice.device,
    stageDelay: const Duration(milliseconds: 400),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...previewOverrides(config, repository),
        if (!scriptedVoice)
          speechInputProvider.overrideWithValue(SilentSpeech()),
      ],
      child: MumumongV2App(home: home ?? const V2Shell()),
    ),
  );
  if (reduceMotion) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
  return repository;
}

/// Pumps until [finder] appears or [limit] passes (mock engine stages).
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 200),
  int limit = 80,
}) async {
  for (var i = 0; i < limit; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(step);
  }
  await tester.pumpAndSettle();
}

Future<T> snapshot<T extends Object>(
  WidgetTester tester,
  Stream<T> stream,
) async => (await tester.runAsync(() => stream.first))!;

/// Tap targets of 44pt, labels on every target, readable text contrast and
/// no layout exception on the current frame.
Future<void> expectGuidelines(WidgetTester tester, String screen) async {
  await expectLater(
    tester,
    meetsGuideline(iOSTapTargetGuideline),
    reason: '$screen: 44pt targets',
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: '$screen: labeled targets',
  );
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: '$screen: text contrast',
  );
  expect(tester.takeException(), isNull, reason: '$screen: no layout errors');
}
