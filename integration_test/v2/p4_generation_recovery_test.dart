// Migrated from integration_test/p4_generation_recovery_test.dart (V1). On
// native SQLite: a long generation left from the V2 shell completes off the
// route, and after a reopen home opens exactly that scene; a reveal already
// presented stays quiet after a restart without marking anything read.
// Invented fixtures; the engine is the fixed mock.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/reader.dart';

import 'harness.dart';

const _dream = '나는 물 위 도서관에서 종이 고래를 만났다.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2: leave a long generation, complete off-route, reopen SQLite and read the exact result',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-v2-p4-',
      );
      final file = File('${directory.path}/synthetic.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      await repository.ready;
      var engine = MockEngineClient(
        store: repository,
        stageDelay: const Duration(seconds: 6),
      );
      Future<void> mount() => mountV2Native(
        tester,
        const V2Shell(),
        overrides: [
          databaseProvider.overrideWithValue(database),
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(engine),
          outboxWorkerProvider.overrideWithValue(null),
        ],
      );

      try {
        await mount();
        await waitFor(tester, find.text('꿈 기록'));
        await tapNative(tester, find.text('꿈 기록'));
        await waitFor(tester, find.byType(TextField));
        await tester.enterText(find.byType(TextField), _dream);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tapNative(tester, v2Text('꿈 저장하기'));
        await waitFor(tester, v2Text('장면 만들기'));
        final saved = (await tester.runAsync(
          () => repository.watchDreams(DreamStatusFilter.all).first,
        ))!.singleWhere((d) => d.rawText == _dream);
        await tapNative(tester, v2Text('장면 만들기'));
        await waitFor(tester, v2Text('나중에 확인하기'));
        await tester.pump(const Duration(seconds: 21));
        expect(find.bySemanticsLabel(RegExp('^소설을 만들고 있어요')), findsOneWidget);
        await tapNative(tester, v2Text('나중에 확인하기'));
        expect(find.byType(V2CaptureFlow), findsNothing);
        await tester.runAsync(
          () => repository
              .watchDreams(DreamStatusFilter.all)
              .firstWhere(
                (dreams) => dreams.any(
                  (d) =>
                      d.id == saved.id && d.status == DreamStatus.inManuscript,
                ),
              )
              .timeout(const Duration(seconds: 25)),
        );
        await tester.pumpAndSettle();
        await unmount(tester);
        engine.dispose();
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        await repository.ready;
        engine = MockEngineClient(store: repository, stageDelay: Duration.zero);
        final result = (await tester.runAsync(
          () => repository.watchScenes(MemorySeedIds.volume).first,
        ))!.singleWhere((s) => s.sourceDreamIds.contains(saved.id));
        await mount();
        await waitFor(tester, find.text('새 장면 읽기'));
        await tapNative(tester, find.text('새 장면 읽기'));
        await waitFor(tester, find.byType(V2ReaderScreen));
        expect(
          tester
              .widget<V2ReaderScreen>(find.byType(V2ReaderScreen))
              .initialSceneId,
          result.id,
        );
        List<Passage> passages = const [];
        for (var i = 0; i < 40; i++) {
          passages = (await tester.runAsync(
            () => repository.watchPassages(result.id).first,
          ))!;
          if (passages.isNotEmpty && passages.first.firstReadAt != null) break;
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(passages, isNotEmpty);
        expect(passages.first.firstReadAt, isNotNull);
        expect(
          (await tester.runAsync(
            () => repository.watchScenes(MemorySeedIds.volume).first,
          ))!.where((s) => s.sourceDreamIds.contains(saved.id)),
          hasLength(1),
        );
      } finally {
        await unmount(tester);
        engine.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'V2: SQLite restart keeps a presented reveal quiet without consuming reading',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-v2-p4-presentation-',
      );
      final file = File('${directory.path}/synthetic.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      var engine = MockEngineClient(store: repository);
      final id = await repository.submitDream(
        DreamDraft(
          id: 'native-v2-presentation-dream',
          rawText: '가상 꿈: 나는 종이 고래와 유리 정원을 걸었다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 28),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 28),
        ),
      );
      await repository.answerRecall(id, {});
      await repository.commitMockResult(
        id,
        result: const MockEngineResult(isFallback: false),
      );
      // The fixture writes the terminal metadata the mock engine would.
      await repository.writeEngineProgress(
        JobProgress(
          dreamId: id,
          type: JobType.commit,
          status: JobStatus.done,
          attempt: 1,
          stageLabel: 'committed fixture',
        ),
      );
      Future<void> mount() async {
        final dream =
            (await repository.watchDreams(DreamStatusFilter.all).first)
                .singleWhere((d) => d.id == id);
        await mountV2Native(
          tester,
          V2CaptureFlow(dreamNumber: 8, sceneNumber: 12, savedDream: dream),
          overrides: [
            databaseProvider.overrideWithValue(database),
            repositoryProvider.overrideWithValue(repository),
            engineClientProvider.overrideWithValue(engine),
          ],
        );
      }

      try {
        await mount();
        await waitFor(tester, v2Text('새 장면 읽기'));
        final scene = (await repository.watchScenes(MemorySeedIds.volume).first)
            .singleWhere((s) => s.sourceDreamIds.contains(id));
        expect(
          (await repository.watchPassages(scene.id).first).first.firstReadAt,
          isNull,
        );
        await unmount(tester);
        engine.dispose();
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        engine = MockEngineClient(store: repository);
        await mount();
        await waitFor(tester, v2Text('장면 읽기'));
        expect(v2Text('새 장면 읽기'), findsNothing);
        expect(v2TextContaining('원고에 보관된 장면이에요'), findsOneWidget);
        expect(
          (await repository.watchPassages(scene.id).first).first.firstReadAt,
          isNull,
        );
        expect(
          (await database.select(database.presentationReceipts).get()).where(
            (r) => r.kind == 'reveal',
          ),
          hasLength(1),
        );
        expect(
          (await repository.watchScenes(MemorySeedIds.volume).first).where(
            (s) => s.sourceDreamIds.contains(id),
          ),
          hasLength(1),
        );
      } finally {
        await unmount(tester);
        engine.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
