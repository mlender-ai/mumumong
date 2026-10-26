// Invented fixtures; these are local presentation receipts, not AI/read metrics.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/log/app_log.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/home/home_screen.dart';

class _Book extends MemoryRepository {
  bool failReceipt = false;
  final attempts = <PresentationKind>[];
  final freshClaims = <PresentationKind>[];
  @override
  Future<bool> consumePresentation({
    required String volumeId,
    required PresentationKind kind,
    required String sourceId,
  }) async {
    attempts.add(kind);
    if (failReceipt) throw StateError('synthetic_disk_unavailable');
    final fresh = await super.consumePresentation(
      volumeId: volumeId,
      kind: kind,
      sourceId: sourceId,
    );
    if (fresh) freshClaims.add(kind);
    return fresh;
  }
}

class _Engine implements EngineClient {
  final updates = StreamController<JobProgress>.broadcast();
  int enqueues = 0;
  bool cached = true;
  static const done = JobProgress(
    dreamId: 'presentation-dream',
    type: JobType.commit,
    status: JobStatus.done,
    attempt: 1,
    stageLabel: 'committed fixture',
  );
  @override
  Future<String> enqueue(String dreamId, String key) async {
    enqueues++;
    return key;
  }

  @override
  Future<String> retry(String dreamId) async =>
      throw StateError('unexpected_retry');
  @override
  Stream<JobProgress> watch(String dreamId) async* {
    if (cached) yield done;
    yield* updates.stream;
  }
}

Future<Dream> _committed(_Book book) async {
  await book.submitDream(
    DreamDraft(
      id: 'presentation-dream',
      rawText: '가상 꿈: 나는 유리 정원 위에 뜬 종이배를 보았다.',
      inputMode: DreamInputMode.text,
      dreamDate: DateTime(2026, 10, 23),
      isBackfill: false,
      updatedAt: DateTime.utc(2026, 10, 23),
    ),
  );
  await book.answerRecall('presentation-dream', {});
  await book.commitMockResult(
    'presentation-dream',
    result: const MockEngineResult(isFallback: false),
  );
  return (await book.watchDreams(DreamStatusFilter.all).first).firstWhere(
    (d) => d.id == 'presentation-dream',
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Book book,
  _Engine engine,
  Dream dream,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(book),
        engineClientProvider.overrideWithValue(engine),
      ],
      child: MaterialApp(
        theme: mumumongTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CaptureFlow(
                      dreamNumber: 8,
                      sceneNumber: 12,
                      savedDream: dream,
                    ),
                  ),
                ),
                child: const Text('결과 확인'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _flush(tester);
}

void main() {
  tearDown(AppLog.resetSinkForTesting);
  testWidgets(
    'reopen completed result without new reveal/log/read or generation',
    (tester) async {
      final book = _Book();
      final engine = _Engine();
      final dream = (await tester.runAsync(() => _committed(book)))!;
      final views = <String>[];
      AppLog.setSinkForTesting((name, _) => views.add(name));
      await _mount(tester, book, engine, dream);
      await tester.tap(find.text('결과 확인'));
      await _flush(tester);
      expect(find.text('새 장면 읽기'), findsOneWidget);
      expect(views.where((name) => name == 'reveal_viewed'), hasLength(1));
      await tester.tap(find.byTooltip('닫기'));
      await _flush(tester);
      await tester.tap(find.text('결과 확인'));
      await _flush(tester);
      expect(find.text('장면 읽기'), findsOneWidget);
      expect(find.text('원고에 보관된 장면이에요.'), findsOneWidget);
      expect(views.where((name) => name == 'reveal_viewed'), hasLength(1));
      expect(engine.enqueues, 0);
      final scenes = (await tester.runAsync(
        () => book.watchScenes(MemorySeedIds.volume).first,
      ))!;
      final scene = scenes.singleWhere(
        (s) => s.sourceDreamIds.contains(dream.id),
      );
      final passages = (await tester.runAsync(
        () => book.watchPassages(scene.id).first,
      ))!;
      expect(passages.every((p) => p.firstReadAt == null), isTrue);
      await tester.pumpWidget(const SizedBox());
      book.dispose();
      await engine.updates.close();
    },
  );

  testWidgets(
    'receipt failure keeps actual manuscript accessible and retries state only',
    (tester) async {
      final book = _Book();
      final engine = _Engine();
      final dream = (await tester.runAsync(() => _committed(book)))!;
      book.failReceipt = true;
      await _mount(tester, book, engine, dream);
      await tester.tap(find.text('결과 확인'));
      await _flush(tester);
      expect(find.text('장면 읽기'), findsOneWidget);
      expect(find.textContaining('장면은 그대로 읽을 수'), findsOneWidget);
      book.failReceipt = false;
      await tester.tap(find.text('화면 상태 다시 저장'));
      await _flush(tester);
      expect(find.text('화면 상태 다시 저장'), findsNothing);
      expect(find.text('새 장면 읽기'), findsNothing);
      expect(engine.enqueues, 0);
      expect(
        book.freshClaims.where((k) => k == PresentationKind.reveal),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
      book.dispose();
      await engine.updates.close();
    },
  );

  testWidgets('covered result does not consume presentation until visible', (
    tester,
  ) async {
    final book = _Book();
    final engine = _Engine()..cached = false;
    final dream = (await tester.runAsync(() => _committed(book)))!;
    await _mount(tester, book, engine, dream);
    await tester.tap(find.text('결과 확인'));
    await _flush(tester);
    final context = tester.element(find.byType(CaptureFlow));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('가상 덮개')),
        ),
      ),
    );
    await _flush(tester);
    engine.updates.add(_Engine.done);
    await _flush(tester);
    expect(book.attempts, isEmpty);
    Navigator.of(tester.element(find.text('가상 덮개'))).pop();
    await _flush(tester);
    expect(find.text('새 장면 읽기'), findsOneWidget);
    expect(book.freshClaims, [
      PresentationKind.reveal,
      PresentationKind.growth,
    ]);
    await tester.pumpWidget(const SizedBox());
    book.dispose();
    await engine.updates.close();
  });

  testWidgets('hidden Home tab defers growth; remount never repeats it', (
    tester,
  ) async {
    final book = _Book();
    final active = ValueNotifier(false);
    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            repositoryProvider.overrideWithValue(book),
            networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: active,
                builder: (_, shown, _) =>
                    HomeScreen(isActive: shown, onCapture: () {}),
              ),
            ),
          ),
        ),
      );
      await _flush(tester);
    }

    await mount();
    expect(book.attempts, isEmpty);
    active.value = true;
    await _flush(tester);
    expect(book.freshClaims, [PresentationKind.growth]);
    await mount();
    expect(book.freshClaims, [PresentationKind.growth]);
    expect(book.attempts, [PresentationKind.growth, PresentationKind.growth]);
    await tester.pumpWidget(const SizedBox());
    active.dispose();
    book.dispose();
  });

  testWidgets(
    'background completion waits for foreground before reserving reveal',
    (tester) async {
      final book = _Book();
      final engine = _Engine();
      final dream = (await tester.runAsync(() => _committed(book)))!;
      await _mount(tester, book, engine, dream);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.tap(find.text('결과 확인'));
      await _flush(tester);
      expect(book.attempts, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(find.text('새 장면 읽기'), findsOneWidget);
      expect(book.freshClaims, [
        PresentationKind.reveal,
        PresentationKind.growth,
      ]);
      await tester.pumpWidget(const SizedBox());
      book.dispose();
      await engine.updates.close();
    },
  );
}
