import 'model/enums.dart';

DreamClarity classifyDreamClarity({
  required int elementCount,
  required int eventCount,
  required int placeTransitionCount,
}) {
  if (elementCount < 0) {
    throw ArgumentError.value(
      elementCount,
      'elementCount',
      'must not be negative',
    );
  }
  if (eventCount < 0 || eventCount > elementCount) {
    throw ArgumentError.value(
      eventCount,
      'eventCount',
      'must be between zero and elementCount',
    );
  }
  if (placeTransitionCount < 0) {
    throw ArgumentError.value(
      placeTransitionCount,
      'placeTransitionCount',
      'must not be negative',
    );
  }

  if (elementCount <= 3) {
    return DreamClarity.fragment;
  }
  if (eventCount >= 3 || placeTransitionCount >= 2) {
    return DreamClarity.vivid;
  }
  if (eventCount >= 1) {
    return DreamClarity.partial;
  }
  return DreamClarity.fragment;
}
