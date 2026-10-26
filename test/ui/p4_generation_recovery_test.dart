import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

class _Engine implements EngineClient {
  final controller = StreamController<JobProgress>.broadcast();
  int enqueues = 0;
  int retries = 0;
  int watches = 0;
  Completer<void>? retryBarrier;
  @override
  Future<String> enqueue(String dreamId, String idempotencyKey) async {
    enqueues++;
    return idempotencyKey;
  }

  @override
  Future<String> retry(String dreamId) async {
    retries++;
    await retryBarrier?.future;
    return 'retry';
  }

  @override
  Stream<JobProgress> watch(String dreamId) {
    watches++;
    return controller.stream;
  }

  void emit(JobStatus status, {JobType type = JobType.write}) => controller.add(
    JobProgress(
      dreamId: 'p4-dream',
      type: type,
      status: status,
      attempt: 1,
      stageLabel: '실제 테스트 상태',
    ),
  );
}

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(generationRecoveryProvider);
    final dreams = ref.watch(dreamsProvider(DreamStatusFilter.all)).value;
    final dream = dreams?.where((d) => d.id == 'p4-dream').firstOrNull;
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: dream == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CaptureFlow(
                      dreamNumber: 1,
                      sceneNumber: 1,
                      savedDream: dream,
                    ),
                  ),
                ),
          child: Text('작업 확인 · ${dream?.status.name ?? "loading"}'),
        ),
      ),
    );
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'closing while retry acknowledgement is pending still persists shell recovery',
    (tester) async {
      final repo = MemoryRepository();
      final engine = _Engine()..retryBarrier = Completer<void>();
      await repo.submitDream(
        DreamDraft(
          id: 'p4-dream',
          rawText: '나는 바다에 떠 있는 종이 역을 보았다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      await repo.answerRecall('p4-dream', {});
      await repo.recordJobProgress(
        const JobProgress(
          dreamId: 'p4-dream',
          type: JobType.validate,
          status: JobStatus.failed,
          attempt: 3,
          stageLabel: '실패 fixture',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            engineClientProvider.overrideWithValue(engine),
          ],
          child: MaterialApp(theme: mumumongTheme(), home: const _Host()),
        ),
      );
      await _flush(tester);
      await tester.tap(find.text('작업 확인 · failed'));
      await _flush(tester);
      await tester.tap(find.text('다시 시도'));
      await _flush(tester);
      expect(engine.retries, 1);
      await tester.tap(find.text('나중에 확인하기'));
      await _flush(tester);
      await tester.runAsync(() async {
        engine.retryBarrier!.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await _flush(tester);
      expect(find.text('작업 확인 · processing'), findsOneWidget);
      expect(engine.controller.hasListener, isTrue);
      expect(engine.enqueues, 0);
      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
      await tester.runAsync(engine.controller.close);
      repo.dispose();
    },
  );

  testWidgets(
    '21 seconds, leave/reopen, stream recovery never enqueue or retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository();
      final engine = _Engine();
      await repo.submitDream(
        DreamDraft(
          id: 'p4-dream',
          rawText: '종이 고래가 빈 역의 천장을 헤엄쳤다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      await repo.answerRecall('p4-dream', {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            engineClientProvider.overrideWithValue(engine),
          ],
          child: MaterialApp(theme: mumumongTheme(), home: const _Host()),
        ),
      );
      await _flush(tester);
      expect(engine.watches, 1);
      await tester.tap(find.text('작업 확인 · processing'));
      await _flush(tester);
      expect(
        engine.watches,
        1,
        reason: 'shell and route share a single stream',
      );
      await tester.pump(const Duration(seconds: 21));
      await tester.tap(find.text('나중에 확인하기'));
      await _flush(tester);
      expect(engine.controller.hasListener, isTrue);
      engine.controller.addError(StateError('synthetic_transport_failure'));
      await _flush(tester);
      await tester.tap(find.text('작업 확인 · processing'));
      await _flush(tester);
      expect(find.text('연결을 확인하고 있어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
      expect(find.text('접수 다시 확인'), findsNothing);
      await tester.tap(find.text('상태 다시 확인'));
      await _flush(tester);
      engine.emit(JobStatus.running);
      await _flush(tester);
      expect(find.text('소설을 만들고 있어요'), findsOneWidget);
      expect(engine.enqueues, 0);
      expect(engine.retries, 0);
      engine.emit(JobStatus.failed);
      await _flush(tester);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(
        (await tester.runAsync(
          () => repo.watchDreams(DreamStatusFilter.all).first,
        ))!.singleWhere((d) => d.id == 'p4-dream').status,
        DreamStatus.failed,
      );
      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
      expect(engine.controller.hasListener, isFalse);
      await tester.runAsync(engine.controller.close);
      repo.dispose();
    },
  );

  test(
    'persisted processing reattaches after a fresh provider container without sending work',
    () async {
      final repo = MemoryRepository();
      final engine = _Engine();
      await repo.submitDream(
        DreamDraft(
          id: 'p4-dream',
          rawText: '유리 벤치가 바다에 떠 있었다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 18),
          isBackfill: false,
          updatedAt: DateTime.utc(2026, 10, 18),
        ),
      );
      await repo.answerRecall('p4-dream', {});
      Future<ProviderContainer> open() async {
        final container = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            engineClientProvider.overrideWithValue(engine),
          ],
        );
        container.listen(generationRecoveryProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        return container;
      }

      final first = await open();
      expect(engine.controller.hasListener, isTrue);
      first.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(engine.controller.hasListener, isFalse);
      final second = await open();
      expect(engine.watches, 2);
      expect(engine.enqueues, 0);
      expect(engine.retries, 0);
      second.dispose();
      await Future<void>.delayed(Duration.zero);
      await engine.controller.close();
      repo.dispose();
    },
  );
}
