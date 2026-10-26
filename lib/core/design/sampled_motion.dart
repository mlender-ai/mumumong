import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Decorative light does not need a 60/120Hz invalidation stream. Preserve the
/// time-based phase while limiting expensive background repaints to 30Hz.
class SampledMotion extends ChangeNotifier implements ValueListenable<double> {
  SampledMotion(this.parent) {
    parent.addListener(_tick);
  }
  final AnimationController parent;
  int _lastFrame = -1;
  double _value = 0;
  @override
  double get value => _value;
  void _tick() {
    final frame = (parent.lastElapsedDuration?.inMicroseconds ?? 0) ~/ 33334;
    if (frame == _lastFrame) return;
    _lastFrame = frame;
    _value = parent.value;
    notifyListeners();
  }

  @override
  void dispose() {
    parent.removeListener(_tick);
    super.dispose();
  }
}
