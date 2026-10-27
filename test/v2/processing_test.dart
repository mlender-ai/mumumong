// Migrated from test/ui/processing_state_test.dart (V1). The same rules on
// the V2 capture flow: processing follows real jobs only, retry starts a new
// engine job, a trial limit pauses without an endless retry, and an
// archive-only result leaves processing for archive guidance.
// Invented fixtures only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/capture.dart';

import 'support.dart';

class ControlledEngine implements EngineClient {
  ControlledEngine({this.limitCode});

  final String? limitCode;
  final controller = StreamController<JobProgress>.broadcast();
  final keys = <String>[];
  String? dreamId;

  @override
  Future<String> enqueue(String dreamId, String key) async {
    this.dreamId = dreamId;
    keys.add(key);
    if (limitCode != null) throw TrialLimitException(limitCode!);
    return key;
  }

  @override
  Future<String> retry(String dreamId) async {
    this.dreamId = dreamId;
    const key = 'retry-key';
    keys.add(key);
    return key;
  }

  @override
  Stream<JobProgress> watch(String dreamId) => controller.stream;

  void emit(JobType type, JobStatus status, {bool archivedOnly = false}) =>
      controller.add(
        JobProgress(
          dreamId: dreamId!,
          type: type,
          status: status,
          attempt: 1,
          stageLabel: '',
          archivedOnly: archivedOnly,
        ),
      );
}

Future<void> _startProcessing(
  WidgetTester tester,
  ControlledEngine engine,
  String text,
) async {
  setV2View(tester, reduceMotion: true);
  final repository = MemoryRepository();
  addTearDown(repository.dispose);
  addTearDown(engine.controller.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        engineClientProvider.overrideWithValue(engine),
        speechInputProvider.overrideWithValue(SilentSpeech()),
        networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ],
      child: const MumumongV2App(
        home: V2CaptureFlow(dreamNumber: 8, sceneNumber: 12),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('v2-dream-editor')), text);
  await tester.pump();
  await tester.ensureVisible(find.text('꿈 저장하기'));
  await tester.tap(find.text('꿈 저장하기'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('장면 만들기'));
  await tester.tap(find.text('장면 만들기'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadV2Fonts);

  testWidgets(
    'trial quota explains the pause without offering an endless retry',
    (tester) async {
      final engine = ControlledEngine(limitCode: 'trial_user_daily_limit');
      await _startProcessing(tester, engine, '가상 기록: 합성 꿈 기록');
      await tester.pumpAndSettle();
      expect(v2TextContaining('오늘의 체험 횟수를'), findsOneWidget);
      expect(v2Text('다시 시도'), findsNothing);
      expect(v2Text('보관함에서 나중에 보기'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('processing follows jobs and retries with a fresh engine job', (
    tester,
  ) async {
    final engine = ControlledEngine();
    await _startProcessing(tester, engine, '가상 기록: 문을 열었다.');

    // No local timer may invent a failure or a result.
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(V2CaptureFlow)),
    );
    expect(
      container.read(jobProgressProvider(engine.dreamId!)).hasError,
      isFalse,
    );
    expect(engine.controller.hasListener, isTrue);
    expect(find.bySemanticsLabel(RegExp('^소설을 만들고 있어요')), findsOneWidget);
    expect(v2Text('다시 시도'), findsNothing);

    engine.emit(JobType.write, JobStatus.running);
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^소설을 만들고 있어요')), findsOneWidget);

    engine.emit(JobType.validate, JobStatus.done);
    await tester.pump();
    expect(v2Text('새 장면 읽기'), findsNothing);

    engine.emit(JobType.validate, JobStatus.failed);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(v2Text('다시 시도'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(v2Text('다시 시도'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.keys, hasLength(2));
    expect(engine.keys[0], engine.dreamId);
    expect(engine.keys[1], 'retry-key');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('standalone completion exits processing into archive guidance', (
    tester,
  ) async {
    final engine = ControlledEngine();
    await _startProcessing(tester, engine, '가상 기록: 낯선 정류장에 혼자 서 있었다.');
    engine.emit(JobType.commit, JobStatus.done, archivedOnly: true);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(v2TextContaining('원고와 이어지지 않았어요'), findsOneWidget);
    expect(v2Text('새 장면 읽기'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
