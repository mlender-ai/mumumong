import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A continuously deforming colour field, independent of AI job progress.
/// The mesh moves its *colour boundaries*, not just a translucent overlay.
class FlowingGradient extends StatefulWidget {
  const FlowingGradient({
    super.key,
    this.animate = true,
    this.intensity = 1,
    this.immersive = false,
  });

  final bool animate;
  final double intensity;
  final bool immersive;

  @override
  State<FlowingGradient> createState() => _FlowingGradientState();
}

class _FlowingGradientState extends State<FlowingGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant FlowingGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context) || !widget.animate;
    return RepaintBoundary(
      child: CustomPaint(
        painter: FlowingGradientPainter(
          phase: still ? .35 : 0,
          animation: still ? null : _motion,
          intensity: widget.intensity.clamp(0, 1),
          immersive: widget.immersive,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

@visibleForTesting
class FlowingGradientPainter extends CustomPainter {
  const FlowingGradientPainter({
    double phase = .35,
    this.animation,
    required this.intensity,
    this.immersive = false,
  }) : _staticPhase = phase,
       super(repaint: animation);

  final double _staticPhase;
  final Animation<double>? animation;
  final double intensity;
  final bool immersive;

  double get phase => animation?.value ?? _staticPhase;

  static const _deep = Color(0xFF6D9CC0);
  static const _sky = Color(0xFF91BDD7);
  static const _ice = Color(0xFFD8ECF3);
  static const _lavender = Color(0xFFAAAEC9);
  static const _warm = Color(0xFFE5D9DC);
  static const _columns = 20;
  static const _rows = 32;
  static final _positions = _makePositions();
  static final _indices = _makeIndices();

  static List<Offset> _makePositions() => List.unmodifiable([
    for (var row = 0; row <= _rows; row++)
      for (var column = 0; column <= _columns; column++)
        Offset(column / _columns, row / _rows),
  ]);

  static List<int> _makeIndices() {
    final indices = <int>[];
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final a = row * (_columns + 1) + column;
        indices.addAll([
          a,
          a + _columns + 1,
          a + 1,
          a + 1,
          a + _columns + 1,
          a + _columns + 2,
        ]);
      }
    }
    return List.unmodifiable(indices);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = phase * math.pi * 2;
    final colors = <Color>[];
    for (final position in _positions) {
      final x = position.dx;
      final y = position.dy;
      final fold =
          .16 * math.sin(t + x * math.pi * 1.55 + y * 1.3) +
          .075 * math.sin(t * 2 - x * math.pi * 2.1 + y * 4.2) +
          .035 * math.cos(t * 3 + x * 5.1 - y * 8.0);
      final field = (y + fold).clamp(0.0, 1.0);
      final colour = _palette(field, x, t);
      colors.add(
        immersive
            ? colour
            : Color.lerp(const Color(0xFFFFFEFC), colour, .38 * intensity)!,
      );
    }

    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawVertices(
      ui.Vertices(
        VertexMode.triangles,
        _positions,
        colors: colors,
        indices: _indices,
      ),
      BlendMode.srcOver,
      Paint()..isAntiAlias = true,
    );
    canvas.restore();
  }

  Color _palette(double field, double x, double t) {
    final light = .035 * math.sin(t + x * math.pi * 2);
    final value = (field + light).clamp(0.0, 1.0);
    if (value < .22) return Color.lerp(_ice, _sky, _smooth(value / .22))!;
    if (value < .48) {
      return Color.lerp(_sky, _deep, _smooth((value - .22) / .26))!;
    }
    if (value < .68) {
      return Color.lerp(_deep, _lavender, _smooth((value - .48) / .2))!;
    }
    return Color.lerp(_lavender, _warm, _smooth((value - .68) / .32))!;
  }

  double _smooth(double value) => value * value * (3 - 2 * value);

  @override
  bool shouldRepaint(covariant FlowingGradientPainter oldDelegate) =>
      oldDelegate._staticPhase != _staticPhase ||
      oldDelegate.animation != animation ||
      oldDelegate.intensity != intensity ||
      oldDelegate.immersive != immersive;
}
