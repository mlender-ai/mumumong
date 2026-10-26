import 'dart:convert';
import '../../data/export/completed_volume_pdf.dart';
import 'enums.dart';

/// Immutable versioned copy. No raw dream body is included.
class FrozenBook {
  FrozenBook(Map<String, dynamic> value) : _encoded = jsonEncode(value) {
    if (value['version'] != 1 ||
        value['volume_id'] is! String ||
        value['request_id'] is! String ||
        value['title'] is! String ||
        (value['title'] as String).trim().isEmpty ||
        value['scenes'] is! List ||
        (value['scenes'] as List).isEmpty) {
      throw const FormatException('invalid_completed_book');
    }
    DateTime.parse(value['completed_at'] as String);
  }
  final String _encoded;
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  String get volumeId => toJson()['volume_id'] as String;
  String get requestId => toJson()['request_id'] as String;
  int get volumeNo => (toJson()['volume_no'] as num).toInt();
  String get title => toJson()['title'] as String;
  String? get authorNote => toJson()['author_note'] as String?;
  DateTime get completedAt =>
      DateTime.parse(toJson()['completed_at'] as String);
  List<Map<String, dynamic>> get scenes => (toJson()['scenes'] as List)
      .map((s) => Map<String, dynamic>.from(s as Map))
      .toList(growable: false);
  CompletedVolumeSnapshot get pdfSnapshot {
    final doc = toJson();
    final ordered = scenes;
    return CompletedVolumeSnapshot(
      volumeNo: volumeNo,
      status: VolumeStatus.completed,
      title: title,
      completedAt: completedAt,
      authorNote: authorNote,
      chapters: [
        for (var i = 0; i < ordered.length; i++)
          BookChapter(
            number: i + 1,
            title: (ordered[i]['title'] as String?)?.trim().isNotEmpty == true
                ? ordered[i]['title'] as String
                : '장면 ${i + 1}',
            paragraphs: [
              for (final raw in ordered[i]['passages'] as List)
                BookParagraph(
                  text: (raw as Map)['text'] as String,
                  origin: enumFromDatabase(raw['origin'], PassageOrigin.values),
                ),
            ],
          ),
      ],
      dreams: [
        for (final raw in doc['dreams'] as List? ?? [])
          if (((raw as Map)['first_line'] as String? ?? '').trim().isNotEmpty)
            BookDreamReference(
              date: DateTime.parse(raw['date'] as String),
              firstLine: raw['first_line'] as String,
            ),
      ],
    );
  }
}

class BookCompletionPreview {
  const BookCompletionPreview({
    required this.document,
    required this.revision,
    required this.eligible,
    required this.busy,
  });
  final Map<String, dynamic> document;
  final String revision;
  final bool eligible;
  final bool busy;
}
