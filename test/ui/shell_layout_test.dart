// Synthetic local navigation only; no accounts, AI or hosted data.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/archive/archive_screen.dart';
import 'package:mumumong/ui/home/home_screen.dart';
import 'package:mumumong/ui/settings/settings_components.dart';
import '../support/ui_preference_store.dart';

void main() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Pretendard', 'assets/fonts/Pretendard-Regular.otf'),
      ('MaruBuri', 'assets/fonts/MaruBuri-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
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
      testWidgets('shell layout and navigation $tag', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = MemoryRepository();
        final store = MemoryUiStore()
          ..value = '{"theme":"${night ? 'dark' : 'light'}","reader_scale":1}';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repository),
              uiPreferenceStoreProvider.overrideWithValue(store),
              outboxWorkerProvider.overrideWithValue(null),
              networkConnectedProvider.overrideWith(
                (ref) => Stream.value(true),
              ),
            ],
            child: MediaQuery(
              data: MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
              ),
              child: const RepaintBoundary(
                key: Key('shell-capture'),
                child: MumumongApp(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('shell-capture')),
            matchesGoldenFile(
              '../../docs/ux-review/${name == 'settings' ? '2026-10-23-release' : '2026-10-23-shell'}/$tag-shell-$name.png',
            ),
          );
        }

        try {
          await capture('home');
          expect(
            find.widgetWithText(EditorialButton, '새 장면 읽기'),
            findsOneWidget,
          );
          expect(find.text('이어 읽기'), findsNothing);
          final primary = find.widgetWithText(EditorialButton, '새 장면 읽기');
          await tester.ensureVisible(primary);
          expect(tester.getSize(primary).width, 280);
          final nav = find.text('설정');
          expect(
            tester.getBottomLeft(primary).dy,
            lessThan(tester.getTopLeft(nav).dy),
          );

          await tester.tap(nav);
          await tester.pumpAndSettle();
          await capture('settings');
          await tester.ensureVisible(find.text('음성 기록'));
          await tester.pumpAndSettle();
          expect(
            tester.getBottomLeft(find.text('음성 기록')).dy,
            lessThan(tester.getTopLeft(find.text('보관함')).dy),
          );
          await tester.ensureVisible(find.text('화면과 읽기'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('화면과 읽기'));
          await tester.pumpAndSettle();
          expect(find.text('화면 테마'), findsOneWidget);
          await tester.tap(find.byTooltip('설정으로 돌아가기'));
          await tester.pumpAndSettle();
          expect(find.byType(SettingsOverview), findsOneWidget);

          await tester.tap(find.text('보관함'));
          await tester.pumpAndSettle();
          await capture('archive');
          expect(find.byTooltip('꿈 기록하기'), findsOneWidget);
          await tester.tap(find.widgetWithText(ChoiceChipEditorial, '기록만'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.textContaining('작은 열쇠가 손바닥'),
            160,
            scrollable: find
                .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.runAsync(() async {
            await tester.tap(find.textContaining('작은 열쇠가 손바닥'));
          });
          await tester.pumpAndSettle();
          expect(find.text('원문 수정'), findsOneWidget);
        } finally {
          await tester.pumpWidget(const SizedBox());
          repository.dispose();
        }
      });
    }
  }

  testWidgets('archive header and rows scroll together at large type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryRepository(seedPrototype: false);
    await repository.createPreviewVolume(
      adaptation: AdaptationLevel.balanced,
      style: WritingStyle.plain,
      narrativeVoice: NarrativeVoice.firstPersonPast,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          networkConnectedProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(body: ArchiveScreen(onCapture: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final header = tester.getTopLeft(find.text('꿈 보관함')).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('꿈 보관함')).dy, lessThan(header));
    await tester.ensureVisible(find.text('첫 꿈 기록하기'));
    expect(
      tester.getSize(find.widgetWithText(EditorialButton, '첫 꿈 기록하기')).width,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    repository.dispose();
  });

  testWidgets('home pending summary omits zero counts and opens archive', (
    tester,
  ) async {
    final repository = MemoryRepository(seedPrototype: false);
    await repository.createPreviewVolume(
      adaptation: AdaptationLevel.balanced,
      style: WritingStyle.plain,
      narrativeVoice: NarrativeVoice.firstPersonPast,
    );
    await repository.submitDream(
      DreamDraft(
        id: 'shell-pending-fixture',
        rawText: '가상 기록: 나는 종이 구름을 바라봤다.',
        inputMode: DreamInputMode.text,
        dreamDate: DateTime(2026, 10, 23),
        isBackfill: false,
        updatedAt: DateTime(2026, 10, 23),
      ),
    );
    var opened = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: HomeScreen(onCapture: () {}, onArchive: () => opened++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.text('보관함에서 확인 · 1개 생성 전');
    expect(find.text('첫 꿈이 남아 있어요'), findsOneWidget);
    expect(find.text('첫 꿈을 기다리고 있어요'), findsNothing);
    expect(action, findsOneWidget);
    expect(find.textContaining('0개'), findsNothing);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    repository.dispose();
  });
}
