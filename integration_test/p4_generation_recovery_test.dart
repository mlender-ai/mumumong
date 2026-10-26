import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import '../test/support/ui_preference_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'leave a long generation, complete off-route, reopen SQLite and read exact result',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-p4-native-',
      );
      final file = File('${directory.path}/synthetic.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      await repository.ready;
      var engine = MockEngineClient(
        store: repository,
        stageDelay: const Duration(seconds: 6),
      );
      Future<void> mount() async {
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              repositoryProvider.overrideWithValue(repository),
              engineClientProvider.overrideWithValue(engine),
              uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
              outboxWorkerProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              theme: mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: const MumumongShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      try {
        await mount();
        await _wait(tester, find.text('꿈 기록하기'));
        await tester.tap(find.text('꿈 기록하기'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          '나는 물 위 도서관에서 종이 고래를 만났다.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tester.tap(find.text('꿈 저장하기'));
        await _wait(tester, find.text('장면 만들기'));
        final saved = (await tester.runAsync(
          () => repository.watchDreams(DreamStatusFilter.all).first,
        ))!.singleWhere((d) => d.rawText == '나는 물 위 도서관에서 종이 고래를 만났다.');
        await tester.tap(find.text('장면 만들기'));
        await _wait(tester, find.text('나중에 확인하기'));
        await tester.pump(const Duration(seconds: 21));
        expect(find.text('소설을 만들고 있어요'), findsOneWidget);
        await tester.tap(find.text('나중에 확인하기'));
        await tester.pump();
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
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        engine.dispose();
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        await repository.ready;
        engine = MockEngineClient(store: repository, stageDelay: Duration.zero);
        final scenes = (await tester.runAsync(
          () => repository.watchScenes(MemorySeedIds.volume).first,
        ))!;
        final result = scenes.singleWhere(
          (s) => s.sourceDreamIds.contains(saved.id),
        );
        await mount();
        await _wait(tester, find.text('새 장면 읽기'));
        await tester.tap(find.text('새 장면 읽기'));
        await _wait(tester, find.byType(ReaderScreen));
        expect(
          tester.widget<ReaderScreen>(find.byType(ReaderScreen)).initialSceneId,
          result.id,
        );
        await tester.pumpAndSettle();
        final passages = (await tester.runAsync(
          () => repository.watchPassages(result.id).first,
        ))!;
        expect(passages, isNotEmpty);
        expect(passages.first.firstReadAt, isNotNull);
        expect(
          (await tester.runAsync(
            () => repository.watchScenes(MemorySeedIds.volume).first,
          ))!.where((s) => s.sourceDreamIds.contains(saved.id)),
          hasLength(1),
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        engine.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'SQLite restart keeps consumed reveal quiet without consuming reading',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-p4-presentation-native-',
      );
      final file = File('${directory.path}/synthetic.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftRepository(database);
      var engine = MockEngineClient(store: repository);
      final id = await repository.submitDream(
        DreamDraft(
          id: 'native-presentation-dream',
          rawText: '가상 꿈: 나는 종이 고래와 유리 정원을 걸었다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 23),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      await repository.answerRecall(id, {});
      await repository.commitMockResult(
        id,
        result: const MockEngineResult(isFallback: false),
      );
      // Synthetic engine fixture writes its terminal metadata just as the
      // mock engine does. recordJobProgress intentionally ignores completed
      // dreams, so it must not be used to fabricate this cache after commit.
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
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              repositoryProvider.overrideWithValue(repository),
              engineClientProvider.overrideWithValue(engine),
            ],
            child: MaterialApp(
              theme: mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: CaptureFlow(
                dreamNumber: 8,
                sceneNumber: 12,
                savedDream: dream,
              ),
            ),
          ),
        );
      }

      try {
        await mount();
        await _wait(tester, find.text('새 장면 읽기'));
        final scene = (await repository.watchScenes(MemorySeedIds.volume).first)
            .singleWhere((s) => s.sourceDreamIds.contains(id));
        expect(
          (await repository.watchPassages(scene.id).first).first.firstReadAt,
          isNull,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        engine.dispose();
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftRepository(database);
        engine = MockEngineClient(store: repository);
        await mount();
        await _wait(tester, find.text('장면 읽기'));
        expect(find.text('새 장면 읽기'), findsNothing);
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
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        engine.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

Future<void> _wait(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
