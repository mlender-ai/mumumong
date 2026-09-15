import 'model/enums.dart';

double progressRatio({required double progressMu, required double targetMu}) {
  return targetMu <= 0 ? 0 : (progressMu / targetMu).clamp(0.0, 1.0);
}

double materialUnits({
  required DreamClarity clarity,
  required int recallAnswers,
  required int userPassages,
}) {
  if (recallAnswers < 0) {
    throw ArgumentError.value(
      recallAnswers,
      'recallAnswers',
      'must not be negative',
    );
  }
  if (userPassages < 0) {
    throw ArgumentError.value(
      userPassages,
      'userPassages',
      'must not be negative',
    );
  }

  final base = switch (clarity) {
    DreamClarity.fragment => 1.0,
    DreamClarity.partial => 2.0,
    DreamClarity.vivid => 3.0,
  };
  final recall = (recallAnswers * 0.25).clamp(0.0, 0.75);
  final user = (userPassages * 0.5).clamp(0.0, 1.0);
  return base + recall + user;
}
