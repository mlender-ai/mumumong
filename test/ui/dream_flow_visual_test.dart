import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

const _dream =
    '나는 물이 찬 긴 복도에 서 있었다. 붉은 문 앞의 여자가 우산을 쥐고 문을 두드렸다. 문틈에서 물소리가 들렸다.';
const _goldens = '../../docs/ux-review/2026-10-26-start-flow';

void main() {
  setUpAll(() async {
    await (FontLoader('Pretendard')
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf')))
        .load();
    await (FontLoader('MaruBuri')
          ..addFont(rootBundle.load('assets/fonts/MaruBuri-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/MaruBuri-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final night in [false, true]) {
    for (final (size, scale) in [
      (const Size(375, 667), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(430, 932), 1.0),
      (const Size(1200, 800), 1.0),
      (const Size(375, 667), 1.6),
    ]) {
      final tag =
          '${night ? 'night' : 'day'}-${size.width.toInt()}-${size.height.toInt()}-${scale == 1 ? 'normal' : 'large'}';
      testWidgets('four-screen composition $tag', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = MemoryRepository();
        final engine = MockEngineClient(
          store: repository,
          stageDelay: const Duration(seconds: 1),
        );
        Future<void> mount(Widget page) async {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                repositoryProvider.overrideWithValue(repository),
                engineClientProvider.overrideWithValue(engine),
              ],
              child: MaterialApp(
                theme: night ? dreamNightTheme() : mumumongTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: RepaintBoundary(
                    key: const Key('p2-screen'),
                    child: child!,
                  ),
                ),
                home: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> capture(String state) async {
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('p2-screen')),
            matchesGoldenFile(
              '${state == 'capture'
                  ? '../../docs/ux-review/2026-10-23-mobile-native'
                  : ['saved', 'reveal', 'entry'].contains(state)
                  ? '../../docs/ux-review/2026-10-23-spacing'
                  : _goldens}/$tag-$state.png',
            ),
          );
        }

        try {
          await mount(
            OnboardingScreen(
              policy: const AiConsentPolicy(
                version: 1,
                message: '가상 UI fixture입니다. 실제 동의는 기록하지 않습니다.',
                providers: [],
              ),
              onApplePressed: (_) {},
            ),
          );
          await capture('entry');
          await mount(const CaptureFlow(dreamNumber: 8, sceneNumber: 12));
          expect(find.byType(MemoryStamp), findsNothing);
          expect(find.byType(ThinkingOrb), findsNothing);
          await tester.enterText(find.byType(TextField), _dream);
          await tester.pump();
          await capture('capture');
          await tester.tap(find.text('꿈 저장하기'));
          await tester.pumpAndSettle();
          expect(find.text('꿈이 저장됐어요'), findsOneWidget);
          expect(find.byType(MemoryStamp), findsOneWidget);
          await capture('saved');
          final saved = (await tester.runAsync(
            () => repository.watchDreams(DreamStatusFilter.all).first,
          ))!;
          expect(saved.any((d) => d.rawText == _dream), isTrue);
          await tester.ensureVisible(find.text('장면 만들기'));
          await tester.tap(find.text('장면 만들기'));
          await tester.pumpAndSettle();
          expect(find.byType(ThinkingOrb), findsOneWidget);
          await capture('processing');
          for (
            var i = 0;
            i < 20 && find.text('새 장면 읽기').evaluate().isEmpty;
            i++
          ) {
            await tester.pump(const Duration(seconds: 1));
          }
          await tester.pumpAndSettle();
          expect(find.text('새 장면 읽기'), findsOneWidget);
          expect(find.text('같은 사람'), findsNothing);
          expect(find.byType(GlassActionButton), findsOneWidget);
          await capture('reveal');
          // Large type can scroll; the primary action must remain reachable.
          await tester.ensureVisible(find.text('새 장면 읽기'));
          expect(
            tester.getRect(find.text('새 장면 읽기')).bottom,
            lessThanOrEqualTo(size.height),
          );
          if (size == const Size(390, 844)) {
            await tester.ensureVisible(find.text('장면 조정하기'));
            await tester.tap(find.text('장면 조정하기'));
            await tester.pumpAndSettle();
            expect(find.text('같은 사람'), findsOneWidget);
            await tester.tap(find.text('같은 사람'));
            await tester.pumpAndSettle();
            final dreamId = saved.firstWhere((d) => d.rawText == _dream).id;
            final decisions = (await tester.runAsync(
              () => repository.watchLinkDecisions(dreamId).first,
            ))!;
            expect(decisions.single.status, LinkDecisionStatus.same);
            await tester.tap(find.text('장면의 위치 바꾸기'));
            await tester.pumpAndSettle();
            expect(find.text('사이 장면으로 넣기'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          engine.dispose();
          repository.dispose();
        }
      });
    }

    testWidgets(
      '${night ? 'night' : 'day'} capture keeps field and save above keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = MemoryRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: night ? dreamNightTheme() : mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: const EdgeInsets.only(bottom: 290),
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: child!,
              ),
              home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        expect(
          tester.getRect(find.text('꿈 저장하기')).bottom,
          lessThanOrEqualTo(377),
        );
        expect(find.byType(DreamAtmosphere), findsNothing);
        expect(find.byType(ThinkingOrb), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        repository.dispose();
      },
    );
  }

  testWidgets(
    'atmosphere visibly moves after a full loop while its text plane stays clear',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(width: 240, height: 320, child: DreamAtmosphere()),
          ),
        ),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).last,
      );
      Future<List<int>> pixels() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }

      await tester.pump(const Duration(seconds: 17));
      final before = (await tester.runAsync(pixels))!;
      await tester.pump(const Duration(seconds: 3));
      final after = (await tester.runAsync(pixels))!;
      var changed = 0;
      var samples = 0;
      for (var i = 0; i < before.length; i += 16) {
        final delta =
            (before[i] - after[i]).abs() +
            (before[i + 1] - after[i + 1]).abs() +
            (before[i + 2] - after[i + 2]).abs();
        if (delta > 18) changed++;
        samples++;
      }
      expect(changed / samples, greaterThan(.08));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('reduced motion freezes atmosphere and finishes saved stamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox(
              width: 240,
              height: 320,
              child: Stack(
                children: [
                  DreamAtmosphere(),
                  Center(child: MemoryStamp()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final atmosphere = paints
        .map((p) => p.painter)
        .whereType<DreamAtmospherePainter>()
        .single;
    expect(atmosphere.clock, isNull);
    expect(tester.hasRunningAnimations, isFalse);
    final phase = atmosphere.phase;
    await tester.pump(const Duration(seconds: 20));
    expect(atmosphere.phase, phase);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
