import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('reading position survives route close and real SQLite reopen', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'mumumong-reader-e2e-',
    );
    final file = File('${directory.path}/fixture.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    var repository = DriftRepository(database);
    try {
      final volume = (await repository.watchActiveVolume().first)!;
      final scene = (await repository.watchScenes(volume.id).first).last;
      final passages = await repository.watchPassages(scene.id).first;
      // Explicit user edits to synthetic seed data, never production manuscripts.
      for (var i = 0; i < passages.length; i++) {
        await repository.editPassage(
          passages[i].id,
          '가상 문단$i ${List.filled(50, '종이배가 유리 계단을 따라 지나갔다.').join(' ')}',
        );
      }
      Future<void> mount(double scale, {String? sceneId}) async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [repositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: ReaderScreen(volumeId: volume.id, initialSceneId: sceneId),
            ),
          ),
        );
        // Native SQLite streams finish on real I/O, not an animation frame.
        for (
          var i = 0;
          i < 40 && find.byType(ReaderPassage).evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.byType(ReaderPassage), findsNWidgets(5));
      }

      await mount(1, sceneId: scene.id);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
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
      expect(find.text(scene.title!), findsOneWidget);
      final paragraph = find.byWidgetPredicate(
        (w) =>
            w is ReaderPassage &&
            w.text.startsWith(
              '가상 문단${passages.indexWhere((p) => p.id == saved.passageId)}',
            ),
      );
      final rect = tester.getRect(paragraph);
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(
        (viewport.top - rect.top) / rect.height,
        closeTo(saved.passageFraction, .03),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
