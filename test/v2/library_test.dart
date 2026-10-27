// V2 completion request, completed-book shelf and frozen book. BookStore keeps
// every rule (its own tests cover eligibility and revisions); these tests
// prove the V2 screens draw each state and call it exactly as V1 did.
// Invented fixtures only.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/export/book_store.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/frozen_book.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/library/book_pdf.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/components/buttons.dart';
import 'package:mumumong/v2/design/theme.dart';
import 'package:mumumong/v2/preview/preview_root.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/library.dart';
import 'package:mumumong/v2/screens/v2_providers.dart';
import 'package:share_plus/share_plus.dart';

import 'support.dart';

const _volume = MemorySeedIds.volume;

const _scenes = [
  {
    'id': 'synthetic-scene-1',
    'title': '가상 장면: 종이 별',
    'passages': [
      {'text': '가상 문장: 종이 별이 창문에 붙어 있었다.', 'origin': 'D'},
      {'text': '가상 문장: 나는 별을 떼어 주머니에 넣었다.', 'origin': 'U'},
    ],
  },
  {
    'id': 'synthetic-scene-2',
    'title': '가상 장면: 두 번째 창',
    'passages': [
      {'text': '가상 문장: 다른 창에서도 같은 별이 빛났다.', 'origin': 'C'},
    ],
  },
  {
    'id': 'synthetic-scene-3',
    'title': '',
    'passages': [
      {'text': '가상 문장: 별은 아침이 되자 얇은 종이로 돌아갔다.', 'origin': 'C'},
    ],
  },
];

FrozenBook _book({String title = '가상 별의 책', String? note = '가상 작가의 말'}) =>
    FrozenBook({
      'version': 1,
      'volume_id': _volume,
      'volume_no': 1,
      'request_id': 'synthetic-request',
      'title': title,
      'author_note': note,
      'completed_at': '2026-10-27T03:00:00Z',
      'scenes': _scenes,
      'dreams': const [],
    });

LocalCompletionRequestRow _request(String status) => LocalCompletionRequestRow(
  volumeId: _volume,
  requestId: 'synthetic-request-$status',
  revision: 'synthetic-revision',
  title: '가상 요청 제목',
  authorNote: null,
  previousStatus: 'completable',
  status: status,
);

class _Store extends BookStore {
  _Store(super.database);

  BookCompletionPreview preview = const BookCompletionPreview(
    document: {'scenes': _scenes},
    revision: 'synthetic-revision',
    eligible: true,
    busy: false,
  );
  bool prepareFails = false;
  bool refreshFails = false;
  bool completeFails = false;
  bool retryFails = false;
  bool nextFails = false;
  LocalCompletionRequestRow? request;
  int refreshes = 0;
  int retries = 0;
  int nexts = 0;
  final completed = <(String, String, String?)>[];
  final _books = StreamController<List<FrozenBook>>.broadcast();
  List<FrozenBook> current = const [];

  @override
  Future<void> refresh() async {
    refreshes++;
    if (refreshFails) throw StateError('synthetic_refresh_failure');
  }

  @override
  Stream<List<FrozenBook>> watchBooks() async* {
    yield current;
    yield* _books.stream;
  }

  @override
  Stream<LocalCompletionRequestRow?> watchRequest(String volumeId) =>
      Stream.value(request);

  @override
  Future<BookCompletionPreview> prepare(String volumeId) async {
    if (prepareFails) throw StateError('synthetic_prepare_failure');
    return preview;
  }

  @override
  Future<void> complete(
    String volumeId,
    BookCompletionPreview preview,
    String title,
    String? note,
  ) async {
    completed.add((volumeId, title, note));
    if (completeFails) throw StateError('synthetic_complete_failure');
    current = [_book(title: title.trim(), note: note)];
    _books.add(current);
  }

  @override
  Future<void> retry(String volumeId) async {
    retries++;
    if (retryFails) throw StateError('synthetic_retry_failure');
  }

  @override
  Future<void> next(FrozenBook book) async {
    nexts++;
    if (nextFails) throw StateError('synthetic_next_failure');
  }
}

class _Harness {
  _Harness()
    : database = AppDatabase.forTesting(NativeDatabase.memory()),
      repository = MemoryRepository(seedPrototype: true) {
    store = _Store(database);
  }

  final AppDatabase database;
  final MemoryRepository repository;
  late final _Store store;
  final preferences = MemoryUiPreferenceStore();
  ShareResultStatus shareStatus = ShareResultStatus.success;
  bool shareFails = false;
  int shares = 0;

  List<Override> overrides({bool preview = false}) => [
    repositoryProvider.overrideWithValue(repository),
    uiPreferenceStoreProvider.overrideWithValue(preferences),
    bookStoreProvider.overrideWithValue(store),
    bookPdfShareProvider.overrideWithValue((book, {origin}) async {
      shares++;
      if (shareFails) throw StateError('synthetic_share_failure');
      return shareStatus;
    }),
    if (preview) v2PreviewProvider.overrideWithValue(true),
  ];
}

/// Mounts [page] pushed over a plain first route, so pops are observable.
Future<_Harness> _mount(
  WidgetTester tester,
  Widget page, {
  bool preview = false,
  double scale = 1,
  void Function(_Harness harness)? setUp,
}) async {
  setV2View(tester, scale: scale, reduceMotion: true);
  final harness = _Harness();
  setUp?.call(harness);
  addTearDown(harness.repository.dispose);
  addTearDown(harness.database.close);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: harness.overrides(preview: preview),
      child: MumumongV2App(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(v2Route(page)),
                child: const Text('첫 화면'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('첫 화면'));
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // Pages are lazy lists: bring the target into the built range first.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

const _completion = V2CompletionScreen(volumeId: _volume);

/// The button with [label], not a page title that shares its words.
Finder _button(String label) =>
    find.descendant(of: find.byType(V2Button), matching: v2Text(label));

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('the shelf lists completed books and opens one', (tester) async {
    final harness = await _mount(
      tester,
      const V2LibraryScreen(),
      setUp: (h) => h.store.current = [_book()],
    );
    expect(harness.store.refreshes, 1);
    expect(v2Text('가상 별의 책'), findsOneWidget);
    expect(v2TextContaining('VOL.01 · 완성본 v1'), findsOneWidget);
    await _tap(tester, v2Text('가상 별의 책'));
    expect(find.byType(V2CompletedBookScreen), findsOneWidget);
  });

  testWidgets('a failed server check keeps the books on this device', (
    tester,
  ) async {
    await _mount(
      tester,
      const V2LibraryScreen(),
      setUp: (h) => h
        ..store.refreshFails = true
        ..store.current = [_book()],
    );
    expect(v2TextContaining('서버의 책을 확인하지 못했어요'), findsOneWidget);
    expect(v2Text('가상 별의 책'), findsOneWidget);
  });

  testWidgets('an empty shelf leads to the completion request', (tester) async {
    await _mount(tester, const V2LibraryScreen());
    expect(v2TextContaining('아직 완성한 책이 없어요'), findsOneWidget);
    await _tap(tester, v2Text('원고 완성 준비'));
    expect(find.byType(V2CompletionScreen), findsOneWidget);
  });

  for (final busy in [false, true]) {
    testWidgets('a manuscript that is not ready explains why (busy=$busy)', (
      tester,
    ) async {
      await _mount(
        tester,
        _completion,
        setUp: (h) => h.store.preview = BookCompletionPreview(
          document: const {'scenes': _scenes},
          revision: 'synthetic-revision',
          eligible: busy,
          busy: busy,
        ),
      );
      expect(
        v2Text(busy ? '진행 중인 장면이 있어요.' : '조금 더 원고를 쌓아 주세요.'),
        findsOneWidget,
      );
      expect(v2TextContaining('재료 70% 이상'), findsOneWidget);
      expect(find.byKey(const Key('v2-book-title')), findsNothing);
      await _tap(tester, v2Text('계속 쌓기'));
      expect(find.byType(V2CompletionScreen), findsNothing);
      expect(find.text('첫 화면'), findsOneWidget);
    });
  }

  testWidgets('completion asks for a title, reviews, then freezes once', (
    tester,
  ) async {
    final harness = await _mount(tester, _completion);
    await _tap(tester, v2Text('내용 확인'));
    expect(v2Text('책 제목을 적어 주세요.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('v2-book-title')), ' 가상 별의 책 ');
    await tester.enterText(find.byKey(const Key('v2-book-note')), '가상 작가의 말');
    await _tap(tester, v2Text('내용 확인'));
    expect(v2Text('이 원고를 한 권으로 보관할까요?'), findsOneWidget);
    expect(v2Text('3개 장면 · 기록 순서 그대로 · 완성본 v1'), findsOneWidget);
    expect(v2Text('가상 작가의 말'), findsOneWidget);

    await _tap(tester, v2Text('제목과 작가의 말 수정'));
    expect(find.text(' 가상 별의 책 '), findsOneWidget);
    await _tap(tester, v2Text('내용 확인'));
    await _tap(tester, _button('원고 완성하기'));

    expect(harness.store.completed, [(_volume, ' 가상 별의 책 ', '가상 작가의 말')]);
    expect(find.byType(V2CompletedBookScreen), findsOneWidget);
    expect(v2TextContaining('완전히 선명하지는 않아요'), findsOneWidget);
  });

  testWidgets('a failed completion keeps the title and the note', (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      _completion,
      setUp: (h) => h.store.completeFails = true,
    );
    await tester.enterText(find.byKey(const Key('v2-book-title')), '가상 제목');
    await _tap(tester, v2Text('내용 확인'));
    await _tap(tester, _button('원고 완성하기'));
    expect(harness.store.completed, hasLength(1));
    expect(v2TextContaining('제목과 작가의 말은 유지했어요'), findsOneWidget);
    expect(find.byType(V2CompletedBookScreen), findsNothing);
    await _tap(tester, v2Text('제목과 작가의 말 수정'));
    expect(find.text('가상 제목'), findsOneWidget);
  });

  testWidgets('a pending request waits and retries the same request', (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      _completion,
      setUp: (h) => h.store.request = _request('pending'),
    );
    expect(v2Text('완성본 저장을 기다리고 있어요.'), findsOneWidget);
    final before = harness.store.refreshes;
    await _tap(tester, v2Text('저장 다시 확인'));
    expect(harness.store.retries, 1);
    expect(harness.store.refreshes, before + 1);

    harness.store.retryFails = true;
    await _tap(tester, v2Text('저장 다시 확인'));
    expect(v2TextContaining('요청은 보관하고 있어요'), findsOneWidget);
    expect(harness.store.completed, isEmpty);
  });

  testWidgets('a conflicted request keeps its title and asks for a new one', (
    tester,
  ) async {
    await _mount(
      tester,
      _completion,
      setUp: (h) => h.store.request = _request('conflict'),
    );
    expect(v2TextContaining('새 요청으로 확정해 주세요'), findsOneWidget);
    expect(find.text('가상 요청 제목'), findsOneWidget);
  });

  testWidgets('a failed check offers a retry and never shows a form', (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      _completion,
      setUp: (h) => h.store.prepareFails = true,
    );
    expect(v2TextContaining('동기화할 변경이 있거나'), findsOneWidget);
    expect(find.byKey(const Key('v2-book-title')), findsNothing);
    harness.store.prepareFails = false;
    await _tap(tester, v2Text('다시 확인'));
    expect(find.byKey(const Key('v2-book-title')), findsOneWidget);
  });

  testWidgets('an existing book replaces the request screen', (tester) async {
    await _mount(
      tester,
      _completion,
      setUp: (h) => h.store.current = [_book()],
    );
    expect(find.byType(V2CompletedBookScreen), findsOneWidget);
    expect(find.byKey(const Key('v2-book-title')), findsNothing);
  });

  testWidgets('the book shares its PDF and reports the outcome', (
    tester,
  ) async {
    final harness = await _mount(tester, V2CompletedBookScreen(book: _book()));
    harness.shareStatus = ShareResultStatus.dismissed;
    await _tap(tester, v2Text('PDF 저장·공유'));
    expect(harness.shares, 1);
    expect(
      find.text(bookPdfShareMessage(ShareResultStatus.dismissed)),
      findsOneWidget,
    );

    harness.shareFails = true;
    await _tap(tester, v2Text('PDF 저장·공유'));
    expect(find.text(bookPdfFailedMessage), findsOneWidget);
  });

  testWidgets('the next volume returns to the first route once', (
    tester,
  ) async {
    final harness = await _mount(tester, V2CompletedBookScreen(book: _book()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(V2CompletedBookScreen)),
    );
    final before = container.read(libraryReturnHomeProvider);
    await _tap(tester, v2Text('다음 권 시작'));
    expect(harness.store.nexts, 1);
    expect(container.read(libraryReturnHomeProvider), before + 1);
    expect(find.byType(V2CompletedBookScreen), findsNothing);
    expect(find.text('첫 화면'), findsOneWidget);
  });

  testWidgets('a failed next volume stays on the book', (tester) async {
    await _mount(
      tester,
      V2CompletedBookScreen(book: _book()),
      setUp: (h) => h.store.nextFails = true,
    );
    await _tap(tester, v2Text('다음 권 시작'));
    expect(find.byType(V2CompletedBookScreen), findsOneWidget);
    expect(v2TextContaining('다음 권을 열지 못했어요'), findsOneWidget);
  });

  testWidgets('the preview never starts a next volume', (tester) async {
    final harness = await _mount(
      tester,
      V2CompletedBookScreen(book: _book()),
      preview: true,
    );
    await _tap(tester, v2Text('다음 권 시작'));
    expect(harness.store.nexts, 0);
    expect(v2Text('미리보기에서는 다음 권을 열지 않아요.'), findsOneWidget);
  });

  testWidgets('the book reads in order with origins when they are on', (
    tester,
  ) async {
    await _mount(
      tester,
      V2CompletedBookScreen(book: _book()),
      setUp: (h) => h.preferences.value =
          '{"theme":"light","reader_scale":1.0,"show_origins":true}',
    );
    final list = find.byType(Scrollable).last;
    for (final text in [
      '가상 장면: 종이 별',
      '꿈에서 온 문장',
      '내가 쓴 문장',
      '장면을 잇는 문장',
      '장면 3',
      '작가의 말',
      '가상 작가의 말',
    ]) {
      for (var i = 0; i < 40 && v2Text(text).evaluate().isEmpty; i++) {
        await tester.drag(list, const Offset(0, -120));
        await tester.pump();
      }
      expect(v2Text(text), findsWidgets, reason: text);
    }
  });

  testWidgets('a finished home opens the V2 book', (tester) async {
    setV2View(tester, reduceMotion: true);
    final harness = _Harness()..store.current = [_book()];
    addTearDown(harness.repository.dispose);
    addTearDown(harness.database.close);
    final seeded = await tester.runAsync(
      () => harness.repository.watchActiveVolume().first,
    );
    final finished = seeded!.copyWith(
      status: VolumeStatus.completed,
      title: '가상 별의 책',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...previewOverrides(
            const PreviewConfig(start: PreviewStart.continued),
            harness.repository,
            books: (_) => harness.store,
          ),
          activeVolumeProvider.overrideWith((ref) => Stream.value(finished)),
        ],
        child: const MumumongV2App(home: V2Shell()),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, v2Text('완성본 열기'));
    expect(find.byType(V2CompletionScreen), findsOneWidget);
    expect(find.byType(V2CompletedBookScreen), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('completion and book pages meet the guidelines x$scale', (
      tester,
    ) async {
      await _mount(
        tester,
        const V2LibraryScreen(),
        scale: scale,
        setUp: (h) => h.store.current = [_book()],
      );
      await expectGuidelines(tester, 'shelf x$scale');
      await _tap(tester, v2Text('가상 별의 책'));
      await expectGuidelines(tester, 'book x$scale');

      await _mount(tester, _completion, scale: scale);
      await expectGuidelines(tester, 'completion form x$scale');
      await tester.enterText(find.byKey(const Key('v2-book-title')), '가상 제목');
      await _tap(tester, v2Text('내용 확인'));
      await expectGuidelines(tester, 'completion review x$scale');
    });
  }
}
