import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

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

void main() {
  testWidgets(
    'trial quota explains the pause without offering an endless retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository();
      final engine = ControlledEngine(limitCode: 'trial_user_daily_limit');
      addTearDown(repository.dispose);
      addTearDown(engine.controller.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            engineClientProvider.overrideWithValue(engine),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '합성 꿈 기록');
      await tester.tap(find.text('꿈 저장하기'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('장면 만들기'));
      await tester.tap(find.text('장면 만들기'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('오늘의 체험 횟수를 모두 사용했어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
      expect(find.text('보관함에서 나중에 보기'), findsOneWidget);
    },
  );

  testWidgets('processing follows jobs and retries with a fresh engine job', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryRepository();
    final engine = ControlledEngine();
    addTearDown(repository.dispose);
    addTearDown(engine.controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(engine),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '문을 열었다.');
    await tester.tap(find.text('꿈 저장하기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('장면 만들기'));
    await tester.tap(find.text('장면 만들기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    await tester.pump();
    final initialContainer = ProviderScope.containerOf(
      tester.element(find.byType(CaptureFlow)),
    );
    expect(
      initialContainer.read(jobProgressProvider(engine.dreamId!)).error,
      isNull,
    );
    expect(
      initialContainer.read(jobProgressProvider(engine.dreamId!)).hasValue,
      isTrue,
      reason: initialContainer
          .read(jobProgressProvider(engine.dreamId!))
          .toString(),
    );
    expect(engine.controller.hasListener, isTrue);
    expect(find.text('소설을 만들고 있어요'), findsOneWidget);
    expect(find.byType(ThinkingOrb), findsOneWidget);
    expect(find.byType(BeamFrame), findsNothing);
    expect(find.textContaining('/ 04'), findsNothing);
    engine.emit(JobType.write, JobStatus.running);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CaptureFlow)),
    );
    expect(
      container.read(jobProgressProvider(engine.dreamId!)).hasError,
      isFalse,
    );
    expect(find.text('소설을 만들고 있어요'), findsOneWidget);
    engine.emit(JobType.validate, JobStatus.done);
    await tester.pump();
    expect(find.byKey(const ValueKey('reveal')), findsNothing);
    engine.emit(JobType.validate, JobStatus.failed);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('다시 시도'));
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryRepository();
    final engine = ControlledEngine();
    addTearDown(repository.dispose);
    addTearDown(engine.controller.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          engineClientProvider.overrideWithValue(engine),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '낯선 정류장에 혼자 서 있었다.');
    await tester.tap(find.text('꿈 저장하기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('장면 만들기'));
    await tester.tap(find.text('장면 만들기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    engine.emit(JobType.commit, JobStatus.done, archivedOnly: true);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('archived')), findsOneWidget);
    expect(find.textContaining('원고와 이어지지 않았어요'), findsOneWidget);
  });
}
