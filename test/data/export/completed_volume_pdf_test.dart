import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/export/completed_volume_pdf.dart';
import 'package:mumumong/domain/model/enums.dart';

void main() {
  late CompletedVolumePdfComposer composer;

  setUpAll(() async {
    composer = CompletedVolumePdfComposer(
      maruRegular: await File(
        'assets/fonts/MaruBuri-Regular.ttf',
      ).readAsBytes(),
      maruBold: await File('assets/fonts/MaruBuri-Bold.ttf').readAsBytes(),
    );
  });

  CompletedVolumeSnapshot book({
    VolumeStatus status = VolumeStatus.completed,
    String? authorNote,
  }) => CompletedVolumeSnapshot(
    volumeNo: 1,
    status: status,
    title: '낯선 종이의 밤',
    completedAt: DateTime(2026, 9, 30),
    authorNote: authorNote,
    chapters: [
      BookChapter(
        number: 1,
        title: '푸른 복도',
        paragraphs: const [
          BookParagraph(
            text: '나는 복도 끝에서 오래된 문을 보았다.',
            origin: PassageOrigin.dream,
          ),
          BookParagraph(
            text: '문틈에 종이 한 장이 끼어 있었다.',
            origin: PassageOrigin.connection,
          ),
          BookParagraph(
            text: '나는 그 종이를 열지 않기로 했다.',
            origin: PassageOrigin.user,
          ),
        ],
      ),
    ],
    dreams: [
      BookDreamReference(
        date: DateTime(2026, 9, 12),
        firstLine: '복도에 푸른 종이가 놓여 있었다.',
      ),
    ],
  );

  test(
    'completed snapshot produces a nonempty PDF with bundled Korean fonts',
    () async {
      final bytes = await composer.compose(
        book(authorNote: '이 장면을 오래 기억하고 싶었다.'),
      );
      expect(bytes.length, greaterThan(2000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final qaPath = Platform.environment['MUMUMONG_PDF_QA_PATH'];
      if (qaPath != null) {
        await File(qaPath).writeAsBytes(bytes);
      }
    },
  );

  test('a non-completed volume is rejected before export', () async {
    await expectLater(
      composer.compose(book(status: VolumeStatus.completable)),
      throwsStateError,
    );
  });

  test('copyright shares come from compiled passages by character count', () {
    final shares = book().sourcePercentages;
    expect(shares.dream, greaterThan(0));
    expect(shares.user, greaterThan(0));
    expect(shares.dream + shares.user, lessThanOrEqualTo(100));
  });

  test('appendix reference cannot contain a full multiline dream', () {
    expect(
      () => BookDreamReference(date: DateTime(2026), firstLine: '첫 줄\n둘째 줄'),
      throwsArgumentError,
    );
    expect(
      () => BookDreamReference(date: DateTime(2026), firstLine: '가' * 121),
      throwsArgumentError,
    );
  });

  test('snapshot lists cannot be mutated after assembly', () {
    final snapshot = book();
    expect(
      () => snapshot.chapters.add(
        BookChapter(number: 2, title: '다음', paragraphs: const []),
      ),
      throwsUnsupportedError,
    );
    expect(() => snapshot.dreams.clear(), throwsUnsupportedError);
  });

  test('a long paragraph can continue across pages', () async {
    final longBook = CompletedVolumeSnapshot(
      volumeNo: 1,
      status: VolumeStatus.completed,
      title: '반복되는 문',
      completedAt: DateTime(2026, 9, 30),
      chapters: [
        BookChapter(
          number: 1,
          title: '한 문장',
          paragraphs: [
            BookParagraph(
              text: List.filled(250, '문 뒤에 작은 빛이 있었다.').join(' '),
              origin: PassageOrigin.user,
            ),
          ],
        ),
      ],
      dreams: const [],
    );
    final bytes = await composer.compose(longBook);
    expect(bytes.length, greaterThan(2000));
  });
}
