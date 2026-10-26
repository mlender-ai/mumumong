import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/archive/archive_screen.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';
import 'package:mumumong/ui/settings/appearance_screen.dart';
import 'package:mumumong/ui/settings/settings_components.dart';
import '../support/ui_preference_store.dart';

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
      testWidgets('P3 shared screen matrix $tag', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = MemoryRepository();
        final store = MemoryUiStore()
          ..value =
              '{"theme":"${night ? 'dark' : 'light'}","reader_scale":1.0}';
        Future<void> mount(Widget page, String name) async {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                repositoryProvider.overrideWithValue(repository),
                uiPreferenceStoreProvider.overrideWithValue(store),
              ],
              child: MaterialApp(
                theme: night ? dreamNightTheme() : mumumongTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: RepaintBoundary(
                    key: const Key('p3-screen'),
                    child: child!,
                  ),
                ),
                home: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('p3-screen')),
            matchesGoldenFile(
              '${switch (name) {
                'setup' => '../../docs/ux-review/2026-10-26-start-flow',
                'archive' => '../../docs/ux-review/2026-10-23-shell',
                'settings' => '../../docs/ux-review/2026-10-23-release',
                _ => '../../docs/ux-review/2026-10-19-design',
              }}/$tag-$name.png',
            ),
          );
        }

        try {
          await mount(VolumeSetupScreen(onComplete: () {}), 'setup');
          expect(find.byType(GlassActionButton), findsOneWidget);
          expect(find.text('문장의 느낌'), findsNothing);
          await tester.tap(find.text('이야기 설정'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('소설 속 인물 시점'));
          expect(tester.takeException(), isNull);
          await mount(
            Scaffold(body: SettingsOverview(onOpen: (_) {})),
            'settings',
          );
          await tester.scrollUntilVisible(
            find.text('음성 기록'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(tester.takeException(), isNull);
          await mount(const AppearanceScreen(), 'appearance');
          await mount(
            Scaffold(body: ArchiveScreen(onCapture: () {})),
            'archive',
          );
          await mount(const ReaderScreen(), 'reader');
          expect(
            tester.getSize(find.byType(ReaderPassage).first).width,
            lessThanOrEqualTo(672),
          );
          await tester.tap(find.byTooltip('문단 메뉴').first);
          await tester.pumpAndSettle();
          expect(find.text('출처 보기'), findsOneWidget);
          expect(find.text('문장 수정'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          repository.dispose();
        }
      });
    }
  }
}
