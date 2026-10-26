import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;
import 'design_system.dart';

enum DreamOrbState { listening, gathering, connecting, composing, checking }

class ThinkingOrb extends StatelessWidget {
  const ThinkingOrb({
    super.key,
    required this.state,
    this.size = 64,
    this.color = MongColor.orbInk,
  });

  final DreamOrbState state;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The reference's 64 px state designs are not scaled into a large ball.
    // The package owns its animation clock and reduced-motion behavior.
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: orbs.ThinkingOrb(
            // One visual identity throughout a wait. Changing the actual job
            // phase only changes its accessible description, not the geometry.
            // Libraries.dev's "Thinking…" reference uses composing (ribbon).
            // Never replace that banded sphere with the connecting web mesh.
            state: orbs.OrbState.composing,
            size: orbs.OrbSize.size64,
            color: color,
            semanticLabel: switch (state) {
              DreamOrbState.listening => '기억을 듣는 중',
              DreamOrbState.gathering => '기억을 모으는 중',
              DreamOrbState.connecting => '연결을 찾는 중',
              DreamOrbState.composing => '장면을 쓰는 중',
              DreamOrbState.checking => '장면을 확인하는 중',
            },
          ),
        ),
      ),
    );
  }
}

/// A moving highlight around a rounded input or job-state container.
class BeamFrame extends StatelessWidget {
  const BeamFrame({
    super.key,
    required this.child,
    required this.active,
    required this.phase,
    this.radius = 24,
  });

  final Widget child;
  final bool active;
  final double phase;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: BeamFramePainter(
          active: active,
          phase: reduced ? 0 : phase,
          radius: radius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
      ),
    );
  }
}

@visibleForTesting
class BeamFramePainter extends CustomPainter {
  const BeamFramePainter({
    required this.active,
    required this.phase,
    required this.radius,
  });

  final bool active;
  final double phase;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shape = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(2.5),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFBBD9E9).withValues(alpha: .65),
    );
    if (!active) return;
    final path = Path()..addRRect(shape);
    final metric = path.computeMetrics().first;
    final start = metric.length * phase.clamp(0, 1);
    final length = math.min(metric.length * .22, 104.0);
    final beam = Path()
      ..addPath(
        metric.extractPath(start, math.min(start + length, metric.length)),
        Offset.zero,
      );
    if (start + length > metric.length) {
      beam.addPath(
        metric.extractPath(0, start + length - metric.length),
        Offset.zero,
      );
    }
    canvas.drawPath(
      beam,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF65B7E5).withValues(alpha: .44)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      beam,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFFB7E5F8), Color(0xFF4EA8DE), Color(0xFFB7E5F8)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant BeamFramePainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.phase != phase ||
      oldDelegate.radius != radius;
}
