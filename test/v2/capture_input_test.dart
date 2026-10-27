// Migrated from test/ui/capture_keyboard_test.dart and the screen tests of
// test/ui/draft_autosave_test.dart (V1). The same input rules on the V2
// capture flow: the live editor survives the keyboard and IME, autosave
// failures are visible and recover, a resumed draft keeps its identity,
// voice partials save at once, and typing wins over a late transcript.
// Invented fixtures only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/capture.dart';

import 'support.dart';

DreamDraft _draft(String text) => DreamDraft(
  id: '00000000-0000-4000-8000-000000009901',
  rawText: text,
  inputMode: DreamInputMode.text,
  dreamDate: DateTime(2026, 9, 18),
  isBackfill: true,
  updatedAt: DateTime.utc(2026, 9, 19),
);

class _UnavailableDraft extends MemoryRepository {
  bool failRead = true;
  bool hangRead = false;
  final pendingRead = Completer<DreamDraft?>();

  @override
  Future<DreamDraft?> loadDraft() {
    if (hangRead) return pendingRead.future;
    if (failRead) return Future.error(StateError('test_storage_unavailable'));
    return super.loadDraft();
  }
}

class _UnwritableDraft extends MemoryRepository {
  bool failWrite = true;

  @override
  Future<void> saveDraft(DreamDraft draft) {
    if (failWrite) return Future.error(StateError('test_storage_full'));
    return super.saveDraft(draft);
  }
}

class _CountingDraft extends MemoryRepository {
  int saves = 0;

  @override
  Future<void> saveDraft(DreamDraft draft) async {
    saves++;
    await super.saveDraft(draft);
  }
}

class _Speech implements SpeechInput {
  final controller = StreamController<SpeechUpdate>.broadcast();

  @override
  Stream<SpeechUpdate> get updates => controller.stream;

  @override
  Future<void> start() async {
    controller.add(const SpeechUpdate(text: '목소리로 남긴 기억'));
  }

  @override
  Future<void> stop() async {}
}

class _DelayedSpeech extends _Speech {
  final firstStart = Completer<void>();
  int starts = 0;

  @override
  Future<void> start() async {
    if (++starts == 1) await firstStart.future;
  }
}

Future<void> _mount(
  WidgetTester tester,
  MumumongRepository repository, {
  SpeechInput? speech,
  Size size = const Size(402, 874),
  double scale = 1,
  bool settle = true,
}) async {
  setV2View(tester, size: size, scale: scale, reduceMotion: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        speechInputProvider.overrideWithValue(speech ?? SilentSpeech()),
        networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ],
      child: const MumumongV2App(
        home: V2CaptureFlow(dreamNumber: 8, sceneNumber: 12),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

Finder get _editor => find.byType(TextField);
Finder get _record => find.bySemanticsLabel('말로 기록하기');
Finder get _stop => find.bySemanticsLabel('녹음 멈추기');
Finder get _saveAction => v2Text('꿈 저장하기');

void main() {
  setUpAll(loadV2Fonts);

  // ---- capture_keyboard_test.dart

  testWidgets('autosave failure is visible without losing input or focus', (
    tester,
  ) async {
    final repo = _UnwritableDraft();
    addTearDown(repo.dispose);
    await _mount(tester, repo);
    await tester.tap(_editor);
    await tester.enterText(_editor, '가상 PWA 초안: 투명한 종이배');
    await tester.pump(const Duration(milliseconds: 550));
    final editor = tester.state<EditableTextState>(find.byType(EditableText));
    expect(v2TextContaining('자동 저장하지 못했어요'), findsOneWidget);
    expect(editor.widget.focusNode.hasFocus, isTrue);
    expect(editor.widget.controller.text, '가상 PWA 초안: 투명한 종이배');

    tester.view.viewInsets = const FakeViewPadding(bottom: 290);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.state(find.byType(EditableText)), same(editor));
    expect(_saveAction.hitTestable(), findsOneWidget);

    repo.failWrite = false;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect((await repo.loadDraft())?.rawText, '가상 PWA 초안: 투명한 종이배');
    expect(v2TextContaining('자동 저장하지 못했어요'), findsNothing);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(375, 667), 1.6),
    (const Size(430, 932), 1.0),
  ]) {
    testWidgets('IME retains editor/focus/composition $size x$scale', (
      tester,
    ) async {
      final repo = MemoryRepository();
      addTearDown(repo.dispose);
      addTearDown(tester.view.resetViewInsets);
      await _mount(tester, repo, size: size, scale: scale);
      await tester.tap(_editor);
      await tester.pump();
      final editor = tester.state<EditableTextState>(find.byType(EditableText));
      final focus = editor.widget.focusNode;
      expect(focus.hasFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '종이별이 춤을',
          selection: TextSelection.collapsed(offset: 7),
          composing: TextRange(start: 6, end: 7),
        ),
      );
      for (final bottom in [40.0, 160.0, 290.0, 310.0, 0.0, 290.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: bottom);
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(editor),
          reason: 'IME resize must not replace the live editor ($bottom)',
        );
        expect(focus.hasFocus, isTrue);
        expect(
          editor.widget.controller.value.composing,
          const TextRange(start: 6, end: 7),
        );
        expect(_saveAction.hitTestable(), findsOneWidget, reason: '$bottom');
        expect(tester.takeException(), isNull);
      }
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '가상 꿈: 종이별이 춤을 췄다.',
          selection: TextSelection.collapsed(offset: 17),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect((await repo.loadDraft())?.rawText, '가상 꿈: 종이별이 춤을 췄다.');
      await tester.tap(_saveAction);
      await tester.pumpAndSettle();
      expect(v2Text('꿈이 저장됐어요'), findsOneWidget);
      expect(await repo.loadDraft(), isNull);
      await _unmount(tester);
    });
  }

  for (final hung in [false, true]) {
    testWidgets('draft read failure is visible and retryable hung=$hung', (
      tester,
    ) async {
      final repo = _UnavailableDraft()..hangRead = hung;
      addTearDown(repo.dispose);
      await _mount(tester, repo, settle: false);
      await tester.pump();
      if (hung) await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(v2Text('쓰던 꿈을\n안전하게 열지 못했어요'), findsOneWidget);
      expect(_editor, findsNothing);
      expect(v2Text('다시 확인하기').hitTestable(), findsOneWidget);

      repo
        ..hangRead = false
        ..failRead = false;
      await tester.tap(v2Text('다시 확인하기'));
      await tester.pumpAndSettle();
      await tester.enterText(_editor, '가상 꿈: 종이별이 빛났다.');
      await tester.pump(const Duration(milliseconds: 600));
      if (hung) {
        repo.pendingRead.complete(null);
        await tester.pump();
      }
      expect((await repo.loadDraft())?.rawText, '가상 꿈: 종이별이 빛났다.');
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }

  // ---- draft_autosave_test.dart (screen tests)

  testWidgets(
    'controller-based input autosaves but selection-only changes do not write',
    (tester) async {
      final repo = _CountingDraft();
      addTearDown(repo.dispose);
      await _mount(tester, repo);
      final controller = tester.widget<TextField>(_editor).controller!;
      controller.text = '가상 꿈: 접근성으로 남긴 종이별';
      await tester.pump(const Duration(milliseconds: 500));
      expect((await repo.loadDraft())?.rawText, controller.text);
      expect(repo.saves, 1);
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.saves, 1);
      await _unmount(tester);
    },
  );

  testWidgets(
    'text saves only after 500ms and background flushes latest input',
    (tester) async {
      final repo = MemoryRepository();
      addTearDown(repo.dispose);
      await _mount(tester, repo);
      await tester.enterText(_editor, '첫 문장');
      await tester.pump(const Duration(milliseconds: 499));
      expect(await repo.loadDraft(), isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect((await repo.loadDraft())?.rawText, '첫 문장');
      await tester.enterText(_editor, '마지막 입력');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect((await repo.loadDraft())?.rawText, '마지막 입력');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _unmount(tester);
    },
  );

  testWidgets('resume is asked once and preserves draft identity and date', (
    tester,
  ) async {
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    final original = _draft('남겨 둔 기억');
    await repo.saveDraft(original);
    await _mount(tester, repo);
    expect(v2Text('쓰던 꿈이 남아 있어요'), findsOneWidget);
    await tester.tap(v2Text('이어서 쓰기'));
    await tester.pumpAndSettle();
    expect(find.text('남겨 둔 기억'), findsOneWidget);
    await tester.enterText(_editor, '이어서 쓴 기억');
    await tester.pump(const Duration(milliseconds: 500));
    final saved = await repo.loadDraft();
    expect(saved?.id, original.id);
    expect(saved?.dreamDate, original.dreamDate);
    expect(saved?.isBackfill, isTrue);
    expect(v2Text('쓰던 꿈이 남아 있어요'), findsNothing);
    await _unmount(tester);
  });

  testWidgets(
    'a new draft discards the old text; a voice partial saves at once',
    (tester) async {
      final repo = MemoryRepository();
      addTearDown(repo.dispose);
      await repo.saveDraft(_draft('폐기할 기억'));
      final speech = _Speech();
      addTearDown(speech.controller.close);
      await _mount(tester, repo, speech: speech);
      await tester.tap(v2Text('새로 쓰기'));
      await tester.pumpAndSettle();
      expect(await repo.loadDraft(), isNull);
      expect(find.text('폐기할 기억'), findsNothing);

      await tester.tap(_record);
      await tester.pump(const Duration(milliseconds: 1500));
      final saved = await repo.loadDraft();
      expect(saved?.rawText, isNotEmpty);
      expect(saved?.inputMode, DreamInputMode.voice);
      await _unmount(tester);
    },
  );

  testWidgets('a voice transcript appears in the editor while recording', (
    tester,
  ) async {
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    final speech = _Speech();
    addTearDown(speech.controller.close);
    await _mount(tester, repo, speech: speech);
    await tester.tap(_record);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('목소리로 남긴 기억'), findsOneWidget);
    expect(v2TextContaining('듣고 있어요'), findsOneWidget);
    expect(_stop, findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a late cancelled voice start cannot stop the next session', (
    tester,
  ) async {
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    final speech = _DelayedSpeech();
    addTearDown(speech.controller.close);
    await _mount(tester, repo, speech: speech);
    await tester.tap(_record);
    await tester.pumpAndSettle();
    await tester.pump();
    expect(speech.starts, 1);
    await tester.tap(_stop);
    await tester.pumpAndSettle();
    expect(_record, findsOneWidget);

    await tester.tap(_record);
    await tester.pumpAndSettle();
    await tester.pump();
    expect(_stop, findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(speech.starts, 2, reason: 'the second session started first');

    speech.firstStart.completeError(StateError('test_cancelled_permission'));
    await tester.pumpAndSettle();
    expect(speech.starts, 2);
    expect(_stop, findsOneWidget);
    speech.controller.add(const SpeechUpdate(text: '가상 꿈: 종이별의 새 목소리'));
    await tester.pumpAndSettle();
    expect((await repo.loadDraft())?.rawText, '가상 꿈: 종이별의 새 목소리');
    await _unmount(tester);
  });

  testWidgets(
    'typing stops transcription before a late partial can overwrite edits',
    (tester) async {
      final repo = MemoryRepository();
      addTearDown(repo.dispose);
      final speech = _Speech();
      addTearDown(speech.controller.close);
      await _mount(tester, repo, speech: speech);
      await tester.tap(_record);
      await tester.pumpAndSettle();
      await tester.tap(_editor);
      await tester.pumpAndSettle();
      await tester.enterText(_editor, '가상 꿈: 직접 고친 종이별');
      speech.controller.add(const SpeechUpdate(text: '가상 꿈: 늦게 온 음성 조각'));
      await tester.pump(const Duration(milliseconds: 600));
      expect((await repo.loadDraft())?.rawText, '가상 꿈: 직접 고친 종이별');
      expect(v2TextContaining('듣고 있어요'), findsNothing);
      expect(tester.widget<TextField>(_editor).focusNode!.hasFocus, isTrue);
      await _unmount(tester);
    },
  );
}
