// Only newly invented fixture text. No private dreams or hosted calls.
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/export/book_store.dart';
import 'package:mumumong/data/export/completed_volume_pdf.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/library/library_screen.dart';
import '../test/data/export/book_store_test.dart' show readyBookFixture;
import '../test/support/ui_preference_store.dart';

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
  testWidgets(
    'complete book from settings UI, inspect snapshot and export actual PDF',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = (await tester.runAsync(() => readyBookFixture(db)))!;
      final store = BookStore(db), repo = DriftRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            repositoryProvider.overrideWithValue(repo),
            bookStoreProvider.overrideWithValue(store),
            uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: RepaintBoundary(
                key: const Key('book-review'),
                child: child!,
              ),
            ),
            home: CompletionScreen(volumeId: id),
          ),
        ),
      );
      Future<void> wait(Finder target) async {
        for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(target, findsOneWidget);
      }

      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('book-review')),
          matchesGoldenFile('../docs/ux-review/2026-10-23-release/$name.png'),
        );
      }

      await wait(find.widgetWithText(TextField, '책 제목'));
      await capture('book-title');
      await tester.enterText(
        find.widgetWithText(TextField, '책 제목'),
        '종이 별을 건너온 밤',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '작가의 말 · 선택'),
        '내가 직접 남기는 가상 작가의 말이다.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('내용 확인'));
      await tester.tap(find.text('내용 확인'));
      await tester.pumpAndSettle();
      await capture('book-confirm');
      await tester.tap(find.text('원고 완성하기').last);
      await wait(find.text('PDF 저장·공유'));
      await tester.pumpAndSettle();
      await capture('book-completed');
      final books = (await tester.runAsync(() => store.watchBooks().first))!;
      final book = books.single;
      final composer = (await tester.runAsync(
        () async => CompletedVolumePdfComposer(
          maruRegular: await File(
            'assets/fonts/MaruBuri-Regular.ttf',
          ).readAsBytes(),
          maruBold: await File('assets/fonts/MaruBuri-Bold.ttf').readAsBytes(),
        ),
      ))!;
      final pdf = await tester.runAsync(
        () => composer.compose(book.pdfSnapshot),
      );
      await tester.runAsync(() async {
        await Directory('output/pdf').create(recursive: true);
        await File(
          'output/pdf/verification-synthetic.pdf',
        ).writeAsBytes(pdf!, flush: true);
      });
      expect(pdf!.length, greaterThan(10000));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() => store.next(book));
      expect(
        (await tester.runAsync(() => repo.watchActiveVolume().first))!.volNo,
        2,
      );
      expect(
        (await tester.runAsync(() => store.watchBooks().first))!.single.title,
        book.title,
      );
      await tester.runAsync(db.close);
      await tester.pumpAndSettle();
    },
  );
  for (final night in [false, true]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('completion fits small screen night=$night scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final id = (await tester.runAsync(() => readyBookFixture(db)))!;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              repositoryProvider.overrideWithValue(DriftRepository(db)),
              bookStoreProvider.overrideWithValue(BookStore(db)),
              uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
            ],
            child: MaterialApp(
              theme: night ? dreamNightTheme() : mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: CompletionScreen(volumeId: id),
            ),
          ),
        );
        for (var i = 0; i < 40 && find.text('책 제목').evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.enterText(find.widgetWithText(TextField, '책 제목'), '가상 작품');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('내용 확인'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('내용 확인'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('이 원고를 한 권으로 보관할까요?'),
          -160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('원고 완성하기'), findsWidgets);
        expect(find.text('이 원고를 한 권으로 보관할까요?'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await tester.pumpAndSettle();
      });
    }
  }
}
