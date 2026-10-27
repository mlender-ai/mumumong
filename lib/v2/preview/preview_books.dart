// Preview-only book stores. Nothing here reaches a server or the device DB.
//
// PreviewBookStore backs preview sessions: no completed books, no requests,
// and the manuscript is never eligible, so the completion screen tells the
// truth about a 42% invented manuscript.
//
// DemoBookStore backs the design lab only: an eligible invented manuscript
// whose completion lands in memory, so the completion review and the
// completed-book reveal can be seen. It is labelled as a design mock there.
import 'dart:async';

import '../../data/export/book_store.dart';
import '../../data/local/database.dart';
import '../../domain/model/frozen_book.dart';

class PreviewBookStore extends BookStore {
  PreviewBookStore(super.database);

  @override
  Future<void> refresh() async {}

  @override
  Stream<List<FrozenBook>> watchBooks() => Stream.value(const []);

  @override
  Stream<LocalCompletionRequestRow?> watchRequest(String volumeId) =>
      Stream.value(null);

  @override
  Future<BookCompletionPreview> prepare(String volumeId) async =>
      const BookCompletionPreview(
        document: {'scenes': []},
        revision: 'preview',
        eligible: false,
        busy: false,
      );

  @override
  Future<void> complete(
    String volumeId,
    BookCompletionPreview preview,
    String title,
    String? note,
  ) => Future.error(UnsupportedError('preview_does_not_complete'));

  @override
  Future<void> retry(String volumeId) =>
      Future.error(UnsupportedError('preview_does_not_complete'));

  @override
  Future<void> next(FrozenBook book) =>
      Future.error(UnsupportedError('preview_does_not_start_volumes'));
}

/// Invented scenes for the lab's completion demo. Not a real dream.
const _demoScenes = [
  {
    'id': 'demo-scene-1',
    'title': '계절 버튼이 있는 엘리베이터',
    'passages': [
      {'text': '엘리베이터에는 층 대신 계절이 적혀 있었다.', 'origin': 'D'},
      {'text': '나는 망설이다가 아직 오지 않은 겨울을 눌렀다.', 'origin': 'C'},
    ],
  },
  {
    'id': 'demo-scene-2',
    'title': '물이 고인 복도',
    'passages': [
      {'text': '문이 열리자 복도 바닥에 얕은 하늘이 고여 있었다.', 'origin': 'D'},
      {'text': '발을 디딜 때마다 구름이 조금씩 자리를 옮겼다.', 'origin': 'U'},
    ],
  },
  {
    'id': 'demo-scene-3',
    'title': '두 번째 문',
    'passages': [
      {'text': '복도 끝의 문은 처음 탔던 엘리베이터와 같은 소리를 냈다.', 'origin': 'C'},
    ],
  },
];

class DemoBookStore extends BookStore {
  DemoBookStore(super.database, {required this.volumeId, this.coverMotifId});

  final String volumeId;

  /// The volume's motif, as BookStore.prepare copies it into the document.
  final String? Function()? coverMotifId;
  final _books = StreamController<List<FrozenBook>>.broadcast();
  List<FrozenBook> _current = const [];

  @override
  Future<void> refresh() async {}

  @override
  Stream<List<FrozenBook>> watchBooks() async* {
    yield _current;
    yield* _books.stream;
  }

  @override
  Stream<LocalCompletionRequestRow?> watchRequest(String volumeId) =>
      Stream.value(null);

  @override
  Future<BookCompletionPreview> prepare(String volumeId) async =>
      BookCompletionPreview(
        document: {
          'volume_id': volumeId,
          'cover_motif_id': coverMotifId?.call(),
          'scenes': _demoScenes,
        },
        revision: 'demo',
        eligible: true,
        busy: false,
      );

  @override
  Future<void> complete(
    String volumeId,
    BookCompletionPreview preview,
    String title,
    String? note,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _current = [
      FrozenBook({
        'version': 1,
        'volume_id': volumeId,
        'volume_no': 1,
        'request_id': 'demo-request',
        'title': title.trim(),
        'author_note': note,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'cover_motif_id': preview.document['cover_motif_id'],
        'scenes': _demoScenes,
        'dreams': const [],
      }),
    ];
    _books.add(_current);
  }

  @override
  Future<void> retry(String volumeId) =>
      Future.error(UnsupportedError('demo_has_no_requests'));

  @override
  Future<void> next(FrozenBook book) =>
      Future.error(UnsupportedError('demo_does_not_start_volumes'));

  void dispose() => _books.close();
}
