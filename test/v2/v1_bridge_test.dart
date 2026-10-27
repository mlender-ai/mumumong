// The V1 bridge keeps the V1 theme on every page a not-yet-redrawn V1 screen
// pushes, and closes itself when that screen's first page is popped.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/screens/v1_bridge.dart';

import 'support.dart';

ColorScheme? _subScheme;

class _V1Probe extends StatelessWidget {
  const _V1Probe();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('V1 first'),
          TextButton(
            onPressed: () =>
                Navigator.push(context, quietPageRoute(const _V1Sub())),
            child: const Text('open sub'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('first back'),
          ),
        ],
      ),
    ),
  );
}

class _V1Sub extends StatelessWidget {
  const _V1Sub();

  @override
  Widget build(BuildContext context) {
    _subScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('sub back'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _mount(WidgetTester tester) async {
  setV2View(tester, reduceMotion: true);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MumumongV2App(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openInV1(context, const _V1Probe()),
                child: const Text('home'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('pages pushed by a V1 screen keep the V1 theme', (tester) async {
    await _mount(tester);
    await tester.tap(find.text('open sub'));
    await tester.pumpAndSettle();
    expect(_subScheme, mumumongTheme().colorScheme);

    await tester.tap(find.text('sub back'));
    await tester.pumpAndSettle();
    expect(find.text('V1 first'), findsOneWidget);
    expect(find.byType(V1Bridge), findsOneWidget);

    await tester.tap(find.text('first back'));
    await tester.pumpAndSettle();
    expect(find.byType(V1Bridge), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('system back pops the inner page first, then the bridge', (
    tester,
  ) async {
    await _mount(tester);
    await tester.tap(find.text('open sub'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('V1 first'), findsOneWidget);
    expect(find.byType(V1Bridge), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(V1Bridge), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('starting the next volume returns home through the bridge', (
    tester,
  ) async {
    final container = await _mount(tester);
    await tester.tap(find.text('open sub'));
    await tester.pumpAndSettle();
    container.read(libraryReturnHomeProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.byType(V1Bridge), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
