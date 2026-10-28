// Migrated from integration_test/completed_book_test.dart (V1). A frozen book
// in a native SQLite file survives a reopen, composes its PDF from the real
// font assets, and the V2 book screen starts the next volume and returns.
// Invented fixtures only; the share sheet itself is not opened.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/export/book_store.dart';
import 'package:mumumong/data/export/completed_volume_pdf.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/screens/library.dart';

import '../../test/data/export/book_store_test.dart' show readyBookFixture;
import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 frozen book survives reopen, exports PDF and starts the next volume',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp('mumumong-v2-book-');
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

        final repo = DriftRepository(db);
        await mountV2Native(
          tester,
          V2CompletedBookScreen(book: book),
          overRoute: true,
          overrides: [
            databaseProvider.overrideWithValue(db),
            repositoryProvider.overrideWithValue(repo),
            bookStoreProvider.overrideWithValue(store),
          ],
        );
        await waitFor(tester, v2Text('PDF 저장·공유'));
        expect(v2Text('가상 별의 책'), findsWidgets);
        await tapNative(tester, v2Text('다음 권 시작'));
        await waitFor(tester, find.text('첫 화면'));
        expect(find.byType(V2CompletedBookScreen), findsNothing);
        expect((await repo.watchActiveVolume().first)!.volNo, 2);
        expect((await store.watchBooks().first).single.title, book.title);
        expect(tester.takeException(), isNull);
      } finally {
        await unmount(tester);
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
