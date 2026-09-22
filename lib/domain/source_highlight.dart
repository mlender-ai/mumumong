import 'model/dream_element.dart';
import 'model/enums.dart';

/// Returns merged UTF-16 ranges for Flutter. Database spans use Unicode points.
List<(int, int)> sourceHighlights(
  String text,
  Iterable<DreamElement> elements,
) {
  final offsets = <int>[0];
  for (final rune in text.runes) {
    offsets.add(offsets.last + (rune > 0xffff ? 2 : 1));
  }
  final ranges = <(int, int)>[];
  for (final element in elements) {
    // Recall answers are not offsets into the raw dream.
    if (element.source.databaseValue != 'raw') continue;
    final span = element.span;
    if (span != null &&
        span.$1 >= 0 &&
        span.$2 > span.$1 &&
        span.$2 < offsets.length) {
      ranges.add((offsets[span.$1], offsets[span.$2]));
    } else if (element.label.isNotEmpty) {
      var start = text.indexOf(element.label);
      while (start >= 0) {
        ranges.add((start, start + element.label.length));
        start = text.indexOf(element.label, start + element.label.length);
      }
    }
  }
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final range in ranges) {
    if (merged.isNotEmpty && range.$1 <= merged.last.$2) {
      final last = merged.removeLast();
      merged.add((last.$1, range.$2 > last.$2 ? range.$2 : last.$2));
    } else {
      merged.add(range);
    }
  }
  return merged;
}
