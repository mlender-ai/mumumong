// V2 capture in a real browser (the deploy script runs this file with
// --platform chrome, like the V1 keyboard test): the live editor, focus and
// IME composition survive the keyboard resizing the page, the save action
// stays reachable, and on the web the microphone opens the guide instead of
// recording. No custom fonts are loaded so it runs the same in a browser and
// the VM. Invented text only.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/settings.dart';

import 'support.dart';

Future<MemoryRepository> _mount(WidgetTester tester, Size size) async {
  setV2View(tester, size: size, reduceMotion: true);
  final repo = MemoryRepository();
  addTearDown(repo.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        speechInputProvider.overrideWithValue(SilentSpeech()),
        networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ],
      child: const MumumongV2App(
        home: V2CaptureFlow(dreamNumber: 1, sceneNumber: 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  for (final size in const [Size(390, 844), Size(375, 667)]) {
    testWidgets('IME keeps the V2 editor, focus and composition $size', (
      tester,
    ) async {
      addTearDown(tester.view.resetViewInsets);
      final repo = await _mount(tester, size);
      await tester.tap(find.byType(TextField));
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
          reason: 'IME resize must not replace the live editor (web=$kIsWeb)',
        );
        expect(focus.hasFocus, isTrue);
        expect(
          editor.widget.controller.value.composing,
          const TextRange(start: 6, end: 7),
        );
        expect(v2Text('꿈 저장하기').hitTestable(), findsOneWidget);
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
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  testWidgets('the web microphone opens the guide; native records in place', (
    tester,
  ) async {
    await _mount(tester, const Size(390, 844));
    if (kIsWeb) {
      await tester.tap(find.bySemanticsLabel('음성 입력 안내 · iPhone 앱 전용 녹음'));
      await tester.pumpAndSettle();
      expect(find.byType(V2VoicePage), findsOneWidget);
    } else {
      expect(find.bySemanticsLabel('말로 기록하기'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
