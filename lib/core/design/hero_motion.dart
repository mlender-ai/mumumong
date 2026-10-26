// DESIGN.md §8–§9: the one narrative from processing to reveal.
// Processing → dots around the Orb settle as the real job advances.
// Reveal → text rises in rhythm; the memory fragment gathers under it.
// Nothing here loops; every motion is driven by a state change and stops.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_system.dart';

/// Dots around the Thinking Orb. The Orb's geometry never changes; the real
/// pipeline stage (0 extract, 1 link, 2 write, 3 validate) only changes how
/// the surrounding memory dots are arranged. A stage change animates once.
class ProcessingHalo extends StatefulWidget {
  const ProcessingHalo({
    super.key,
    required this.stage,
    required this.child,
    this.size = 180,
    this.color,
    this.settleColor,
  });

  /// 0–3; values outside clamp.
  final int stage;
  final Widget child;
  final double size;
  final Color? color;
  final Color? settleColor;

  @override
  State<ProcessingHalo> createState() => _ProcessingHaloState();
}

class _ProcessingHaloState extends State<ProcessingHalo>
    with SingleTickerProviderStateMixin {
  late final _move = AnimationController(
    vsync: this,
    duration: MongMotion.gather,
    value: 1,
  );
  late int _from = widget.stage;
  late int _to = widget.stage;

  @override
  void didUpdateWidget(covariant ProcessingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _from = _to;
      _to = widget.stage;
      if (MediaQuery.disableAnimationsOf(context)) {
        _move.value = 1;
      } else {
        _move.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: ProcessingHaloPainter(
          from: _from,
          to: _to,
          progress: _move,
          arriveColor: widget.color ?? MongColor.sky500,
          settleColor: widget.settleColor ?? context.accentInk,
        ),
        child: Center(child: widget.child),
      ),
    ),
  );
}

@visibleForTesting
class ProcessingHaloPainter extends CustomPainter {
  ProcessingHaloPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.arriveColor,
    required this.settleColor,
  }) : super(repaint: progress);

  final int from;
  final int to;
  final Animation<double> progress;
  final Color arriveColor;
  final Color settleColor;

  static const dots = 24;

  /// Polar layout of one dot for a stage: (radius 0–1, angle, alpha, size).
  @visibleForTesting
  static (double, double, double, double) layout(int stage, int i) {
    final s = stage.clamp(0, 3);
    final random = math.Random(97 + i * 7);
    final base = i / dots * 2 * math.pi;
    switch (s) {
      case 0:
        // Extract: scattered wide, faint, as memory is still loose.
        return (
          .55 + random.nextDouble() * .45,
          base + (random.nextDouble() - .5) * .9,
          .34,
          2.4,
        );
      case 1:
        // Link: dots pull into four groups.
        final group = (i % 4) * (math.pi / 2) + math.pi / 4;
        return (.70, group + (random.nextDouble() - .5) * .5, .52, 2.6);
      case 2:
        // Write: an even ring; the scene is being composed.
        return (.62, base, .70, 2.8);
      default:
        // Validate: tight, sharp ring.
        return (.52, base, .86, 3.0);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = MongMotion.enter.transform(progress.value.clamp(0.0, 1.0));
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final settle = (to / 3).clamp(0.0, 1.0);
    final paint = Paint();
    for (var i = 0; i < dots; i++) {
      final a = layout(from, i);
      final b = layout(to, i);
      final r = _lerp(a.$1, b.$1, t) * maxRadius;
      final angle = _lerpAngle(a.$2, b.$2, t);
      final alpha = _lerp(a.$3, b.$3, t);
      final dot = _lerp(a.$4, b.$4, t);
      final color = Color.lerp(arriveColor, settleColor, settle)!;
      paint
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          _lerp(1.6, .4, settle),
        );
      canvas.drawCircle(
        center + Offset(math.cos(angle) * r, math.sin(angle) * r),
        dot / 2,
        paint,
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _lerpAngle(double a, double b, double t) {
    var delta = (b - a) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    return a + delta * t;
  }

  @override
  bool shouldRepaint(covariant ProcessingHaloPainter old) =>
      old.from != from ||
      old.to != to ||
      old.progress != progress ||
      old.arriveColor != arriveColor ||
      old.settleColor != settleColor;
}

/// Text Reveal recipe: children fade in and rise 6 px, 90 ms apart, 320 ms
/// each. No typing effect. Reduced motion or `animate: false` shows the
/// final frame at once.
class RevealEntrance extends StatefulWidget {
  const RevealEntrance({
    super.key,
    required this.children,
    this.animate = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final bool animate;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<RevealEntrance> createState() => _RevealEntranceState();
}

class _RevealEntranceState extends State<RevealEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  Duration get _total {
    final n = widget.children.length;
    final length =
        MongMotion.revealStagger * math.max(0, n - 1) + MongMotion.revealItem;
    return length < MongMotion.reveal ? length : MongMotion.reveal;
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: _total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _total.inMilliseconds.toDouble();
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) => Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            _revealed(i, totalMs, widget.children[i]),
        ],
      ),
    );
  }

  Widget _revealed(int i, double totalMs, Widget child) {
    final start = (MongMotion.revealStagger.inMilliseconds * i) / totalMs;
    final end =
        ((MongMotion.revealStagger.inMilliseconds * i) +
            MongMotion.revealItem.inMilliseconds) /
        totalMs;
    final t = MongMotion.enter.transform(
      ((_entrance.value - start) / (end - start)).clamp(0.0, 1.0),
    );
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
    );
  }
}
