import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/settings/generation_settings_screen.dart';
import 'package:mumumong/ui/settings/settings_screen.dart';

class SettingsBook extends MemoryRepository {
  bool fail = false;
  int saves = 0;
  int retries = 0;
  bool? keptLocal;
  @override
  Future<void> saveGenerationSettings(
    String volumeId,
    GenerationSettings settings,
  ) async {
    saves++;
    if (fail) throw StateError('synthetic_save_failure');
    await super.saveGenerationSettings(volumeId, settings);
  }

  @override
  Future<void> retryGenerationSettings(String volumeId) async {
    retries++;
  }

  @override
  Future<void> resolveGenerationSettingsConflict(
    String volumeId, {
    required bool keepLocal,
  }) async {
    keptLocal = keepLocal;
  }
}

const initial = GenerationSettings(
  adaptation: AdaptationLevel.balanced,
  style: WritingStyle.plain,
  narrativeVoice: NarrativeVoice.firstPersonPast,
);
const pending = GenerationSettings(
  adaptation: AdaptationLevel.faithful,
  style: WritingStyle.lyrical,
  narrativeVoice: NarrativeVoice.firstPersonPast,
);

void main() {
  Future<T> read<T>(WidgetTester tester, Stream<T> stream) async =>
      (await tester.runAsync(() => stream.first)) as T;
  Future<void> mount(
    WidgetTester tester,
    SettingsBook book, {
    GenerationSettingsState? state,
    Widget page = const GenerationSettingsScreen(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(book),
          if (state != null)
            generationSettingsProvider.overrideWith(
              (ref, id) => Stream.value(state),
            ),
        ],
        child: MaterialApp(theme: mumumongTheme(), home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'settings navigation saves preferences only, failure retains draft and retry succeeds',
    (tester) async {
      final book = SettingsBook()..fail = true;
      addTearDown(book.dispose);
      final volume = (await read(tester, book.watchActiveVolume()))!;
      final scenesBefore = (await read(
        tester,
        book.watchScenes(volume.id),
      )).map((s) => s.toJson()).toList();
      await mount(tester, book, page: const Scaffold(body: SettingsScreen()));
      await tester.tap(find.text('이후 장면 설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서정적으로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정 저장'));
      await tester.pumpAndSettle();
      expect(find.textContaining('선택은 유지했어요'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChipEditorial>(
              find.widgetWithText(ChoiceChipEditorial, '서정적으로'),
            )
            .selected,
        isTrue,
      );
      expect(
        (await read(tester, book.watchActiveVolume()))!.settingsVersion,
        1,
      );
      book.fail = false;
      await tester.tap(find.text('설정 저장'));
      await tester.pumpAndSettle();
      expect(
        (await read(tester, book.watchActiveVolume()))!.style,
        WritingStyle.lyrical,
      );
      expect(
        (await read(tester, book.watchActiveVolume()))!.settingsVersion,
        2,
      );
      expect(
        (await read(
          tester,
          book.watchScenes(volume.id),
        )).map((s) => s.toJson()),
        scenesBefore,
      );
      expect(book.saves, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('back discards unsaved choice without changing volume', (
    tester,
  ) async {
    final book = SettingsBook();
    addTearDown(book.dispose);
    await mount(tester, book, page: const Scaffold(body: SettingsScreen()));
    await tester.tap(find.text('이후 장면 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('영화적으로'));
    await tester.tap(find.byTooltip('설정으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(book.saves, 0);
    expect(
      (await read(tester, book.watchActiveVolume()))!.style,
      WritingStyle.plain,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'pending choices stay fixed and retry uses the existing mutation',
    (tester) async {
      final book = SettingsBook();
      addTearDown(book.dispose);
      await mount(
        tester,
        book,
        state: const GenerationSettingsState(
          confirmed: initial,
          version: 1,
          pending: pending,
          status: SettingsSyncStatus.pending,
        ),
      );
      await tester.tap(find.text('영화적으로'), warnIfMissed: false);
      expect(
        tester
            .widget<ChoiceChipEditorial>(
              find.widgetWithText(ChoiceChipEditorial, '서정적으로'),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.text('동기화 다시 시도'));
      await tester.pumpAndSettle();
      expect(book.retries, 1);
      expect(book.saves, 0);
      expect(find.textContaining('새 생성을 시작하지 않아요'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final keep in [false, true]) {
    testWidgets('conflict explains both choices and resolves keepLocal=$keep', (
      tester,
    ) async {
      final book = SettingsBook();
      addTearDown(book.dispose);
      await mount(
        tester,
        book,
        state: const GenerationSettingsState(
          confirmed: initial,
          version: 2,
          pending: pending,
          status: SettingsSyncStatus.conflict,
        ),
      );
      expect(find.textContaining('어느 설정을 사용할지'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('서버의 설정:'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('이 기기의 선택:'), findsOneWidget);
      await tester.tap(find.text(keep ? '이 기기의 선택 적용' : '서버 설정 사용'));
      await tester.pumpAndSettle();
      expect(book.keptLocal, keep);
      expect(book.saves, 0);
      await tester.pumpWidget(const SizedBox());
    });
  }

  setUpAll(() async {
    for (final (family, path) in [
      ('Pretendard', 'assets/fonts/Pretendard-Regular.otf'),
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
      testWidgets('generation settings fits $night $size $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final book = SettingsBook();
        addTearDown(book.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(book)],
            child: MaterialApp(
              theme: night ? dreamNightTheme() : mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale),
                ),
                child: RepaintBoundary(
                  key: const Key('settings-capture'),
                  child: child!,
                ),
              ),
              home: const GenerationSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('settings-capture')),
          matchesGoldenFile(
            '../../docs/ux-review/2026-10-23-p4-settings/${night ? 'night' : 'day'}-${size.width.toInt()}-${size.height.toInt()}-${scale == 1 ? 'normal' : 'large'}-generation-settings.png',
          ),
        );
        await tester.ensureVisible(find.text('소설 속 인물 시점'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('소설 속 인물 시점'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('설정 저장'));
        await tester.pumpAndSettle();
        expect(
          (await read(tester, book.watchActiveVolume()))!.narrativeVoice,
          NarrativeVoice.thirdPersonPast,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
