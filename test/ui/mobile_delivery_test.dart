import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/sampled_motion.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/home/home_screen.dart';
import 'package:mumumong/ui/shared/web_install_guide.dart';
import 'package:mumumong/ui/settings/settings_components.dart';

void main() {
  test(
    'PDF-only font remains available as an explicit bundled asset',
    () async {
      final font = await rootBundle.load('assets/fonts/MaruBuri-Bold.ttf');
      expect(font.lengthInBytes, 3351940);
    },
  );
  testWidgets(
    'decorative clock bounds 120Hz source invalidations and disposes',
    (tester) async {
      final parent = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 14),
      );
      final sampled = SampledMotion(parent);
      var paints = 0;
      sampled.addListener(() => paints++);
      parent.repeat();
      await tester.pump();
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(microseconds: 8333));
      }
      expect(paints, inInclusiveRange(28, 31));
      expect(sampled.value, greaterThan(0));
      sampled.dispose();
      parent.dispose();
    },
  );
  testWidgets(
    'atmosphere stops in background and resumes without touching input',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DreamAtmosphere()));
      await tester.pump(const Duration(seconds: 1));
      final clock = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<DreamAtmospherePainter>()
          .single
          .clock!;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final stopped = clock.value;
      await tester.pump(const Duration(seconds: 2));
      expect(clock.value, stopped);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(clock.value, isNot(stopped));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('performance tuning preserves the shared glass material', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Column(
            children: [
              GlassActionButton(label: 'paper', onPressed: () {}),
              GlassActionButton(
                label: 'field',
                lightContent: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final filters = tester
        .widgetList<BackdropFilter>(find.byType(BackdropFilter))
        .toList();
    expect(filters.map((f) => f.enabled), [true, true]);
  });
  testWidgets('off-tab home does not animate its decorative cover', (
    tester,
  ) async {
    final repo = MemoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: HomeScreen(
            isActive: false,
            onCapture: () {},
            onRead: () {},
            onReadScene: (_) {},
            onArchive: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final atmosphere = tester.widget<DreamAtmosphere>(
      find.byType(DreamAtmosphere),
    );
    expect(atmosphere.animate, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    repo.dispose();
  });
  testWidgets(
    'settings no longer routes back to the retired installation guide',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mumumongTheme(),
          home: Scaffold(body: SettingsOverview(onOpen: (_) {})),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('음성 기록'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('앱처럼 사용하기'), findsNothing);
      expect(find.text('브라우저 주소창 없이 여는 방법'), findsNothing);
      expect(find.text('AI 처리 고지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('web microphone help does not impersonate native recording', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: mumumongTheme(), home: const WebVoiceGuide()),
    );
    expect(find.textContaining('이 웹 체험판에서는 사용할 수 없어요'), findsOneWidget);
    expect(find.textContaining('음성을 서버로 보내지는 않아요'), findsOneWidget);
    expect(find.text('녹음 중'), findsNothing);
  });
}
