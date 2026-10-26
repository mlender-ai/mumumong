// P4 quality validation (DESIGN.md §10, §14): accessibility guidelines,
// text scaling up to 2.0, keyboard insets and reduced motion across the
// core screens. Synthetic Memory/mock data only; no accounts, AI or network.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/hero_motion.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';
import '../support/ui_preference_store.dart';

const _dream = '유리 복도를 걷다가 바닥 아래로 물고기들이 지나가는 것을 보았다. 끝에는 열리지 않는 파란 문이 있었다.';

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Pretendard', 'assets/fonts/Pretendard-Regular.otf'),
      ('Pretendard', 'assets/fonts/Pretendard-Medium.otf'),
      ('MaruBuri', 'assets/fonts/MaruBuri-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });

  Future<MemoryRepository> mountShell(
    WidgetTester tester, {
    required Size size,
    required double scale,
    required bool night,
    bool reduceMotion = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Platform-level values so MediaQuery.fromView carries them and the
    // view's own insets still reach the app (an ancestor MediaQuery would
    // shadow keyboard insets).
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: reduceMotion);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final repository = MemoryRepository();
    final store = MemoryUiStore()
      ..value = '{"theme":"${night ? 'dark' : 'light'}","reader_scale":1}';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          uiPreferenceStoreProvider.overrideWithValue(store),
          outboxWorkerProvider.overrideWithValue(null),
          engineClientProvider.overrideWithValue(
            MockEngineClient(
              store: repository,
              stageDelay: const Duration(milliseconds: 300),
            ),
          ),
          networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MumumongApp(),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> expectGuidelines(WidgetTester tester, String screen) async {
    await expectLater(
      tester,
      meetsGuideline(iOSTapTargetGuideline),
      reason: '$screen: 44pt touch targets',
    );
    await expectLater(
      tester,
      meetsGuideline(labeledTapTargetGuideline),
      reason: '$screen: labeled tap targets',
    );
    await expectLater(
      tester,
      meetsGuideline(textContrastGuideline),
      reason: '$screen: text contrast',
    );
  }

  for (final night in [false, true]) {
    testWidgets('core screens meet tap-target, label and contrast guidelines '
        '(${night ? 'night' : 'day'})', (tester) async {
      final handle = tester.ensureSemantics();
      await mountShell(
        tester,
        size: const Size(390, 844),
        scale: 1,
        night: night,
      );
      await expectGuidelines(tester, 'home');

      await tester.tap(find.text('보관함'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'archive');

      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'settings');
      await tester.tap(find.text('화면과 읽기'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'appearance');
      await tester.tap(find.byTooltip('설정으로 돌아가기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('원고'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('새 장면 읽기'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      await expectGuidelines(tester, 'reader');
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('꿈 기록하기'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureFlow), findsOneWidget);
      await expectGuidelines(tester, 'capture');
      await tester.enterText(find.byType(TextField), _dream);
      await tester.tap(find.text('꿈 저장하기'));
      await tester.pumpAndSettle();
      await expectGuidelines(tester, 'saved');
      await tester.tap(find.text('장면 만들기'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ThinkingOrb), findsOneWidget);
      await expectGuidelines(tester, 'processing');
      for (var i = 0; i < 30 && find.text('새 장면 읽기').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pumpAndSettle();
      expect(find.text('새 장면 읽기'), findsOneWidget);
      await expectGuidelines(tester, 'reveal');
      handle.dispose();
    });
  }

  for (final (size, scale) in [
    (const Size(375, 667), 1.6),
    (const Size(375, 667), 2.0),
    (const Size(390, 844), 2.0),
    (const Size(430, 932), 2.0),
  ]) {
    testWidgets(
      'core screens survive text scale $scale at ${size.width.toInt()}×'
      '${size.height.toInt()} without overflow and keep the primary action '
      'reachable',
      (tester) async {
        await mountShell(tester, size: size, scale: scale, night: false);
        Future<void> reachable(String label) async {
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.text(label)).bottom,
            lessThanOrEqualTo(size.height),
          );
          expect(tester.takeException(), isNull);
        }

        await reachable('새 장면 읽기');
        await tester.tap(find.text('보관함'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        await reachable('앱 잠금');
        await tester.tap(find.text('원고'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('새 장면 읽기'));
        await tester.pumpAndSettle();
        expect(find.byType(ReaderScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('닫기'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('꿈 기록하기'));
        await tester.pumpAndSettle();
        await reachable('꿈 저장하기');
        await tester.enterText(find.byType(TextField), _dream);
        await tester.tap(find.text('꿈 저장하기'));
        await tester.pumpAndSettle();
        await reachable('장면 만들기');
        await tester.tap(find.text('장면 만들기'));
        for (
          var i = 0;
          i < 30 && find.text('새 장면 읽기').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        await tester.pumpAndSettle();
        await reachable('새 장면 읽기');
      },
    );
  }

  testWidgets(
    'capture keeps the save action above an open keyboard at 375×667 ×1.6',
    (tester) async {
      await mountShell(
        tester,
        size: const Size(375, 667),
        scale: 1.6,
        night: false,
      );
      await tester.ensureVisible(find.text('꿈 기록하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('꿈 기록하기'));
      await tester.pumpAndSettle();
      // A real keyboard inset on the view, not a MediaQuery ancestor (the
      // app's MaterialApp re-reads view insets).
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final editor = find.byKey(const ValueKey('dream-editor'));
      expect(editor, findsOneWidget);
      final save = find.text('꿈 저장하기');
      expect(save, findsOneWidget);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(667 - 290));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion leaves home, saved and reveal at rest', (
    tester,
  ) async {
    await mountShell(
      tester,
      size: const Size(390, 844),
      scale: 1,
      night: false,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse, reason: 'home');

    await tester.tap(find.text('꿈 기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _dream);
    await tester.pump(const Duration(seconds: 1));
    // The caret blinks while the field is focused; nothing of ours may move.
    expect(find.byType(ThinkingOrb), findsNothing, reason: 'typing is still');
    expect(find.byType(ProcessingHalo), findsNothing);
    expect(find.byType(MemoryStamp), findsNothing);
    expect(
      tester
          .widgetList<DreamAtmosphere>(find.byType(DreamAtmosphere))
          .every((w) => !w.animate),
      isTrue,
      reason: 'capture atmosphere is a still frame',
    );
    await tester.tap(find.text('꿈 저장하기'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse, reason: 'saved');

    await tester.tap(find.text('장면 만들기'));
    await tester.pump(const Duration(milliseconds: 100));
    final halo = tester.widget<ProcessingHalo>(find.byType(ProcessingHalo));
    expect(halo.stage, greaterThanOrEqualTo(0));
    for (var i = 0; i < 30 && find.text('새 장면 읽기').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse, reason: 'reveal');
    final revealed = tester.widget<RevealEntrance>(find.byType(RevealEntrance));
    expect(revealed.animate, isTrue);
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      1,
      reason: 'reduced motion shows the final frame at once',
    );
  });
}
