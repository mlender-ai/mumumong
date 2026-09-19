import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/capture/draft_autosave.dart';

DreamDraft draft(String text) => DreamDraft(
  id: '00000000-0000-4000-8000-000000009901',
  rawText: text,
  inputMode: DreamInputMode.text,
  dreamDate: DateTime(2026, 9, 18),
  isBackfill: true,
  updatedAt: DateTime.utc(2026, 9, 19),
);

Widget app(MumumongRepository repository) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: mumumongTheme(),
    home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
  ),
);

class DelayedRepository extends MemoryRepository {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> saveDraft(DreamDraft draft) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await super.saveDraft(draft);
  }
}

class FlakyRepository extends MemoryRepository {
  int attempts = 0;
  @override
  Future<void> saveDraft(DreamDraft draft) async {
    if (++attempts == 1) throw StateError('storage unavailable');
    await super.saveDraft(draft);
  }
}

void main() {
  testWidgets(
    'text saves only after 500ms and background flushes latest input',
    (tester) async {
      final repository = MemoryRepository();
      await tester.pumpWidget(app(repository));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '첫 문장');
      await tester.pump(const Duration(milliseconds: 499));
      expect(await repository.loadDraft(), isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect((await repository.loadDraft())?.rawText, '첫 문장');
      await tester.enterText(find.byType(TextField), '마지막 입력');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect((await repository.loadDraft())?.rawText, '마지막 입력');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      repository.dispose();
    },
  );

  testWidgets('resume is asked once and preserves draft identity and date', (
    tester,
  ) async {
    final repository = MemoryRepository();
    final original = draft('남겨 둔 기억');
    await repository.saveDraft(original);
    await tester.pumpWidget(app(repository));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('쓰던 꿈이 남아 있어요'), findsOneWidget);
    await tester.tap(find.text('이어서 쓰기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('남겨 둔 기억'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '이어서 쓴 기억');
    await tester.pump(const Duration(milliseconds: 500));
    final saved = await repository.loadDraft();
    expect(saved?.id, original.id);
    expect(saved?.dreamDate, original.dreamDate);
    expect(saved?.isBackfill, true);
    expect(find.text('쓰던 꿈이 남아 있어요'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    repository.dispose();
  });

  testWidgets(
    'new draft discards old text and voice partial is saved immediately',
    (tester) async {
      final repository = MemoryRepository();
      await repository.saveDraft(draft('폐기할 기억'));
      await tester.pumpWidget(app(repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('새로 쓰기'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(await repository.loadDraft(), isNull);
      expect(find.text('폐기할 기억'), findsNothing);
      await tester.tap(find.bySemanticsLabel('녹음 시작'));
      await tester.pump(const Duration(milliseconds: 1500));
      final saved = await repository.loadDraft();
      expect(saved?.rawText, isNotEmpty);
      expect(saved?.inputMode, DreamInputMode.voice);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      repository.dispose();
    },
  );

  testWidgets('failed autosave silently retries the newest value', (
    tester,
  ) async {
    final repository = FlakyRepository();
    final autosave = DraftAutosave(repository);
    autosave.changed(draft('처음'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(await repository.loadDraft(), isNull);
    autosave.changed(draft('최신'));
    await tester.pump(const Duration(milliseconds: 500));
    expect((await repository.loadDraft())?.rawText, '최신');
    autosave.dispose();
    await tester.pump();
    repository.dispose();
  });

  testWidgets('transient save failure retries without another edit', (
    tester,
  ) async {
    final repository = FlakyRepository();
    final autosave = DraftAutosave(repository);
    autosave.changed(draft('자동 재시도'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.attempts, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.attempts, 2);
    expect((await repository.loadDraft())?.rawText, '자동 재시도');
    autosave.dispose();
    await tester.pump();
    repository.dispose();
  });

  test(
    'submission waits for an in-flight save and does not resurrect a draft',
    () async {
      final repository = DelayedRepository();
      final autosave = DraftAutosave(repository);
      autosave.changed(draft('처음'), immediate: true);
      await repository.started.future;
      final submitted = autosave.submit(draft('최종'));
      repository.release.complete();
      final id = await submitted;
      expect(await repository.loadDraft(), isNull);
      expect(
        (await repository.watchDreams(DreamStatusFilter.all).first)
            .singleWhere((dream) => dream.id == id)
            .rawText,
        '최종',
      );
      autosave.dispose();
      await Future<void>.delayed(Duration.zero);
      repository.dispose();
    },
  );

  test('discard waits for an in-flight save', () async {
    final repository = DelayedRepository();
    final autosave = DraftAutosave(repository);
    autosave.changed(draft('폐기'), immediate: true);
    await repository.started.future;
    final discarded = autosave.discard();
    repository.release.complete();
    await discarded;
    expect(await repository.loadDraft(), isNull);
    autosave.dispose();
    await Future<void>.delayed(Duration.zero);
    repository.dispose();
  });

  test(
    'autosaved draft survives reopening a file database without dispose flush',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mumumong-autosave-',
      );
      final file = File('${directory.path}/draft.sqlite');
      final first = AppDatabase.forTesting(NativeDatabase(file));
      final autosave = DraftAutosave(DriftRepository(first));
      autosave.changed(draft('재시작 후 복원'));
      await autosave.flush();
      await first.close();
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        expect(
          (await DriftRepository(second).loadDraft())?.rawText,
          '재시작 후 복원',
        );
      } finally {
        autosave.dispose();
        await second.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
