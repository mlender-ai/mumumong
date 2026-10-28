// Shared harness for the V2 integration tests. They run on a simulator or
// device: native SQLite files in a temp directory, the platform preference
// channel and the real asset bundle. Invented fixtures only; the engine is
// the fixed mock, never a hosted AI call.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/design/theme.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';

import '../../test/v2/support.dart' show SilentSpeech;

export '../../test/v2/support.dart' show v2Text, v2TextContaining;

/// Mounts [home] in the V2 app with motion reduced. Network, speech and
/// preferences get offline-safe defaults; pass [speech] or [preferences]
/// false to supply your own in [overrides]. [overRoute] pushes [home] over a
/// plain first route so pops are observable.
Future<void> mountV2Native(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  bool speech = true,
  bool preferences = true,
  double scale = 1,
  bool overRoute = false,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...overrides,
        if (speech) speechInputProvider.overrideWithValue(SilentSpeech()),
        if (preferences)
          uiPreferenceStoreProvider.overrideWithValue(
            MemoryUiPreferenceStore(),
          ),
        networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MumumongV2App(
        home: overRoute
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).push(v2Route(home)),
                      child: const Text('첫 화면'),
                    ),
                  ),
                ),
              )
            : home,
      ),
    ),
  );
  await tester.pump();
  if (overRoute) {
    await tester.tap(find.text('첫 화면'));
    await tester.pump();
  }
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Native SQLite streams finish on real I/O, not on a frame: let real time
/// pass between frames until [finder] appears.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int attempts = 120,
}) async {
  for (var i = 0; i < attempts && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
  await tester.pumpAndSettle();
}

/// Taps [finder] after scrolling it into view and lets real I/O settle.
/// Lazy lists build the target only once it is scrolled near.
Future<void> tapNative(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}
