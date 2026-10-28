// Migrated from integration_test/p3_saved_flow_test.dart (V1). A dream saved
// and reinforced on the V2 capture flow survives a native SQLite reopen
// without generating, and generates only on the explicit request. V2 reading
// settings persist through the platform preference channel. Invented
// fixtures; the engine is the fixed mock, not AI fidelity.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/ui_preferences.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 saved dream and recall survive SQLite reopen before explicit generation',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-v2-p3-',
      );
      final file = File('${directory.path}/saved.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(db);
      var engine = _CountingEngine(repository);
      await repository.ready;
      Future<void> mount({Dream? dream}) => mountV2Native(
        tester,
        V2CaptureFlow(dreamNumber: 8, sceneNumber: 12, savedDream: dream),
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(engine),
        ],
      );
      try {
        await mount();
        await waitFor(tester, find.byType(TextField));
        await tester.enterText(
          find.byType(TextField),
          '종이 우산이 투명한 계단 위에 놓여 있었다.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tapNative(tester, v2Text('꿈 저장하기'));
        await waitFor(tester, v2Text('꿈이 저장됐어요'));
        await tapNative(tester, v2Text('기억 더 보강하기'));
        await tapNative(tester, find.text('밝음'));
        await tapNative(tester, v2Text('보강 마치기'));
        await waitFor(tester, v2Text('장면 만들기'));
        final saved = (await tester.runAsync(
          () => repository.watchDreams(DreamStatusFilter.all).first,
        ))!.firstWhere((d) => d.rawText.startsWith('종이 우산'));
        expect(saved.status, DreamStatus.queued);
        expect(saved.recallAnswers['light'], '밝음');
        expect(engine.enqueues, 0, reason: 'saving never generates');
        await unmount(tester);
        engine.dispose();
        await db.close();

        db = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(db);
        engine = _CountingEngine(repository);
        final preserved = (await tester.runAsync(
          () => repository.watchDreams(DreamStatusFilter.all).first,
        ))!.singleWhere((d) => d.id == saved.id);
        expect(preserved.status, DreamStatus.queued);
        expect(preserved.recallAnswers['light'], '밝음');
        await mount(dream: preserved);
        await waitFor(tester, v2Text('꿈이 저장됐어요'));
        expect(engine.enqueues, 0, reason: 'reopening never generates');
        await tapNative(tester, v2Text('장면 만들기'));
        await waitFor(tester, v2Text('새 장면 읽기'));
        expect(engine.enqueues, 1);
        expect(v2Text('문 밖의 여자'), findsOneWidget);
      } finally {
        await unmount(tester);
        engine.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'V2 reading settings persist through the native preference channel',
    (tester) async {
      const key = 'mumumong.integration.v2.appearance';
      final platform = await SharedPreferences.getInstance();
      final previous = platform.getString(key);
      try {
        await platform.remove(key);
        await mountV2Native(
          tester,
          const V2ReadingSettingsPage(),
          preferences: false,
          overrides: [
            uiPreferenceStoreProvider.overrideWithValue(
              DeviceUiPreferenceStore(storageKey: key),
            ),
          ],
        );
        await waitFor(tester, find.text('밤의 종이'));
        await tapNative(tester, find.text('밤의 종이'));
        await tapNative(tester, find.text('크게'));
        await tapNative(tester, find.text('여백에 표시'));
        await unmount(tester);

        await platform.reload();
        final restored = UiPreferences(
          DeviceUiPreferenceStore(storageKey: key),
        );
        await restored.ready;
        expect(restored.themeMode, ThemeMode.dark);
        expect(restored.readerScale, 1.15);
        expect(restored.showOrigins, isTrue);
        restored.dispose();
      } finally {
        if (previous == null) {
          await platform.remove(key);
        } else {
          await platform.setString(key, previous);
        }
      }
    },
  );
}

/// The fixed mock engine, counting explicit generation requests.
class _CountingEngine implements EngineClient {
  _CountingEngine(DriftRepository store)
    : _mock = MockEngineClient(store: store, stageDelay: Duration.zero);
  final MockEngineClient _mock;
  int enqueues = 0;

  @override
  Future<String> enqueue(String dreamId, String idempotencyKey) {
    enqueues++;
    return _mock.enqueue(dreamId, idempotencyKey);
  }

  @override
  Future<String> retry(String dreamId) {
    enqueues++;
    return _mock.retry(dreamId);
  }

  @override
  Stream<JobProgress> watch(String dreamId) => _mock.watch(dreamId);

  void dispose() => _mock.dispose();
}
