// Migrated from test/ui/reader_navigation_test.dart (all 8) and the cancel
// test of test/ui/reader_edit_test.dart (V1). The same reading rules on the
// V2 reader, archive and home: each dream opens its own scene, the saved
// paragraph fraction survives larger type, saves are debounced and flushed
// in the background, deleted anchors fall back to a neighbour, invalid or
// foreign scenes never show unrelated prose, errors retry, and reading
// stays available offline. Invented fixtures only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/design/press.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/archive.dart';
import 'package:mumumong/v2/screens/home.dart';
import 'package:mumumong/v2/screens/reader.dart';

import 'support.dart';

Future<void> _mount(
  WidgetTester tester,
  MumumongRepository repository,
  Widget page, {
  double scale = 1,
  bool offline = false,
}) async {
  setV2View(
    tester,
    size: const Size(390, 844),
    scale: scale,
    reduceMotion: true,
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        networkConnectedProvider.overrideWith((ref) => Stream.value(!offline)),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ],
      child: MumumongV2App(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Text of a passage (or any display text) starting with [prefix], with the
/// keep-all joiners removed.
Finder _startsWith(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .replaceAll('⁠', '')
          .startsWith(prefix),
  description: 'text starting with "$prefix"',
);

/// The whole tappable passage block, the box the reader anchors to.
Finder _passage(String prefix) => find
    .ancestor(of: _startsWith(prefix), matching: find.byType(V2Pressable))
    .first;

/// Every rendered passage of the fixture (`장면N-문단M ...`).
Finder get _passages => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      RegExp(r'^장면\d-문단\d').hasMatch(
        (widget.data ?? widget.textSpan?.toPlainText() ?? '').replaceAll(
          '\u2060',
          '',
        ),
      ),
  description: 'fixture passages',
);

ScrollController _controller(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
    .controller!;

Rect _viewport(WidgetTester tester) =>
    tester.getRect(find.byType(SingleChildScrollView).first);

Future<void> _tapAsync(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadV2Fonts);

  // ---- reader_navigation_test.dart

  testWidgets('each of three archived dreams opens its own scene and body', (
    tester,
  ) async {
    final book = _Book();
    addTearDown(book.dispose);
    await _mount(
      tester,
      book,
      Scaffold(body: V2ArchiveScreen(onCapture: () {})),
    );
    for (var i = 1; i <= 3; i++) {
      await _tapAsync(tester, v2Text('가상 꿈$i').first);
      await _tapAsync(tester, find.bySemanticsLabel('장면$i 읽기'));
      expect(find.byType(V2ReaderScreen), findsOneWidget);
      expect(v2Text('장면$i'), findsWidgets);
      expect(_startsWith('장면$i-문단1'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기').first);
      await tester.pumpAndSettle();
    }
    await _unmount(tester);
  });

  testWidgets(
    'resume uses the saved paragraph fraction after larger type; explicit result starts at top',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      book.bookmark = _position('s2', 's2-p2', fraction: .4);
      await _mount(tester, book, const V2ReaderScreen(), scale: 1.6);
      expect(v2Text('장면2'), findsWidgets);
      expect(_controller(tester).offset, greaterThan(100));
      final rect = tester.getRect(_passage('장면2-문단2'));
      expect(
        (_viewport(tester).top - rect.top) / rect.height,
        closeTo(.4, .01),
      );
      await _unmount(tester);

      await _mount(
        tester,
        book,
        const V2ReaderScreen(
          volumeId: MemorySeedIds.volume,
          initialSceneId: 's1',
        ),
      );
      expect(v2Text('장면1'), findsWidgets);
      expect(_controller(tester).offset, 0);
      await _unmount(tester);
    },
  );

  testWidgets(
    'scroll saves are debounced; background and reopening retain the anchor',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      await _mount(tester, book, const V2ReaderScreen(initialSceneId: 's2'));
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(book.saves, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(book.saves, 1);
      final saved = book.bookmark!;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(book.saves, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _unmount(tester);

      await _mount(tester, book, const V2ReaderScreen());
      expect(book.bookmark?.sceneId, saved.sceneId);
      expect(_controller(tester).offset, closeTo(saved.offset, 1));
      await _unmount(tester);
    },
  );

  testWidgets(
    'deleted paragraph uses its next neighbor; deleted scene uses a nearby scene',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      book.bookmark = _position('s2', 's2-p2', fraction: .5);
      book.passages.removeWhere((p) => p.id == 's2-p2');
      await _mount(tester, book, const V2ReaderScreen());
      expect(
        tester.getRect(_passage('장면2-문단3')).top,
        closeTo(_viewport(tester).top, 1),
      );
      await _unmount(tester);

      book.bookmark = _position('s2', 's2-p2');
      book.scenes.removeWhere((s) => s.id == 's2');
      await _mount(tester, book, const V2ReaderScreen());
      expect(v2Text('장면3'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets('live text-size change keeps the visible paragraph anchored', (
    tester,
  ) async {
    final book = _Book();
    addTearDown(book.dispose);
    await _mount(tester, book, const V2ReaderScreen(initialSceneId: 's2'));
    _controller(tester).jumpTo(900);
    await tester.pump(const Duration(seconds: 1));
    final saved = book.bookmark!;

    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpAndSettle();
    final passage = book.passages.singleWhere((p) => p.id == saved.passageId);
    final rect = tester.getRect(
      _passage(passage.text.substring(0, passage.text.indexOf(' '))),
    );
    expect(
      (_viewport(tester).top - rect.top) / rect.height,
      closeTo(saved.passageFraction, .02),
    );
    await _unmount(tester);
  });

  testWidgets(
    'reader and archive errors retry; empty archive starts a first dream',
    (tester) async {
      final book = _Book()..failPassages = true;
      addTearDown(book.dispose);
      await _mount(tester, book, const V2ReaderScreen());
      expect(v2Text('다시 불러오기'), findsOneWidget);
      book.failPassages = false;
      await tester.tap(v2Text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(_passages, findsNWidgets(5));

      book.failDreams = true;
      await _mount(
        tester,
        book,
        Scaffold(body: V2ArchiveScreen(onCapture: () {})),
      );
      expect(v2Text('다시 불러오기'), findsOneWidget);
      book
        ..failDreams = false
        ..emptyDreams = true;
      await tester.tap(v2Text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(v2Text('첫 꿈 기록하기'), findsOneWidget);

      var captures = 0;
      await _mount(
        tester,
        book,
        Scaffold(body: V2ArchiveScreen(onCapture: () => captures++)),
      );
      await tester.tap(v2Text('첫 꿈 기록하기'));
      expect(captures, 1);
      await _unmount(tester);
    },
  );

  testWidgets(
    'invalid explicit scene or foreign volume never opens unrelated prose',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      for (final page in [
        const V2ReaderScreen(initialSceneId: 'missing'),
        const V2ReaderScreen(volumeId: 'foreign'),
      ]) {
        await _mount(tester, book, page);
        expect(v2TextContaining('이 장면은 원고에서 찾을 수 없어요'), findsOneWidget);
        expect(v2Text('돌아가기'), findsOneWidget);
        expect(_passages, findsNothing);
      }
      await _unmount(tester);
    },
  );

  testWidgets(
    'home retry recovers, empty archive filter offers all dreams, offline reading remains available',
    (tester) async {
      final book = _Book()..failVolume = true;
      addTearDown(book.dispose);
      await _mount(
        tester,
        book,
        Scaffold(body: V2HomeScreen(onCapture: () {})),
      );
      expect(v2Text('다시 불러오기'), findsOneWidget);
      book.failVolume = false;
      await tester.tap(v2Text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(v2Text('원고의 재료'), findsOneWidget);

      await _mount(
        tester,
        book,
        Scaffold(body: V2ArchiveScreen(onCapture: () {})),
      );
      await tester.tap(find.text('기록만').first);
      await tester.pumpAndSettle();
      expect(v2Text('이 조건에 맞는 꿈이 없어요.'), findsOneWidget);
      await tester.tap(v2Text('전체 꿈 보기'));
      await tester.pumpAndSettle();
      expect(v2Text('가상 꿈1'), findsOneWidget);

      await _mount(tester, book, const V2ReaderScreen(), offline: true);
      expect(v2TextContaining('네트워크 연결이 없어요'), findsOneWidget);
      expect(_passages, findsNWidgets(5));
      await _unmount(tester);
    },
  );

  // ---- reader_edit_test.dart (the edit itself is covered by flow_test)

  testWidgets('cancel leaves manuscript untouched and source sheet scrolls', (
    tester,
  ) async {
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await _mount(tester, repository, const V2ReaderScreen());
    final passage = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Passage',
    );
    expect(passage, findsWidgets);

    await _tapAsync(tester, passage.first);
    await _tapAsync(tester, v2Text('내 문장으로 고치기'));
    await tester.enterText(find.byType(TextField), '저장하지 않을 내용');
    await tester.tap(v2Text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('저장하지 않을 내용'), findsNothing);
    expect(_startsWith('저장하지 않을 내용'), findsNothing);

    await _tapAsync(tester, passage.first);
    expect(v2Text('원문'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    final sheetScroll = find.ancestor(
      of: find.byType(SelectableText),
      matching: find.byType(SingleChildScrollView),
    );
    expect(sheetScroll, findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

ReaderPosition _position(String scene, String passage, {double fraction = 0}) =>
    ReaderPosition(
      volumeId: MemorySeedIds.volume,
      sceneId: scene,
      sceneOrderKey: scene.substring(1),
      passageId: passage,
      passageOrderKey: passage.split('p').last,
      passageFraction: fraction,
      offset: 100,
      updatedAt: DateTime.utc(2026, 10, 15),
    );

// Newly invented UI fixtures. No private dreams, network or generated DB writes.
class _Book extends MemoryRepository {
  ReaderPosition? bookmark;
  int saves = 0;
  bool failVolume = false;
  bool failPassages = false;
  bool failDreams = false;
  bool emptyDreams = false;
  final scenes = [
    for (var i = 1; i <= 3; i++)
      Scene(
        id: 's$i',
        volumeId: MemorySeedIds.volume,
        orderKey: '$i',
        chapterNo: i,
        kind: SceneKind.dream,
        placement: PlacementKind.continuation,
        title: '장면$i',
        sourceDreamIds: ['d$i'],
        openImage: null,
      ),
  ];
  final passages = [
    for (var i = 1; i <= 3; i++)
      for (var p = 1; p <= 5; p++)
        Passage(
          id: 's$i-p$p',
          sceneId: 's$i',
          orderKey: '$p',
          text:
              '장면$i-문단$p ${List.filled(45, '유리 계단 옆으로 종이배가 지나갔다.').join(' ')}',
          origin: PassageOrigin.user,
          sourceDreamId: null,
          sourceElementIds: [],
          cReason: null,
          originalText: null,
          locked: true,
          firstReadAt: null,
        ),
  ];

  @override
  Stream<Volume?> watchActiveVolume() => failVolume
      ? Stream.error(StateError('fixture_failure'))
      : super.watchActiveVolume();

  @override
  Stream<List<Scene>> watchScenes(String volumeId) =>
      Stream.value(scenes.where((s) => s.volumeId == volumeId).toList());

  @override
  Stream<List<Passage>> watchPassages(String sceneId) => failPassages
      ? Stream.error(StateError('fixture_failure'))
      : Stream.value(passages.where((p) => p.sceneId == sceneId).toList());

  @override
  Stream<List<Dream>> watchDreams(DreamStatusFilter filter) => failDreams
      ? Stream.error(StateError('fixture_failure'))
      : Stream.value(
          emptyDreams || filter == DreamStatusFilter.archivedOnly
              ? []
              : [
                  for (var i = 1; i <= 3; i++)
                    Dream(
                      id: 'd$i',
                      volumeId: MemorySeedIds.volume,
                      dreamDate: DateTime(2026, 10, i),
                      recordedAt: DateTime.utc(2026, 10, i),
                      inputMode: DreamInputMode.text,
                      rawText: '가상 꿈$i',
                      recallAnswers: {},
                      clarity: DreamClarity.vivid,
                      status: DreamStatus.inManuscript,
                      isBackfill: false,
                    ),
                ],
        );

  @override
  Future<ReaderPosition?> loadReaderPosition(String volumeId) async => bookmark;

  @override
  Future<void> saveReaderPosition(ReaderPosition position) async {
    bookmark = position;
    saves++;
  }
}
