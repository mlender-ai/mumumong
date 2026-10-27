// Migrated from test/ui/p4_generation_recovery_test.dart (V1). Leaving and
// reopening generation on the V2 capture flow never sends new work: a retry
// whose acknowledgement arrives after closing still hands the job to the
// shell recovery, and a dropped stream offers a status check, not a retry.
// The third V1 test there is provider-only and stays shared.
// Invented fixtures only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/design/theme.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/capture.dart';

import 'support.dart';

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

/// The shell's part: keep generation recovery subscribed and reopen the
/// capture flow for the saved dream.
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
                  v2Route(
                    V2CaptureFlow(
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

Future<MemoryRepository> _repository(String text) async {
  final repo = MemoryRepository();
  await repo.submitDream(
    DreamDraft(
      id: 'p4-dream',
      rawText: text,
      inputMode: DreamInputMode.text,
      dreamDate: DateTime(2026, 10, 18),
      isBackfill: false,
      updatedAt: DateTime.utc(2026, 10, 18),
    ),
  );
  await repo.answerRecall('p4-dream', {});
  return repo;
}

Future<void> _mount(
  WidgetTester tester,
  MemoryRepository repo,
  _Engine engine,
) async {
  setV2View(tester, reduceMotion: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        engineClientProvider.overrideWithValue(engine),
        speechInputProvider.overrideWithValue(SilentSpeech()),
        networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ],
      child: const MumumongV2App(home: _Host()),
    ),
  );
  await _flush(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(v2Text(text).first);
  await tester.tap(v2Text(text).first);
  await _flush(tester);
}

final _processing = find.bySemanticsLabel(RegExp('^소설을 만들고 있어요'));

void main() {
  setUpAll(loadV2Fonts);

  testWidgets(
    'closing while retry acknowledgement is pending still persists shell recovery',
    (tester) async {
      final repo = (await tester.runAsync(
        () => _repository('가상 꿈: 나는 바다에 떠 있는 종이 역을 보았다.'),
      ))!;
      await tester.runAsync(
        () => repo.recordJobProgress(
          const JobProgress(
            dreamId: 'p4-dream',
            type: JobType.validate,
            status: JobStatus.failed,
            attempt: 3,
            stageLabel: '실패 fixture',
          ),
        ),
      );
      final engine = _Engine()..retryBarrier = Completer<void>();
      await _mount(tester, repo, engine);
      await tester.tap(find.text('작업 확인 · failed'));
      await _flush(tester);
      await _tapText(tester, '다시 시도');
      expect(engine.retries, 1);
      await _tapText(tester, '나중에 확인하기');

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
      final repo = (await tester.runAsync(
        () => _repository('가상 꿈: 종이 고래가 빈 역의 천장을 헤엄쳤다.'),
      ))!;
      final engine = _Engine();
      await _mount(tester, repo, engine);
      expect(engine.watches, 1);
      await tester.tap(find.text('작업 확인 · processing'));
      await _flush(tester);
      expect(engine.watches, 1, reason: 'shell and route share one stream');

      await tester.pump(const Duration(seconds: 21));
      await _tapText(tester, '나중에 확인하기');
      expect(engine.controller.hasListener, isTrue);
      engine.controller.addError(StateError('synthetic_transport_failure'));
      await _flush(tester);

      await tester.tap(find.text('작업 확인 · processing'));
      await _flush(tester);
      expect(v2Text('연결을 확인하고 있어요'), findsOneWidget);
      expect(v2Text('다시 시도'), findsNothing);
      expect(v2Text('접수 다시 확인'), findsNothing);
      await _tapText(tester, '상태 다시 확인');
      engine.emit(JobStatus.running);
      await _flush(tester);
      expect(_processing, findsOneWidget);
      expect(v2Text('연결을 확인하고 있어요'), findsNothing);
      expect(engine.enqueues, 0);
      expect(engine.retries, 0);

      engine.emit(JobStatus.failed);
      await _flush(tester);
      expect(v2Text('다시 시도'), findsOneWidget);
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
}
