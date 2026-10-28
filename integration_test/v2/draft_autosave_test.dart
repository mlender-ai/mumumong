// Migrated from integration_test/draft_autosave_test.dart (V1). The V2
// capture editor autosaves to a native SQLite file; after the file is closed
// and reopened the draft offers to continue, and a new draft deletes it.
// Invented fixtures only.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/screens/capture.dart';

import 'harness.dart';

const _text = '다시 열어도 남는 테스트 기억';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 native autosave restores after reopening and discard stays deleted',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-v2-draft-',
      );
      final file = File('${directory.path}/draft.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      Future<void> mount() => mountV2Native(
        tester,
        const V2CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        overrides: [
          databaseProvider.overrideWithValue(database),
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(
            MockEngineClient(store: repository, stageDelay: Duration.zero),
          ),
        ],
      );
      try {
        await mount();
        await waitFor(tester, find.byType(TextField));
        await tester.enterText(find.byType(TextField), _text);
        await tester.pump(const Duration(seconds: 1));
        expect((await repository.loadDraft())?.rawText, _text);
        FocusManager.instance.primaryFocus?.unfocus();
        await unmount(tester);
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        await mount();
        await waitFor(tester, v2Text('쓰던 꿈이 남아 있어요'));
        await tapNative(tester, v2Text('이어서 쓰기'));
        expect(find.text(_text), findsOneWidget);
        expect(v2Text('쓰던 꿈이 남아 있어요'), findsNothing);
        await unmount(tester);

        await mount();
        await waitFor(tester, v2Text('새로 쓰기'));
        await tapNative(tester, v2Text('새로 쓰기'));
        expect(await repository.loadDraft(), isNull);
        expect(find.text(_text), findsNothing);
      } finally {
        await unmount(tester);
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
