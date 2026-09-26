import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

class ControlledEngine implements EngineClient {
  final controller = StreamController<JobProgress>.broadcast();
  final keys = <String>[];
  String? dreamId;
  @override
  Future<String> enqueue(String dreamId, String key) async {
    this.dreamId = dreamId;
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
  testWidgets('processing follows jobs and retries with the stable dream key', (
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
    await tester.tap(find.text('기록 저장'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('전체 건너뛰기'));
    await tester.tap(find.text('전체 건너뛰기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('꿈을 읽는 중'), findsOneWidget);
    expect(find.text('조금 더 시간이 필요해요. 꿈은 안전하게 저장되어 있어요.'), findsOneWidget);
    engine.emit(JobType.write, JobStatus.running);
    await tester.pump();
    expect(find.text('장면을 쓰는 중'), findsOneWidget);
    engine.emit(JobType.validate, JobStatus.done);
    await tester.pump();
    expect(find.byKey(const ValueKey('reveal')), findsNothing);
    engine.emit(JobType.validate, JobStatus.failed);
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
    expect(engine.keys[1], engine.keys[0]);
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
    await tester.tap(find.text('기록 저장'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('전체 건너뛰기'));
    await tester.tap(find.text('전체 건너뛰기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    engine.emit(JobType.commit, JobStatus.done, archivedOnly: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('archived')), findsOneWidget);
    expect(find.textContaining('원고와 이어지지 않았어요'), findsOneWidget);
  });
}
