import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/model/enums.dart';
import 'package:mumumong/domain/progress.dart';

void main() {
  group('materialUnits', () {
    test('fragment base is 1.0 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.fragment,
          recallAnswers: 0,
          userPassages: 0,
        ),
        1.0,
      );
    });

    test('partial base is 2.0 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.partial,
          recallAnswers: 0,
          userPassages: 0,
        ),
        2.0,
      );
    });

    test('vivid base is 3.0 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.vivid,
          recallAnswers: 0,
          userPassages: 0,
        ),
        3.0,
      );
    });

    test('one recall answer adds 0.25 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.fragment,
          recallAnswers: 1,
          userPassages: 0,
        ),
        1.25,
      );
    });

    test('three recall answers add the maximum 0.75 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.fragment,
          recallAnswers: 3,
          userPassages: 0,
        ),
        1.75,
      );
    });

    test('extra recall answers remain capped at 0.75 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.fragment,
          recallAnswers: 8,
          userPassages: 0,
        ),
        1.75,
      );
    });

    test('one user passage adds 0.5 MU', () {
      expect(
        materialUnits(
          clarity: DreamClarity.fragment,
          recallAnswers: 0,
          userPassages: 1,
        ),
        1.5,
      );
    });

    test('combined bonuses respect both caps', () {
      expect(
        materialUnits(
          clarity: DreamClarity.vivid,
          recallAnswers: 5,
          userPassages: 4,
        ),
        4.75,
      );
    });
  });
}
