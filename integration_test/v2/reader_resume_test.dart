// Migrated from integration_test/reader_resume_test.dart (V1). The V2 reader
// saves where reading stopped into a native SQLite file; after the route is
// closed and the file reopened, a plain reader open resumes the same
// paragraph at the same fraction under larger type. Explicit edits to
// synthetic seed data, never production manuscripts.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/design/press.dart';
import 'package:mumumong/v2/screens/reader.dart';

import 'harness.dart';

Finder _startsWith(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .replaceAll('⁠', '')
          .startsWith(prefix),
  description: 'text starting with "$prefix"',
);

Finder _passage(int index) => find
    .ancestor(
      of: _startsWith('가상 문단$index '),
      matching: find.byType(V2Pressable),
    )
    .first;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V2 reading position survives route close and SQLite reopen', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'mumumong-v2-reader-',
    );
    final file = File('${directory.path}/fixture.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    var repository = DriftRepository(database);
    try {
      final volume = (await repository.watchActiveVolume().first)!;
      final scene = (await repository.watchScenes(volume.id).first).last;
      final passages = await repository.watchPassages(scene.id).first;
      for (var i = 0; i < passages.length; i++) {
        await repository.editPassage(
          passages[i].id,
          '가상 문단$i ${List.filled(50, '종이배가 유리 계단을 따라 지나갔다.').join(' ')}',
        );
      }
      Future<void> mount(double scale, {String? sceneId}) async {
        await mountV2Native(
          tester,
          V2ReaderScreen(volumeId: volume.id, initialSceneId: sceneId),
          scale: scale,
          overrides: [
            databaseProvider.overrideWithValue(database),
            repositoryProvider.overrideWithValue(repository),
          ],
        );
        await waitFor(tester, _startsWith('가상 문단0 '));
        for (var i = 0; i < passages.length; i++) {
          expect(_startsWith('가상 문단$i '), findsOneWidget);
        }
      }

      await mount(1, sceneId: scene.id);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await unmount(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      final saved = await repository.loadReaderPosition(volume.id);
      expect(saved?.sceneId, scene.id);
      expect(saved?.passageId, isNotNull);
      expect(saved!.offset, greaterThan(100));
      await database.close();

      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = DriftRepository(database);
      await mount(1.5);
      expect(v2Text(scene.title!), findsWidgets);
      final index = passages.indexWhere((p) => p.id == saved.passageId);
      final rect = tester.getRect(_passage(index));
      final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
      expect(
        (viewport.top - rect.top) / rect.height,
        closeTo(saved.passageFraction, .03),
      );
      expect(tester.takeException(), isNull);
      await unmount(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
