import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/source_highlight.dart';

DreamElement element({
  String label = '문',
  (int, int)? span,
  DreamElementSource source = DreamElementSource.raw,
}) => DreamElement(
  id: 'e',
  dreamId: 'd',
  type: DreamElementType.object,
  label: label,
  detail: null,
  salience: DreamElementSalience.high,
  source: source,
  span: span,
);

void main() {
  test('Unicode database offsets become UTF16 offsets including emoji', () {
    expect(sourceHighlights('🌙 붉은 문', [element(span: (2, 6))]), [(3, 7)]);
  });
  test('null and invalid spans fall back to all matching labels', () {
    expect(sourceHighlights('문 옆의 문', [element()]), [(0, 1), (5, 6)]);
    expect(sourceHighlights('문', [element(span: (0, 99))]), [(0, 1)]);
  });
  test('overlapping and adjacent sources merge', () {
    expect(
      sourceHighlights('붉은 문', [element(span: (0, 3)), element(span: (2, 4))]),
      [(0, 4)],
    );
  });
  test('unmatched and recall sources never highlight unrelated raw text', () {
    expect(sourceHighlights('문', [element(label: '없는 말')]), isEmpty);
    expect(
      sourceHighlights('문', [element(source: DreamElementSource.recall)]),
      isEmpty,
    );
  });
}
