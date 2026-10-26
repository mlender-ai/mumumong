import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/archive/archive_screen.dart';
import 'package:mumumong/ui/home/home_screen.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    _Book repository,
    Widget page, {
    double scale = 1,
    bool offline = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          networkConnectedProvider.overrideWith(
            (ref) => Stream.value(!offline),
          ),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each of three archived dreams opens its own scene and body', (
    tester,
  ) async {
    final book = _Book();
    addTearDown(book.dispose);
    await mount(tester, book, Scaffold(body: ArchiveScreen(onCapture: () {})));
    for (var i = 1; i <= 3; i++) {
      await tester.ensureVisible(find.text('가상 꿈$i'));
      await tester.runAsync(() async {
        await tester.tap(find.text('가상 꿈$i'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(MongListRow, '장면$i'));
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(MongListRow, '장면$i'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      expect(find.text('장면$i'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is ReaderPassage && w.text.startsWith('장면$i-문단1'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'resume uses the saved paragraph fraction after larger type; explicit result starts at top',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      book.bookmark = _position('s2', 's2-p2', fraction: .4);
      await mount(tester, book, const ReaderScreen(), scale: 1.6);
      expect(find.text('장면2'), findsOneWidget);
      final scroll = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      expect(scroll.offset, greaterThan(100));
      final paragraph = find.byWidgetPredicate(
        (w) => w is ReaderPassage && w.text.startsWith('장면2-문단2'),
      );
      final rect = tester.getRect(paragraph);
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect((viewport.top - rect.top) / rect.height, closeTo(.4, .01));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await mount(
        tester,
        book,
        const ReaderScreen(
          volumeId: MemorySeedIds.volume,
          initialSceneId: 's1',
        ),
      );
      expect(find.text('장면1'), findsOneWidget);
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!
            .offset,
        0,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'scroll saves are debounced; background and reopening retain the anchor',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      await mount(tester, book, const ReaderScreen(initialSceneId: 's2'));
      await tester.drag(
        find.byType(SingleChildScrollView),
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await mount(tester, book, const ReaderScreen());
      expect(book.bookmark?.sceneId, saved.sceneId);
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!
            .offset,
        closeTo(saved.offset, 1),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'deleted paragraph uses its next neighbor; deleted scene uses a nearby scene',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      book.bookmark = _position('s2', 's2-p2', fraction: .5);
      book.passages.removeWhere((p) => p.id == 's2-p2');
      await mount(tester, book, const ReaderScreen());
      final rect = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is ReaderPassage && w.text.startsWith('장면2-문단3'),
        ),
      );
      expect(
        rect.top,
        closeTo(tester.getRect(find.byType(SingleChildScrollView)).top, 1),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      book.bookmark = _position('s2', 's2-p2');
      book.scenes.removeWhere((s) => s.id == 's2');
      await mount(tester, book, const ReaderScreen());
      expect(find.text('장면3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('live text-size change keeps the visible paragraph anchored', (
    tester,
  ) async {
    final book = _Book();
    final scale = ValueNotifier<double>(1);
    addTearDown(book.dispose);
    addTearDown(scale.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(book)],
        child: MaterialApp(
          theme: mumumongTheme(),
          builder: (context, child) => ValueListenableBuilder<double>(
            valueListenable: scale,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(value)),
              child: child!,
            ),
          ),
          home: const ReaderScreen(initialSceneId: 's2'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    controller.jumpTo(900);
    await tester.pump(const Duration(seconds: 1));
    final saved = book.bookmark!;
    scale.value = 1.6;
    await tester.pumpAndSettle();
    final passage = book.passages.singleWhere((p) => p.id == saved.passageId);
    final rect = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is ReaderPassage && w.text == passage.text,
      ),
    );
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    expect(
      (viewport.top - rect.top) / rect.height,
      closeTo(saved.passageFraction, .02),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'reader and archive errors retry; empty archive starts a first dream',
    (tester) async {
      final book = _Book()..failPassages = true;
      addTearDown(book.dispose);
      await mount(tester, book, const ReaderScreen());
      expect(find.text('다시 불러오기'), findsOneWidget);
      book.failPassages = false;
      await tester.tap(find.text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderPassage), findsNWidgets(5));
      book.failDreams = true;
      await mount(
        tester,
        book,
        Scaffold(body: ArchiveScreen(onCapture: () {})),
      );
      expect(find.text('다시 불러오기'), findsOneWidget);
      book.failDreams = false;
      book.emptyDreams = true;
      await tester.tap(find.text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(find.text('첫 꿈 기록하기'), findsOneWidget);
      var captures = 0;
      await mount(
        tester,
        book,
        Scaffold(body: ArchiveScreen(onCapture: () => captures++)),
      );
      await tester.tap(find.text('첫 꿈 기록하기'));
      expect(captures, 1);
    },
  );

  testWidgets(
    'invalid explicit scene or foreign volume never opens unrelated prose',
    (tester) async {
      final book = _Book();
      addTearDown(book.dispose);
      for (final page in [
        const ReaderScreen(initialSceneId: 'missing'),
        const ReaderScreen(volumeId: 'foreign'),
      ]) {
        await mount(tester, book, page);
        expect(find.textContaining('이 장면은 원고에서 찾을 수 없어요'), findsOneWidget);
        expect(find.text('돌아가기'), findsOneWidget);
        expect(find.byType(ReaderPassage), findsNothing);
      }
    },
  );

  testWidgets(
    'home retry recovers, empty archive filter offers all dreams, offline reading remains available',
    (tester) async {
      final book = _Book()..failVolume = true;
      addTearDown(book.dispose);
      await mount(tester, book, HomeScreen(onCapture: () {}));
      expect(find.text('다시 불러오기'), findsOneWidget);
      book.failVolume = false;
      await tester.tap(find.text('다시 불러오기'));
      await tester.pumpAndSettle();
      expect(find.text('꿈 기록하기'), findsOneWidget);
      await mount(
        tester,
        book,
        Scaffold(body: ArchiveScreen(onCapture: () {})),
      );
      await tester.tap(find.text('기록만').first);
      await tester.pumpAndSettle();
      expect(find.text('이 조건에 맞는 꿈이 없어요.'), findsOneWidget);
      await tester.tap(find.text('전체 꿈 보기'));
      await tester.pumpAndSettle();
      expect(find.text('가상 꿈1'), findsOneWidget);
      await mount(tester, book, const ReaderScreen(), offline: true);
      expect(find.textContaining('네트워크 연결이 없어요'), findsOneWidget);
      expect(find.byType(ReaderPassage), findsNWidgets(5));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
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
