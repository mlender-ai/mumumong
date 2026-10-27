// V2 surfaces (DESIGN_V2.md §4). One painter renders every material so a
// button, a card, a sheet and the navigation share the same light, rim and
// shadow. Screens choose a kind; they never hand-build panels.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'tokens.dart';

enum V2SurfaceKind {
  /// Opaque warm paper for reading and the manuscript page.
  paper,

  /// Boundaryless light: no rim, no shadow, only a soft lift of the space.
  atmospheric,

  /// Translucent frosted glass for in-flow cards and pills.
  frosted,

  /// Denser glass that sits above content (sheets, hero cards).
  elevated,

  /// Glass that floats above everything (navigation, floating controls).
  floating,

  /// Solid ink used by primary actions.
  ink,
}

@immutable
class V2SurfaceStyle {
  const V2SurfaceStyle({
    required this.kind,
    this.radius = V2Radius.card,
    this.chroma = 0,
    this.sink = 0,
    this.hover = 0,
    this.blur,
    this.shadow = true,
  });

  final V2SurfaceKind kind;
  final double radius;

  /// Chromatic warm/sky light inside glass (Reference A). 0..1.
  final double chroma;

  /// Press depth 0..1 from V2PressState.
  final double sink;
  final double hover;

  /// Backdrop blur sigma; null uses the kind default.
  final double? blur;
  final bool shadow;

  double get backdropBlur =>
      blur ??
      switch (kind) {
        V2SurfaceKind.frosted => V2Glass.blur,
        V2SurfaceKind.elevated => V2Glass.blur,
        V2SurfaceKind.floating => V2Glass.heavyBlur,
        _ => 0,
      };

  List<BoxShadow> get shadows {
    if (!shadow || kind == V2SurfaceKind.atmospheric) return const [];
    final rest = switch (kind) {
      V2SurfaceKind.floating => V2Shadow.floating,
      V2SurfaceKind.elevated => V2Shadow.raised,
      _ => V2Shadow.rest,
    };
    final lifted = BoxShadow.lerpList(
      rest,
      kind == V2SurfaceKind.floating ? V2Shadow.floating : V2Shadow.raised,
      hover * .6,
    )!;
    return BoxShadow.lerpList(lifted, V2Shadow.pressed, sink)!;
  }
}

ui.RSuperellipse v2Shape(Rect rect, double radius) =>
    ui.RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(math.min(radius, rect.shortestSide / 2)),
    );

class V2ShadowPainter extends CustomPainter {
  const V2ShadowPainter({required this.radius, required this.shadows});

  final double radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final rect = Offset.zero & size;
    // Shadows live outside the material only: translucent glass must not
    // show its own shadow through itself.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(120)),
        Path()..addRSuperellipse(v2Shape(rect, radius)),
      ),
    );
    for (final shadow in shadows) {
      final r = rect.shift(shadow.offset).inflate(shadow.spreadRadius);
      // A blurred rounded rect is the fast, well-supported shadow path on
      // every renderer; the superellipse difference is invisible here.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r,
          Radius.circular(math.min(radius, r.shortestSide / 2)),
        ),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(V2ShadowPainter old) =>
      old.radius != radius || !listEquals(old.shadows, shadows);
}

class V2FillPainter extends CustomPainter {
  const V2FillPainter(this.style, {this.night = false});

  final V2SurfaceStyle style;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = v2Shape(rect, style.radius);
    final sink = style.sink.clamp(0.0, 1.0);
    final w = size.width, h = size.height;

    switch (style.kind) {
      case V2SurfaceKind.paper:
        canvas.drawRSuperellipse(
          shape,
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topCenter,
              rect.bottomCenter,
              night
                  ? [V2Color.nightPaper, V2Color.nightPaper]
                  : [V2Color.paperPure, V2Color.paper],
            ),
        );
      case V2SurfaceKind.atmospheric:
        canvas.drawRSuperellipse(
          shape,
          Paint()
            ..shader = ui.Gradient.radial(rect.center, math.max(w, h) * .6, [
              Colors.white.withValues(alpha: .34),
              Colors.white.withValues(alpha: 0),
            ]),
        );
        return;
      case V2SurfaceKind.ink:
        canvas.drawRSuperellipse(
          shape,
          Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              Color.lerp(
                const Color(0xFF2B3038),
                const Color(0xFF353B45),
                style.hover * .6,
              )!,
              const Color(0xFF111316),
            ]),
        );
      case V2SurfaceKind.frosted ||
          V2SurfaceKind.elevated ||
          V2SurfaceKind.floating:
        final dense = style.kind != V2SurfaceKind.frosted;
        final top = dense ? V2Glass.elevatedTop : V2Glass.fillTop;
        final bottom = dense ? V2Glass.elevatedBottom : V2Glass.fillBottom;
        canvas.drawRSuperellipse(
          shape,
          Paint()
            ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              Colors.white.withValues(alpha: top + style.hover * .06),
              Colors.white.withValues(alpha: bottom - sink * .08),
            ]),
        );
    }

    canvas.save();
    canvas.clipRSuperellipse(shape);

    // Chromatic light (Reference A): warm on the left, sky in the middle.
    // Pressing gathers the light and drifts it toward the touch.
    final chroma = (style.chroma + sink * .35).clamp(0.0, 1.0);
    if (chroma > 0 && style.kind != V2SurfaceKind.ink) {
      final drift = sink * w * .05;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w * .16 + drift, h * .78),
            math.max(w * .46, h * .9),
            [
              V2Color.lightWarm.withValues(alpha: .62 * chroma),
              V2Color.lightWarm.withValues(alpha: 0),
            ],
          ),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w * .46 + drift, h * .18),
            math.max(w * .42, h * .9),
            [
              V2Color.sky200.withValues(alpha: .78 * chroma),
              V2Color.sky200.withValues(alpha: 0),
            ],
          ),
      );
    }

    // Top sheen: the light source. It dims and slides down as the surface
    // sinks, which reads as depth rather than a color change.
    if (style.kind != V2SurfaceKind.paper || night) {
      final sheenAlpha = switch (style.kind) {
        V2SurfaceKind.ink => .13,
        _ => .42,
      };
      final shift = style.sink * 2.5;
      canvas.drawRect(
        Rect.fromLTWH(0, shift, w, h * .52),
        Paint()
          ..shader =
              ui.Gradient.linear(Offset(0, shift), Offset(0, shift + h * .52), [
                Colors.white.withValues(
                  alpha: sheenAlpha * (1 - sink * .7) + style.hover * .05,
                ),
                Colors.white.withValues(alpha: 0),
              ]),
      );
    }

    // Inset shade while pressed: the surface is now below its rim.
    if (sink > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, Offset(0, h * .55), [
            const Color(0xFF0E1A28).withValues(
              alpha: (style.kind == V2SurfaceKind.ink ? .30 : .08) * sink,
            ),
            const Color(0xFF0E1A28).withValues(alpha: 0),
          ]),
      );
    }
    canvas.restore();

    // Rim: a lit top edge fading toward the bottom.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    switch (style.kind) {
      case V2SurfaceKind.paper:
        rim.color = night ? V2Color.nightLine : V2Color.hairline;
      case V2SurfaceKind.ink:
        rim.shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          Colors.white.withValues(alpha: .20 * (1 - sink * .6)),
          Colors.white.withValues(alpha: 0),
        ]);
      case V2SurfaceKind.atmospheric:
        return;
      default:
        rim.shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          Colors.white.withValues(alpha: .95 - sink * .3),
          Colors.white.withValues(alpha: .35),
        ]);
    }
    canvas.drawRSuperellipse(v2Shape(rect.deflate(.5), style.radius), rim);
    if (style.kind == V2SurfaceKind.frosted ||
        style.kind == V2SurfaceKind.elevated ||
        style.kind == V2SurfaceKind.floating) {
      // A faint outer hairline keeps glass legible on white backgrounds.
      canvas.drawRSuperellipse(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = const Color(0xFF1C3552).withValues(alpha: .07),
      );
    }
  }

  @override
  bool shouldRepaint(V2FillPainter old) =>
      old.night != night ||
      old.style.kind != style.kind ||
      old.style.radius != style.radius ||
      old.style.chroma != style.chroma ||
      old.style.sink != style.sink ||
      old.style.hover != style.hover;
}

/// A V2 material. Glass kinds blur what is behind them (Reference E);
/// set [blur] to 0 for glass over a static, already-soft background.
class V2Surface extends StatelessWidget {
  const V2Surface({
    super.key,
    required this.kind,
    this.child,
    this.radius,
    this.padding = const EdgeInsets.all(V2Space.lg),
    this.chroma = 0,
    this.sink = 0,
    this.hover = 0,
    this.blur,
    this.shadow = true,
    this.night = false,
    this.width,
    this.height,
  });

  final V2SurfaceKind kind;
  final Widget? child;
  final double? radius;
  final EdgeInsetsGeometry padding;
  final double chroma;
  final double sink;
  final double hover;
  final double? blur;
  final bool shadow;
  final bool night;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final style = V2SurfaceStyle(
      kind: kind,
      radius: radius ?? V2Radius.card,
      chroma: chroma,
      sink: sink,
      hover: hover,
      blur: blur,
      shadow: shadow,
    );
    Widget content = CustomPaint(
      painter: V2FillPainter(style, night: night),
      child: Padding(padding: padding, child: child),
    );
    final sigma = style.backdropBlur;
    if (sigma > 0) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      );
    }
    content = ClipRSuperellipse(
      borderRadius: BorderRadius.circular(style.radius),
      child: content,
    );
    final shadows = style.shadows;
    if (shadows.isNotEmpty) {
      content = CustomPaint(
        painter: V2ShadowPainter(radius: style.radius, shadows: shadows),
        child: content,
      );
    }
    return SizedBox(width: width, height: height, child: content);
  }
}
