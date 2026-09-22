import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';

void main() {
  testWidgets('long press edits to locked U and restores original provenance', (
    tester,
  ) async {
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    final volume = (await tester.runAsync(
      () => repository.watchActiveVolume().first,
    ))!;
    final scenes = (await tester.runAsync(
      () => repository.watchScenes(volume.id).first,
    ))!;
    final original = (await tester.runAsync(
      () => repository.watchPassages(scenes.last.id).first,
    ))!.first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: mumumongTheme(), home: const ReaderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(ReaderPassage).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '내가 직접 고친 문장');
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    final edited = (await tester.runAsync(
      () => repository.watchPassages(scenes.last.id).first,
    ))!.first;
    expect(edited.origin, PassageOrigin.user);
    expect(edited.locked, true);
    expect(edited.text, '내가 직접 고친 문장');
    expect(edited.originalText, original.text);
    await tester.longPress(find.byType(ReaderPassage).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('원래 문장으로'));
    await tester.pumpAndSettle();
    final restored = (await tester.runAsync(
      () => repository.watchPassages(scenes.last.id).first,
    ))!.first;
    expect(restored.text, original.text);
    expect(restored.origin, original.origin);
    expect(restored.sourceElementIds, original.sourceElementIds);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('cancel leaves manuscript untouched and source sheet scrolls', (
    tester,
  ) async {
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: mumumongTheme(), home: const ReaderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(ReaderPassage).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '저장하지 않을 내용');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('저장하지 않을 내용'), findsNothing);
    await tester.runAsync(() async {
      await tester.tap(find.byType(ReaderPassage).first);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.text('원문'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
