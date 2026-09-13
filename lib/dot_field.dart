import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_system.dart';

double _hash(int x, int y, int seed) {
  var value = x * 374761393 + y * 668265263 + seed * 69069;
  value = (value ^ (value >> 13)) * 1274126177;
  return ((value ^ (value >> 16)) & 0x7fffffff) / 0x7fffffff;
}

class DotCover extends StatelessWidget {
  const DotCover({
    super.key,
    required this.clarity,
    this.growth = 1,
    this.seed = 14,
    this.ink = MongColor.ink,
    this.background = MongColor.paperPure,
  });

  final double clarity;
  final double growth;
  final int seed;
  final Color ink;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ColoredBox(
          color: background,
          child: CustomPaint(
            painter: DotCoverPainter(
              clarity: clarity.clamp(0, .9),
              growth: growth.clamp(0, 1),
              seed: seed,
              ink: ink,
            ),
          ),
        ),
      ),
    );
  }
}

class DotCoverPainter extends CustomPainter {
  const DotCoverPainter({
    required this.clarity,
    required this.growth,
    required this.seed,
    required this.ink,
  });

  final double clarity;
  final double growth;
  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.max(5.0, size.width / 44);
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    final oldClarity = math.max(.1, clarity - .08);
    final effectiveClarity = oldClarity + (clarity - oldClarity) * growth;
    final dropout = .12 + .6 * (1 - effectiveClarity);
    final basePaint = Paint()..color = ink;
    final skyPaint = Paint()..color = MongColor.sky500;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final nx = (col + .5) / cols;
        final ny = (row + .5) / rows;
        final random = _hash(col, row, seed);
        final form = _doorMask(nx, ny, effectiveClarity);
        final stray = random > .962 + .025 * effectiveClarity;
        if (!stray && (form < .13 || _hash(col + 9, row + 3, seed) < dropout)) {
          continue;
        }

        final jitterScale = .15 * cell * (1 - effectiveClarity);
        final dx = (_hash(col + 1, row, seed) - .5) * 2 * jitterScale;
        final dy = (_hash(col, row + 1, seed) - .5) * 2 * jitterScale;
        final amount = stray ? .25 : form * (.35 + .65 * effectiveClarity);
        final radius = .4 * cell * math.sqrt(amount.clamp(.05, 1));
        final isNew =
            clarity > oldClarity &&
            form > .2 &&
            _hash(col + 30, row + 20, seed) > .78 &&
            growth < .82;
        canvas.drawCircle(
          Offset((col + .5) * cell + dx, (row + .5) * cell + dy),
          radius,
          isNew ? skyPaint : basePaint,
        );
      }
    }
  }

  double _doorMask(double x, double y, double clarity) {
    final blur = (1 - clarity) * .12;
    final left = _band(x, .23, .055 + blur) * _between(y, .14, .87, blur);
    final right = _band(x, .77, .055 + blur) * _between(y, .14, .87, blur);
    final top = _band(y, .16, .045 + blur) * _between(x, .2, .8, blur);
    final innerShade =
        _between(x, .32, .68, .04 + blur) *
        _between(y, .25, .82, .05 + blur) *
        .24;
    final threshold = .74 - (y * .45);
    final openingEdge =
        _band(x, threshold, .025 + blur * .5) *
        _between(y, .28, .82, blur) *
        .9;
    final floor =
        _band(x, .5, .12 + y * .08) * _between(y, .78, .94, .06) * .45;
    return math.max(
      math.max(math.max(left, right), math.max(top, openingEdge)),
      math.max(innerShade, floor),
    );
  }

  double _band(double value, double center, double width) {
    final distance = (value - center).abs();
    return (1 - distance / width).clamp(0, 1);
  }

  double _between(double value, double min, double max, double feather) {
    if (value < min - feather || value > max + feather) return 0;
    if (value < min) return ((value - min + feather) / feather).clamp(0, 1);
    if (value > max) return ((max + feather - value) / feather).clamp(0, 1);
    return 1;
  }

  @override
  bool shouldRepaint(covariant DotCoverPainter oldDelegate) {
    return oldDelegate.clarity != clarity ||
        oldDelegate.growth != growth ||
        oldDelegate.seed != seed ||
        oldDelegate.ink != ink;
  }
}

class MemoryParticles extends StatelessWidget {
  const MemoryParticles({
    super.key,
    required this.count,
    this.progress = 0,
    this.forming = false,
    this.color = MongColor.ink,
  });

  final int count;
  final double progress;
  final bool forming;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: MemoryParticlePainter(
          count: count.clamp(0, 300),
          progress: progress,
          forming: forming,
          color: color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class MemoryParticlePainter extends CustomPainter {
  const MemoryParticlePainter({
    required this.count,
    required this.progress,
    required this.forming,
    required this.color,
  });

  final int count;
  final double progress;
  final bool forming;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final ink = Paint()..color = color;
    final sky = Paint()..color = MongColor.sky500;
    final visibleCount = math.max(20, count);
    for (var i = 0; i < visibleCount; i++) {
      final hx = _hash(i, 4, 81);
      final hy = _hash(i, 9, 16);
      final drift = math.sin(progress * math.pi * 2 + i * .7) * 3;
      var point = Offset(
        18 + hx * (size.width - 36),
        size.height * (.24 + hy * .68) + drift,
      );
      if (forming) {
        final target = Offset(size.width * .5, size.height * .1);
        point = Offset.lerp(
          point,
          target,
          Curves.easeInOut.transform(progress),
        )!;
      }
      final radius = 1.1 + _hash(i, 18, 22) * 2.1;
      final paint = i > visibleCount - 5 ? sky : ink;
      canvas.drawCircle(point, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MemoryParticlePainter oldDelegate) => true;
}
