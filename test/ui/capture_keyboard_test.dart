import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';

class UnavailableDraftRepository extends MemoryRepository {
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

class UnwritableDraftRepository extends MemoryRepository {
  bool failWrite = true;
  @override
  Future<void> saveDraft(DreamDraft draft) {
    if (failWrite) return Future.error(StateError('test_storage_full'));
    return super.saveDraft(draft);
  }
}

// Run on both VM and Chrome. A VM-only keyboard snapshot never exercises the
// web-only help row that used to destroy EditableText as the IME appeared.
void main() {
  testWidgets('autosave failure is visible without losing input or focus', (
    tester,
  ) async {
    final repo = UnwritableDraftRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 1, sceneNumber: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '가상 PWA 초안: 투명한 종이배');
    await tester.pump(const Duration(milliseconds: 550));
    final editor = tester.state<EditableTextState>(find.byType(EditableText));
    expect(find.textContaining('자동 저장하지 못했어요'), findsOneWidget);
    expect(editor.widget.focusNode.hasFocus, isTrue);
    expect(editor.widget.controller.text, '가상 PWA 초안: 투명한 종이배');
    tester.view.viewInsets = const FakeViewPadding(bottom: 290);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.state(find.byType(EditableText)), same(editor));
    expect(find.text('꿈 저장하기').hitTestable(), findsOneWidget);
    repo.failWrite = false;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect((await repo.loadDraft())?.rawText, '가상 PWA 초안: 투명한 종이배');
    expect(find.textContaining('자동 저장하지 못했어요'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    repo.dispose();
  });

  for (final (size, scale, night) in [
    (const Size(390, 844), 1.0, false),
    (const Size(375, 667), 1.6, false),
    (const Size(430, 932), 1.0, true),
  ]) {
    testWidgets(
      'IME retains editor/focus/composition $size $scale night=$night',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        final repo = MemoryRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: night ? dreamNightTheme() : mumumongTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const CaptureFlow(dreamNumber: 1, sceneNumber: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final editor = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
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
            reason: 'IME resize must not replace the live editor (web=$kIsWeb)',
          );
          expect(focus.hasFocus, isTrue);
          expect(
            editor.widget.controller.value.composing,
            const TextRange(start: 6, end: 7),
          );
          expect(find.text('꿈 저장하기').hitTestable(), findsOneWidget);
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
        await tester.tap(find.text('꿈 저장하기'));
        await tester.pumpAndSettle();
        expect(find.text('꿈이 저장됐어요'), findsOneWidget);
        expect(await repo.loadDraft(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        repo.dispose();
      },
    );
  }

  for (final hung in [false, true]) {
    testWidgets('draft read failure is visible and retryable hung=$hung', (
      tester,
    ) async {
      final repo = UnavailableDraftRepository()..hangRead = hung;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: const CaptureFlow(dreamNumber: 1, sceneNumber: 1),
          ),
        ),
      );
      await tester.pump();
      if (hung) await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.text('쓰던 꿈을 안전하게 열지 못했어요'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('다시 확인하기').hitTestable(), findsOneWidget);
      repo
        ..hangRead = false
        ..failRead = false;
      await tester.tap(find.text('다시 확인하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '가상 꿈: 종이별이 빛났다.');
      await tester.pump(const Duration(milliseconds: 600));
      if (hung) {
        repo.pendingRead.complete(null);
        await tester.pump();
      }
      expect((await repo.loadDraft())?.rawText, '가상 꿈: 종이별이 빛났다.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      repo.dispose();
    });
  }
}
