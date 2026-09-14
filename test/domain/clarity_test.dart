import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/clarity.dart';
import 'package:mumumong/domain/model/enums.dart';

void main() {
  group('classifyDreamClarity boundaries', () {
    test('three or fewer elements always stay fragment', () {
      expect(
        classifyDreamClarity(
          elementCount: 3,
          eventCount: 3,
          placeTransitionCount: 2,
        ),
        DreamClarity.fragment,
      );
    });

    test('four elements without an event stay fragment', () {
      expect(
        classifyDreamClarity(
          elementCount: 4,
          eventCount: 0,
          placeTransitionCount: 0,
        ),
        DreamClarity.fragment,
      );
    });

    test('one event becomes partial above the element floor', () {
      expect(
        classifyDreamClarity(
          elementCount: 4,
          eventCount: 1,
          placeTransitionCount: 0,
        ),
        DreamClarity.partial,
      );
    });

    test('two events remain partial', () {
      expect(
        classifyDreamClarity(
          elementCount: 4,
          eventCount: 2,
          placeTransitionCount: 1,
        ),
        DreamClarity.partial,
      );
    });

    test('three events become vivid', () {
      expect(
        classifyDreamClarity(
          elementCount: 4,
          eventCount: 3,
          placeTransitionCount: 0,
        ),
        DreamClarity.vivid,
      );
    });

    test('two place transitions become vivid', () {
      expect(
        classifyDreamClarity(
          elementCount: 4,
          eventCount: 0,
          placeTransitionCount: 2,
        ),
        DreamClarity.vivid,
      );
    });
  });
}
