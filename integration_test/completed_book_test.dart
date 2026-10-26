// Invented fixtures only. Native SQLite, PDF bytes and next-volume persistence.
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/export/book_store.dart';
import 'package:mumumong/data/export/completed_volume_pdf.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/library/library_screen.dart';
import '../test/data/export/book_store_test.dart' show readyBookFixture;
import '../test/support/ui_preference_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native frozen book survives reopen, exports PDF and starts next volume',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-native-book-',
      );
      final file = File('${dir.path}/synthetic.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final id = await readyBookFixture(db);
        var store = BookStore(db);
        await store.complete(
          id,
          await store.prepare(id),
          '가상 별의 책',
          '가상 작가의 말',
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        store = BookStore(db);
        final book = (await store.watchBooks().first).single;
        final fonts = await Future.wait([
          rootBundle.load('assets/fonts/MaruBuri-Regular.ttf'),
          rootBundle.load('assets/fonts/MaruBuri-Bold.ttf'),
        ]);
        final bytes = await CompletedVolumePdfComposer(
          maruRegular: fonts[0].buffer.asUint8List(),
          maruBold: fonts[1].buffer.asUint8List(),
        ).compose(book.pdfSnapshot);
        expect(bytes.length, greaterThan(10000));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              repositoryProvider.overrideWithValue(DriftRepository(db)),
              bookStoreProvider.overrideWithValue(store),
              uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
            ],
            child: MaterialApp(
              theme: mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: CompletedBookScreen(book: book),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PDF 저장·공유'), findsOneWidget);
        await tester.tap(find.text('다음 권 시작'));
        await tester.pumpAndSettle();
        final repo = DriftRepository(db);
        expect((await repo.watchActiveVolume().first)!.volNo, 2);
        expect((await store.watchBooks().first).single.title, book.title);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
