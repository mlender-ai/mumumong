// V2 presentation must keep V1 behavior: same repository calls, receipts and
// recovery. Invented fixtures only (MemoryRepository seed, mock engine).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/preview/preview_root.dart';
import 'package:mumumong/v2/screens/reader.dart';
import 'package:mumumong/v2/screens/settings.dart';

import 'support.dart';

const _dream = '가상 테스트: 유리로 된 정류장에서 버스를 기다렸다. 바닥 아래로 물이 흘렀다.';

Future<void> _capture(WidgetTester tester) async {
  await tester.tap(find.text('꿈 기록'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('v2-dream-editor')), _dream);
  await tester.pump();
  await tester.tap(find.text('꿈 저장하기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('home reads the real volume, progress and newest scene', (
    tester,
  ) async {
    await mountV2(tester);
    expect(v2Text('이름 없는 원고'), findsOneWidget);
    expect(find.bySemanticsLabel('원고 42%'), findsWidgets);
    expect(v2Text('붉은 문'), findsOneWidget);
    expect(find.text('새 장면 읽기'), findsOneWidget);
  });

  // Found with VoiceOver labels on the simulator: the home button that opens
  // every setting was announced as reading settings.
  testWidgets('the home settings button is named for what it opens', (
    tester,
  ) async {
    await mountV2(tester);
    expect(find.bySemanticsLabel('읽기 설정'), findsNothing);
    await tester.tap(find.bySemanticsLabel('설정'));
    await tester.pumpAndSettle();
    expect(find.byType(V2SettingsScreen), findsOneWidget);
  });

  testWidgets('capture → save → process → reveal → reader → home growth', (
    tester,
  ) async {
    final repo = await mountV2(tester);
    await _capture(tester);
    expect(v2Text('꿈이 저장됐어요'), findsOneWidget);
    final saved = await snapshot(
      tester,
      repo.watchDreams(DreamStatusFilter.all),
    );
    expect(saved.where((d) => d.rawText == _dream), hasLength(1));

    await tester.tap(find.text('장면 만들기'));
    await pumpUntil(tester, find.text('새 장면 읽기'));
    expect(v2Text('문 밖의 여자'), findsOneWidget);
    expect(v2TextContaining('꿈이 한 장면이 되었어요'), findsOneWidget);

    await tester.tap(find.text('새 장면 읽기'));
    await tester.pumpAndSettle();
    expect(v2TextContaining('복도 바닥에 물이 차 있었다'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();

    // The reveal states the increase; Home claims the growth presentation.
    final events = await snapshot(
      tester,
      repo.watchRecentProgress(MemorySeedIds.volume),
    );
    final again = await tester.runAsync(
      () => repo.consumePresentation(
        volumeId: MemorySeedIds.volume,
        kind: PresentationKind.growth,
        sourceId: events.first.id,
      ),
    );
    expect(again, isFalse, reason: 'Home already presented this growth');
  });

  testWidgets('recall answers are stored before generation', (tester) async {
    final repo = await mountV2(tester);
    await _capture(tester);
    await tester.tap(find.text('기억 더 보강하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('어두움'));
    await tester.pump();
    await tester.ensureVisible(find.text('보강 마치기'));
    await tester.tap(find.text('보강 마치기'));
    await tester.pumpAndSettle();
    expect(v2Text('보강한 기억도 함께 사용할게요.'), findsOneWidget);
    final dreams = await snapshot(
      tester,
      repo.watchDreams(DreamStatusFilter.all),
    );
    expect(
      dreams.firstWhere((d) => d.rawText == _dream).recallAnswers['light'],
      '어두움',
    );
  });

  testWidgets('a failed job keeps the dream and offers a retry', (
    tester,
  ) async {
    final repo = await mountV2(tester, engine: MockEngineCase.fail);
    await _capture(tester);
    await tester.tap(find.text('장면 만들기'));
    await pumpUntil(tester, v2Text('장면을 만들지 못했어요'));
    expect(find.text('다시 시도'), findsOneWidget);
    expect(v2Text('꿈은 보관함에 저장되어 있어요.'), findsOneWidget);
    final dreams = await snapshot(
      tester,
      repo.watchDreams(DreamStatusFilter.all),
    );
    expect(
      dreams.firstWhere((d) => d.rawText == _dream).status,
      DreamStatus.failed,
    );
  });

  testWidgets('reader: passage sheet shows the source and editing locks it', (
    tester,
  ) async {
    final repo = await mountV2(
      tester,
      home: const V2ReaderScreen(
        volumeId: MemorySeedIds.volume,
        initialSceneId: MemorySeedIds.readerScene,
      ),
    );
    // Opening the sheet awaits real repository streams (as in V1 tests).
    await tester.runAsync(() async {
      await tester.tap(v2TextContaining('우산을 든 여자가 문 옆에'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(v2Text('꿈에서 온 문장'), findsOneWidget);
    expect(v2Text('9월 13일 기록한 꿈'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('내 문장으로 고치기'));
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '여자는 끝내 고개를 들지 않았다.');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    final passages = await snapshot(
      tester,
      repo.watchPassages(MemorySeedIds.readerScene),
    );
    final edited = passages.firstWhere((p) => p.text == '여자는 끝내 고개를 들지 않았다.');
    expect(edited.origin, PassageOrigin.user);
    expect(edited.locked, isTrue);
  });

  testWidgets('reader saves where reading stopped', (tester) async {
    final repo = await mountV2(
      tester,
      size: const Size(402, 640),
      home: const V2ReaderScreen(
        volumeId: MemorySeedIds.volume,
        initialSceneId: MemorySeedIds.readerScene,
      ),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    final position = await tester.runAsync(
      () => repo.loadReaderPosition(MemorySeedIds.volume),
    );
    expect(position?.sceneId, MemorySeedIds.readerScene);
    expect(position!.offset, greaterThan(0));
  });

  testWidgets('archive deletes a dream through the repository', (tester) async {
    final repo = await mountV2(tester);
    await tester.tap(find.text('보관함'));
    await tester.pumpAndSettle();
    final card = v2TextContaining('작은 열쇠가 손바닥 위에');
    final archiveScroll = find.descendant(
      of: find.ancestor(
        of: find.text('꿈 보관함'),
        matching: find.byType(CustomScrollView),
      ),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(card, 200, scrollable: archiveScroll.first);
    await tester.runAsync(() async {
      await tester.tap(card);
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('꿈 삭제'));
    await tester.tap(find.text('꿈 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('꿈과 장면 모두 삭제'));
    await tester.pumpAndSettle();
    final dreams = await snapshot(
      tester,
      repo.watchDreams(DreamStatusFilter.all),
    );
    expect(dreams.where((d) => d.rawText.contains('작은 열쇠')), isEmpty);
  });

  testWidgets(
    'fresh start: consent gates continue and setup creates a volume',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      await tester.pumpWidget(
        V2PreviewSession(
          config: const PreviewConfig(start: PreviewStart.fresh),
          onExit: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(v2Text('꿈이 자라,\n이야기가 되는 곳.'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('동의하고 계속'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('동의하고 계속'), findsOneWidget, reason: 'still gated');
      await tester.tap(find.text('만 14세 이상입니다.'));
      await tester.tap(find.text('꿈 내용의 AI 처리에 동의합니다.'));
      await tester.pump();
      await tester.tap(find.text('동의하고 계속'));
      await tester.pumpAndSettle();
      expect(v2Text('첫 이야기를\n시작해 볼까요?'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(v2Text('첫 꿈을\n기다리고 있어요'), findsOneWidget);
      expect(find.text('꿈 기록'), findsOneWidget);
    },
  );
}
