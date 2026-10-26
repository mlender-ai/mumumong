import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/domain/model/enums.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/auth/auth_loading_screen.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';

final _policy = AiConsentPolicy(
  version: 7,
  message: '로컬 QA 고지입니다. 상세 내용과 제공사 링크는 접혀 있어도 언제든 확인할 수 있습니다.',
  providers: [
    AiProviderDisclosure(
      id: 'groq',
      name: 'Groq',
      termsUrl: Uri.parse(
        'https://console.groq.com/docs/legal/services-agreement',
      ),
      dataUrl: Uri.parse('https://console.groq.com/docs/your-data'),
    ),
  ],
);

Widget _app(Widget child, {bool night = false, double scale = 1}) =>
    ProviderScope(
      child: MaterialApp(
        theme: night ? dreamNightTheme() : mumumongTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: child,
      ),
    );

void main() {
  testWidgets(
    'consent details are optional, two explicit checks still gate the only primary action',
    (tester) async {
      var submissions = 0;
      await tester.pumpWidget(
        _app(
          OnboardingScreen(
            policy: _policy,
            initialPage: 1,
            onConsentPressed: (_) => submissions++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_policy.message), findsNothing);
      expect(find.text('고지 버전 7'), findsNothing);
      expect(find.textContaining('Groq AI로'), findsOneWidget);
      expect(find.byType(GlassActionButton), findsOneWidget);
      GlassActionButton action() =>
          tester.widget(find.byType(GlassActionButton));
      expect(action().onPressed, isNull);
      await tester.tap(find.byKey(const Key('age-confirmation')));
      await tester.pump();
      expect(action().onPressed, isNull);
      await tester.tap(find.byKey(const Key('consent-details-toggle')));
      await tester.pump();
      expect(find.text(_policy.message), findsOneWidget);
      expect(find.text('고지 버전 7'), findsOneWidget);
      expect(find.text('Groq 이용 약관 열기'), findsOneWidget);
      await tester.tap(find.byKey(const Key('consent-details-toggle')));
      await tester.pump();
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('age-confirmation')))
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('ai-consent')));
      await tester.pump();
      expect(action().onPressed, isNotNull);
      expect(
        submissions,
        0,
      ); // No real acceptance, network or account creation.
    },
  );

  for (final night in [false, true]) {
    testWidgets(
      'compact flow remains scrollable at 375x667 / 160% night=$night',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            OnboardingScreen(
              policy: _policy,
              initialPage: 1,
              onConsentPressed: (_) {},
            ),
            night: night,
            scale: 1.6,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('ai-consent')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('ai-consent')));
        await tester.pump();
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('ai-consent')))
              .value,
          isTrue,
        );
        await tester.ensureVisible(find.text('동의하고 계속'));
        expect(find.text('동의하고 계속').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(VolumeSetupScreen(onComplete: () {}), night: night, scale: 1.6),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('이야기 설정'));
        await tester.pump();
        await tester.ensureVisible(find.text('소설 속 인물 시점'));
        await tester.tap(find.text('소설 속 인물 시점'));
        await tester.pump();
        await tester.ensureVisible(find.text('시작하기'));
        expect(find.text('시작하기').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'setup keeps selected choices on failure and starts once during a pending request',
    (tester) async {
      var requests = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        _app(
          VolumeSetupScreen(
            onComplete: () {},
            createVolume:
                ({
                  required adaptation,
                  required style,
                  required narrativeVoice,
                }) {
                  requests++;
                  expect(adaptation, AdaptationLevel.faithful);
                  return pending.future;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('이야기 설정'));
      await tester.pump();
      await tester.tap(find.text('꿈에 충실하게'));
      await tester.ensureVisible(find.text('시작하기'));
      await tester.tap(find.text('시작하기'));
      await tester.pump();
      expect(requests, 1);
      expect(find.byType(ThinkingOrb), findsOneWidget);
      expect(find.byType(GlassActionButton), findsNothing);
      pending.completeError(StateError('qa_offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('원고를 만들지 못했어요'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChipEditorial>(
              find.widgetWithText(ChoiceChipEditorial, '꿈에 충실하게'),
            )
            .selected,
        isTrue,
      );
    },
  );

  testWidgets(
    'all real wait phases retain the same mounted dotted-orbit geometry',
    (tester) async {
      Element? previous;
      for (final phase in DreamOrbState.values) {
        await tester.pumpWidget(
          _app(AuthLoadingScreen(title: '준비하고 있어요', orbState: phase)),
        );
        await tester.pump();
        final finder = find.byType(orbs.ThinkingOrb);
        expect(finder, findsOneWidget);
        expect(
          tester.widget<orbs.ThinkingOrb>(finder).state,
          orbs.OrbState.composing,
        );
        final current = tester.element(finder);
        if (previous != null) expect(current, same(previous));
        previous = current;
      }
    },
  );

  testWidgets('the production orb moves, and reduced motion freezes it', (
    tester,
  ) async {
    Widget frame(bool reduced) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const Center(
          child: RepaintBoundary(
            key: Key('orb-pixels'),
            child: ThinkingOrb(state: DreamOrbState.connecting),
          ),
        ),
      ),
    );
    Future<List<int>> pixels() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('orb-pixels')),
      );
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List().toList();
    }

    await tester.pumpWidget(frame(false));
    await tester.pump();
    final before = (await tester.runAsync(pixels))!;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 160)),
    );
    await tester.pump(const Duration(milliseconds: 160));
    expect((await tester.runAsync(pixels))!, isNot(orderedEquals(before)));
    await tester.pumpWidget(frame(true));
    await tester.pump();
    final paused = (await tester.runAsync(pixels))!;
    await tester.pump(const Duration(milliseconds: 200));
    expect((await tester.runAsync(pixels))!, orderedEquals(paused));
  });
}
