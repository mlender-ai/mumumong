import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/model/enums.dart';

/// Already-compiled text only. The source dream body is deliberately absent.
class CompletedVolumeSnapshot {
  CompletedVolumeSnapshot({
    required this.volumeNo,
    required this.status,
    required this.title,
    required this.completedAt,
    required List<BookChapter> chapters,
    required List<BookDreamReference> dreams,
    this.authorNote,
  }) : chapters = List.unmodifiable(chapters),
       dreams = List.unmodifiable(dreams);

  final int volumeNo;
  final VolumeStatus status;
  final String title;
  final DateTime completedAt;
  final List<BookChapter> chapters;
  final List<BookDreamReference> dreams;
  final String? authorNote;

  /// Character-count shares of the immutable passage snapshot, not dreams.
  ({int dream, int user}) get sourcePercentages {
    var total = 0;
    var dream = 0;
    var user = 0;
    for (final chapter in chapters) {
      for (final paragraph in chapter.paragraphs) {
        final count = paragraph.text.runes.where((rune) => rune > 32).length;
        total += count;
        if (paragraph.origin == PassageOrigin.dream) dream += count;
        if (paragraph.origin == PassageOrigin.user) user += count;
      }
    }
    if (total == 0) return (dream: 0, user: 0);
    return (
      dream: (100 * dream / total).round(),
      user: (100 * user / total).round(),
    );
  }
}

class BookChapter {
  BookChapter({
    required this.number,
    required this.title,
    required List<BookParagraph> paragraphs,
  }) : paragraphs = List.unmodifiable(paragraphs);

  final int number;
  final String title;
  final List<BookParagraph> paragraphs;
}

class BookParagraph {
  const BookParagraph({required this.text, required this.origin});

  final String text;
  final PassageOrigin origin;
}

/// Caller must provide only a short first line; no full original dream input.
class BookDreamReference {
  BookDreamReference({required this.date, required this.firstLine}) {
    if (firstLine.trim().isEmpty ||
        firstLine.contains(RegExp(r'[\r\n]')) ||
        firstLine.runes.length > 120) {
      throw ArgumentError('A dream reference must be one short first line');
    }
  }

  final DateTime date;
  final String firstLine;
}

/// Pure PDF composition. Callers load bundled fonts and provide a consistent
/// completed-volume snapshot; this class never reads a database or raw dream.
class CompletedVolumePdfComposer {
  CompletedVolumePdfComposer({
    required Uint8List maruRegular,
    required Uint8List maruBold,
  }) : _maruRegular = pw.Font.ttf(ByteData.sublistView(maruRegular)),
       _maruBold = pw.Font.ttf(ByteData.sublistView(maruBold));

  static const pageWidthMm = 128.0;
  static const pageHeightMm = 188.0;
  static const coverClarity = 0.875; // 56 of 64 dots: below the 0.9 ceiling.

  static final pageFormat = PdfPageFormat(
    pageWidthMm * PdfPageFormat.mm,
    pageHeightMm * PdfPageFormat.mm,
  );

  final pw.Font _maruRegular;
  final pw.Font _maruBold;

  static const _ink = PdfColor.fromInt(0xFF211F1D);
  static const _muted = PdfColor.fromInt(0xFF706E6A);

  Future<Uint8List> compose(CompletedVolumeSnapshot book) async {
    _validate(book);
    final pdf = pw.Document(
      title: book.title,
      creator: 'MUMUMONG',
      subject: 'Completed manuscript',
    );
    _addCover(pdf, book);
    _addCopyright(pdf, book);
    _addContents(pdf, book);
    for (final chapter in book.chapters) {
      _addRightHandBlankIfNeeded(pdf);
      _addChapter(pdf, chapter);
    }
    if (book.authorNote?.trim().isNotEmpty ?? false) {
      _addRightHandBlankIfNeeded(pdf);
      _addEndMatter(pdf, '작가의 말', [book.authorNote!.trim()]);
    }
    _addRightHandBlankIfNeeded(pdf);
    _addDreamAppendix(pdf, book.dreams);
    return pdf.save();
  }

  void _validate(CompletedVolumeSnapshot book) {
    if (book.status != VolumeStatus.completed) {
      throw StateError('Only a completed volume can be exported as a book');
    }
    if (book.volumeNo < 1 ||
        book.title.trim().isEmpty ||
        book.chapters.isEmpty) {
      throw ArgumentError(
        'A completed book needs a number, title, and chapter',
      );
    }
    for (final chapter in book.chapters) {
      if (chapter.number < 1 ||
          chapter.title.trim().isEmpty ||
          chapter.paragraphs.isEmpty ||
          chapter.paragraphs.any(
            (paragraph) => paragraph.text.trim().isEmpty,
          )) {
        throw ArgumentError('Each chapter needs a number, title, and text');
      }
    }
  }

  pw.TextStyle get _bodyStyle => pw.TextStyle(
    font: _maruRegular,
    fontSize: 10,
    lineSpacing: 7.5,
    color: _ink,
  );

  // Bundled Pretendard is CFF OTF; dart_pdf cannot embed its Korean glyphs.
  // MaruBuri TTF keeps PDF metadata legible until a licensed TTF is bundled.
  pw.TextStyle get _metaStyle =>
      pw.TextStyle(font: _maruRegular, fontSize: 8, color: _muted);

  String _date(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

  void _addCover(pw.Document pdf, CompletedVolumeSnapshot book) {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(18 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MUMUMONG', style: _metaStyle),
            pw.Spacer(),
            _completedDotField(),
            pw.SizedBox(height: 20 * PdfPageFormat.mm),
            pw.Text(
              book.title.trim(),
              style: pw.TextStyle(
                font: _maruBold,
                fontSize: 24,
                height: 1.2,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 5 * PdfPageFormat.mm),
            pw.Text(
              'VOL.${book.volumeNo.toString().padLeft(2, '0')}',
              style: _metaStyle,
            ),
            pw.Spacer(),
            pw.Text('꿈에서 온 이야기', style: _metaStyle),
          ],
        ),
      ),
    );
  }

  pw.Widget _completedDotField() {
    const missing = {3, 10, 19, 28, 36, 45, 54, 61};
    return pw.SizedBox(
      width: 50 * PdfPageFormat.mm,
      child: pw.Wrap(
        spacing: 3 * PdfPageFormat.mm,
        runSpacing: 3 * PdfPageFormat.mm,
        children: [
          for (var i = 0; i < 64; i++)
            pw.Container(
              width: 3 * PdfPageFormat.mm,
              height: 3 * PdfPageFormat.mm,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: missing.contains(i) ? PdfColors.white : _ink,
              ),
            ),
        ],
      ),
    );
  }

  void _addCopyright(pw.Document pdf, CompletedVolumeSnapshot book) {
    final shares = book.sourcePercentages;
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(18 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              book.title.trim(),
              style: pw.TextStyle(font: _maruBold, fontSize: 12, color: _ink),
            ),
            pw.SizedBox(height: 5 * PdfPageFormat.mm),
            pw.Text(
              'VOL.${book.volumeNo.toString().padLeft(2, '0')}  ·  ${_date(book.completedAt)}',
              style: _metaStyle,
            ),
            pw.SizedBox(height: 8 * PdfPageFormat.mm),
            pw.Text(
              '이 책의 문장 중 ${shares.dream}%는 당신의 꿈에서, ${shares.user}%는 당신의 손에서 왔습니다.',
              style: _metaStyle,
            ),
            pw.SizedBox(height: 7 * PdfPageFormat.mm),
            pw.Text('MUMUMONG', style: _metaStyle),
          ],
        ),
      ),
    );
  }

  void _addContents(pw.Document pdf, CompletedVolumeSnapshot book) {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(18 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionTitle('차례'),
            pw.SizedBox(height: 12 * PdfPageFormat.mm),
            for (final chapter in book.chapters)
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 5 * PdfPageFormat.mm),
                child: pw.Text(
                  '${chapter.number}. ${chapter.title}',
                  style: _bodyStyle,
                ),
              ),
            if (book.authorNote?.trim().isNotEmpty ?? false)
              pw.Text('작가의 말', style: _bodyStyle),
            pw.SizedBox(height: 5 * PdfPageFormat.mm),
            pw.Text('이 책의 꿈들', style: _bodyStyle),
          ],
        ),
      ),
    );
  }

  void _addRightHandBlankIfNeeded(pw.Document pdf) {
    // PDF page 1 is the right-hand cover; right-hand chapter pages are odd.
    if (pdf.document.pdfPageList.pages.length.isOdd) {
      pdf.addPage(pw.Page(pageFormat: pageFormat, build: (_) => pw.SizedBox()));
    }
  }

  void _addChapter(pw.Document pdf, BookChapter chapter) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.fromLTRB(
          17 * PdfPageFormat.mm,
          16 * PdfPageFormat.mm,
          15 * PdfPageFormat.mm,
          17 * PdfPageFormat.mm,
        ),
        maxPages: 200,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('${context.pageNumber}', style: _metaStyle),
        ),
        build: (_) => [
          pw.SizedBox(height: 42 * PdfPageFormat.mm),
          pw.Text('제${chapter.number}장', style: _metaStyle),
          pw.SizedBox(height: 4 * PdfPageFormat.mm),
          _sectionTitle(chapter.title),
          pw.SizedBox(height: 13 * PdfPageFormat.mm),
          for (final paragraph in chapter.paragraphs) ...[
            _paragraph(paragraph.text),
            pw.SizedBox(height: 7.5),
          ],
        ],
      ),
    );
  }

  pw.Widget _paragraph(String text) => pw.RichText(
    textAlign: pw.TextAlign.justify,
    overflow: pw.TextOverflow.span,
    text: pw.TextSpan(
      style: _bodyStyle,
      children: [
        pw.WidgetSpan(child: pw.SizedBox(width: 10)),
        pw.TextSpan(text: text.trim()),
      ],
    ),
  );

  pw.Widget _sectionTitle(String title) => pw.Text(
    title,
    style: pw.TextStyle(
      font: _maruBold,
      fontSize: 18,
      height: 1.3,
      color: _ink,
    ),
  );

  void _addEndMatter(pw.Document pdf, String title, List<String> paragraphs) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(18 * PdfPageFormat.mm),
        maxPages: 100,
        build: (_) => [
          pw.SizedBox(height: 42 * PdfPageFormat.mm),
          _sectionTitle(title),
          pw.SizedBox(height: 12 * PdfPageFormat.mm),
          for (final paragraph in paragraphs) ...[
            _paragraph(paragraph),
            pw.SizedBox(height: 7.5),
          ],
        ],
      ),
    );
  }

  void _addDreamAppendix(pw.Document pdf, List<BookDreamReference> dreams) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(18 * PdfPageFormat.mm),
        maxPages: 100,
        build: (_) => [
          pw.SizedBox(height: 42 * PdfPageFormat.mm),
          _sectionTitle('이 책의 꿈들'),
          pw.SizedBox(height: 12 * PdfPageFormat.mm),
          if (dreams.isEmpty) pw.Text('기록된 꿈이 없습니다.', style: _metaStyle),
          for (final dream in dreams) ...[
            pw.Text(_date(dream.date), style: _metaStyle),
            pw.SizedBox(height: 2 * PdfPageFormat.mm),
            pw.Text(dream.firstLine.trim(), style: _bodyStyle),
            pw.SizedBox(height: 5 * PdfPageFormat.mm),
          ],
        ],
      ),
    );
  }
}
