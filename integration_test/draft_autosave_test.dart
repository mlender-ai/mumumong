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
import 'package:mumumong/ui/capture/capture_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native autosave restores after reopening and discard stays deleted',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('draft-runtime-');
      final file = File('${directory.path}/draft.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      Widget app() => ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      );
      try {
        await tester.pumpWidget(app());
        await tester.pump(const Duration(seconds: 1));
        await tester.enterText(find.byType(TextField), '다시 열어도 남는 테스트 기억');
        await tester.pump(const Duration(seconds: 1));
        expect((await repository.loadDraft())?.rawText, '다시 열어도 남는 테스트 기억');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        await tester.pumpWidget(app());
        for (var i = 0; i < 30 && find.text('이어서 쓰기').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('이어서 쓰기'), findsOneWidget);
        await tester.tap(find.text('이어서 쓰기'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('다시 열어도 남는 테스트 기억'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.pumpWidget(app());
        for (var i = 0; i < 30 && find.text('새로 쓰기').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.text('새로 쓰기'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(await repository.loadDraft(), isNull);
        expect(find.text('다시 열어도 남는 테스트 기억'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
