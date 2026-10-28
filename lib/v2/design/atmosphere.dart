// The V2 space (DESIGN_V2.md §3.3, References D and F). One continuous sky:
// a base gradient, diffused light without edges, an optional blurred sky
// photograph and a fine print grain. Moods and real states move the light;
// between them the light keeps drifting slowly, like V1's flowing gradient,
// and stops in the background, on hidden routes and with Reduce Motion.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/design/sampled_motion.dart';
import 'tokens.dart';

enum V2Mood { intro, home, capture, processing, reveal, archive, quiet }

@immutable
class V2Light {
  const V2Light(this.center, this.radius, this.color, this.alpha);

  /// Center in fractions of the canvas.
  final Offset center;

  /// Radius as a fraction of the canvas' longest side.
  final double radius;
  final Color color;
  final double alpha;

  static V2Light lerp(V2Light a, V2Light b, double t) => V2Light(
    Offset.lerp(a.center, b.center, t)!,
    ui.lerpDouble(a.radius, b.radius, t)!,
    Color.lerp(a.color, b.color, t)!,
    ui.lerpDouble(a.alpha, b.alpha, t)!,
  );
}

@immutable
class V2AtmosphereSpec {
  const V2AtmosphereSpec({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.middleStop,
    required this.lights,
    this.sky = 0,
  });

  final Color top;
  final Color middle;
  final Color bottom;
  final double middleStop;

  /// Exactly three lights so moods interpolate pairwise.
  final List<V2Light> lights;

  /// Opacity of the sky photograph layer.
  final double sky;

  static V2AtmosphereSpec lerp(
    V2AtmosphereSpec a,
    V2AtmosphereSpec b,
    double t,
  ) => V2AtmosphereSpec(
    top: Color.lerp(a.top, b.top, t)!,
    middle: Color.lerp(a.middle, b.middle, t)!,
    bottom: Color.lerp(a.bottom, b.bottom, t)!,
    middleStop: ui.lerpDouble(a.middleStop, b.middleStop, t)!,
    lights: [
      for (var i = 0; i < 3; i++) V2Light.lerp(a.lights[i], b.lights[i], t),
    ],
    sky: ui.lerpDouble(a.sky, b.sky, t)!,
  );

  /// Preset for a mood. [energy] (0..1) is a live, event-driven input such as
  /// the amount written or the voice level; [stage] is the real job stage.
  factory V2AtmosphereSpec.of(V2Mood mood, {double energy = 0, int stage = 0}) {
    final e = energy.clamp(0.0, 1.0);
    switch (mood) {
      case V2Mood.intro:
        return const V2AtmosphereSpec(
          top: V2Color.sky400,
          middle: V2Color.sky100,
          bottom: V2Color.paper,
          middleStop: .55,
          sky: 1,
          lights: [
            V2Light(Offset(.12, .08), .55, V2Color.lightWarm, .55),
            V2Light(Offset(.86, .30), .45, V2Color.sky200, .35),
            V2Light(Offset(.50, .72), .55, V2Color.paperPure, .70),
          ],
        );
      case V2Mood.home:
        return const V2AtmosphereSpec(
          top: V2Color.sky200,
          middle: V2Color.sky50,
          bottom: V2Color.paper,
          middleStop: .38,
          sky: .22,
          lights: [
            V2Light(Offset(.88, .02), .55, V2Color.sky300, .55),
            V2Light(Offset(.06, .12), .42, V2Color.lightWarm, .42),
            V2Light(Offset(.50, .46), .50, V2Color.paperPure, .55),
          ],
        );
      case V2Mood.archive:
        return const V2AtmosphereSpec(
          top: V2Color.sky100,
          middle: V2Color.sky50,
          bottom: V2Color.paper,
          middleStop: .30,
          lights: [
            V2Light(Offset(.92, .00), .45, V2Color.sky200, .50),
            V2Light(Offset(.10, .06), .36, V2Color.lightWarm, .30),
            V2Light(Offset(.50, .50), .50, V2Color.paperPure, .40),
          ],
        );
      case V2Mood.capture:
        return V2AtmosphereSpec(
          top: Color.lerp(V2Color.sky100, V2Color.sky200, e)!,
          middle: V2Color.sky50,
          bottom: V2Color.paper,
          middleStop: .42,
          lights: [
            V2Light(
              const Offset(.50, .24),
              .40 + e * .14,
              V2Color.sky300,
              .38 + e * .34,
            ),
            V2Light(
              Offset(.16 + e * .08, .12),
              .36 + e * .06,
              V2Color.lightWarm,
              .36 + e * .18,
            ),
            const V2Light(Offset(.5, .78), .50, V2Color.paperPure, .55),
          ],
        );
      case V2Mood.processing:
        final s = stage.clamp(0, 3);
        const centers = [
          [Offset(.20, .20), Offset(.82, .30), Offset(.50, .78)],
          [Offset(.32, .26), Offset(.70, .36), Offset(.50, .74)],
          [Offset(.42, .34), Offset(.60, .38), Offset(.50, .70)],
          [Offset(.50, .36), Offset(.52, .40), Offset(.50, .66)],
        ];
        return V2AtmosphereSpec(
          top: V2Color.sky200,
          middle: V2Color.sky50,
          bottom: V2Color.paper,
          middleStop: .48,
          lights: [
            V2Light(
              centers[s][0],
              .42 + s * .03,
              V2Color.sky300,
              .45 + s * .05,
            ),
            V2Light(centers[s][1], .38, V2Color.lightWarm, .30 + s * .06),
            V2Light(centers[s][2], .50, V2Color.paperPure, .55),
          ],
        );
      case V2Mood.reveal:
        return const V2AtmosphereSpec(
          top: V2Color.sky200,
          middle: V2Color.sky50,
          bottom: V2Color.paper,
          middleStop: .30,
          lights: [
            V2Light(Offset(.50, .00), .55, V2Color.sky300, .45),
            V2Light(Offset(.50, .26), .40, V2Color.lightWarm, .40),
            V2Light(Offset(.50, .60), .55, V2Color.paperPure, .65),
          ],
        );
      case V2Mood.quiet:
        return const V2AtmosphereSpec(
          top: V2Color.paper,
          middle: V2Color.paper,
          bottom: V2Color.paper,
          middleStop: .5,
          lights: [
            V2Light(Offset(.5, 0), .4, V2Color.sky100, .3),
            V2Light(Offset(.1, .1), .3, V2Color.lightWarm, .15),
            V2Light(Offset(.5, .6), .5, V2Color.paperPure, .3),
          ],
        );
    }
  }
}

/// How strongly V1's flowing light shows for each mood: fullest at home,
/// quiet where reading or a result needs calm.
double v2FlowingStrength(V2Mood mood) => switch (mood) {
  V2Mood.intro => .55,
  V2Mood.home => .85,
  V2Mood.capture => .6,
  V2Mood.processing => .7,
  V2Mood.reveal => .4,
  V2Mood.archive => .6,
  V2Mood.quiet => .35,
};

class _AtmosphereSpecTween extends Tween<V2AtmosphereSpec> {
  _AtmosphereSpecTween({super.end});

  @override
  V2AtmosphereSpec lerp(double t) => V2AtmosphereSpec.lerp(begin!, end!, t);
}

class V2Atmosphere extends StatefulWidget {
  const V2Atmosphere({
    super.key,
    required this.mood,
    this.energy = 0,
    this.stage = 0,
    this.duration = V2Motion.page,
    this.drift = true,
    this.child,
  });

  final V2Mood mood;
  final double energy;
  final int stage;
  final Duration duration;

  /// The slow idle drift of the light (V1's flowing gradient).
  final bool drift;
  final Widget? child;

  static const skyAsset = 'assets/v2/sky_key.jpg';

  /// One drift cycle, as in V1.
  static const driftPeriod = Duration(seconds: 14);

  @override
  State<V2Atmosphere> createState() => _V2AtmosphereState();
}

class _V2AtmosphereState extends State<V2Atmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: V2Atmosphere.driftPeriod,
  );
  // Decorative light needs no 120Hz invalidation stream.
  late final _sampled = SampledMotion(_clock);
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant V2Atmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!_foreground || !widget.drift || V2Motion.reduced(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sampled.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = V2AtmosphereSpec.of(
      widget.mood,
      energy: widget.energy,
      stage: widget.stage,
    );
    final drifting = widget.drift && !V2Motion.reduced(context);
    return TweenAnimationBuilder<V2AtmosphereSpec>(
      tween: _AtmosphereSpecTween(end: target),
      duration: V2Motion.of(context, widget.duration),
      curve: V2Motion.drift,
      builder: (context, spec, child) => Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _AtmospherePainter(
                spec,
                clock: drifting ? _sampled : null,
              ),
            ),
          ),
          if (spec.sky > .01)
            RepaintBoundary(
              child: Opacity(
                opacity: spec.sky.clamp(0.0, 1.0),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => ui.Gradient.linear(
                    rect.topCenter,
                    rect.bottomCenter,
                    const [Colors.white, Colors.white, Color(0x00FFFFFF)],
                    const [0, .42, .78],
                  ),
                  child: Image.asset(
                    V2Atmosphere.skyAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    excludeFromSemantics: true,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          // V1's flowing gradient, kept in V2: four blue light pools that
          // keep drifting across the upper sky.
          TweenAnimationBuilder<double>(
            tween: Tween(end: v2FlowingStrength(widget.mood)),
            duration: V2Motion.of(context, widget.duration),
            curve: V2Motion.drift,
            builder: (context, strength, _) => RepaintBoundary(
              child: CustomPaint(
                painter: V2FlowingLightPainter(
                  strength: strength,
                  clock: drifting ? _sampled : null,
                ),
              ),
            ),
          ),
          const RepaintBoundary(child: CustomPaint(painter: V2GrainPainter())),
          ?child,
        ],
      ),
      child: widget.child,
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.spec, {this.clock}) : super(repaint: clock);

  final V2AtmosphereSpec spec;
  final ValueListenable<double>? clock;

  /// V1's flowing light: each pool circles on its own phase. The third pool
  /// is the bright content plane, so it barely moves.
  static Offset drift(int index, double phase) {
    final t = phase * 2 * math.pi;
    return switch (index) {
      0 => Offset(.10 * math.sin(t), .06 * math.cos(t)),
      1 => Offset(.10 * math.cos(t), .06 * math.sin(t)),
      _ => Offset(.04 * math.sin(t + 1), .025 * math.cos(t + 1)),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [spec.top, spec.middle, spec.bottom],
          [0, spec.middleStop, 1],
        ),
    );
    final longest = size.longestSide;
    final phase = clock?.value;
    for (var i = 0; i < spec.lights.length; i++) {
      final light = spec.lights[i];
      if (light.alpha <= 0) continue;
      final moved = phase == null
          ? light.center
          : light.center + drift(i, phase);
      final center = Offset(moved.dx * size.width, moved.dy * size.height);
      final radius = light.radius * longest;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [
              light.color.withValues(alpha: light.alpha),
              light.color.withValues(alpha: light.alpha * .45),
              light.color.withValues(alpha: 0),
            ],
            const [0, .45, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.spec != spec || old.clock != clock;
}

/// V1's DreamAtmosphere light, without its paper base: four blue pools
/// circling on one 14s clock, fading out before the content plane. A still
/// frame ([stillPhase]) is shown when the clock is off.
@visibleForTesting
class V2FlowingLightPainter extends CustomPainter {
  V2FlowingLightPainter({
    required this.strength,
    this.clock,
    this.stillPhase = .24,
  }) : super(repaint: clock);

  final double strength;
  final ValueListenable<double>? clock;
  final double stillPhase;

  static const _sky = Color(0xFF72CBF2);
  static const _soft = Color(0xFF5A8DD8);
  static const _deep = Color(0xFF288FD4);
  static const _haze = Color(0xFFE7F7FF);

  double get phase => clock?.value ?? stillPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final amount = strength.clamp(0.0, 1.0);
    if (size.isEmpty || amount <= 0) return;
    final t = phase * 2 * math.pi;
    final bounds = Offset.zero & size;
    // Everything fades out from 40% of the height: the lower part stays the
    // calm content plane, as in V1.
    canvas.saveLayer(bounds, Paint());
    void light(double x, double y, double rx, double ry, Color c, double a) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.scale(size.width * rx, size.height * ry);
      canvas.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            1,
            [
              c.withValues(alpha: a * amount),
              c.withValues(alpha: a * amount * .55),
              c.withValues(alpha: 0),
            ],
            const [0, .38, 1],
          ),
      );
      canvas.restore();
    }

    light(.66 + .1 * math.sin(t), .17 + .06 * math.cos(t), .82, .65, _sky, .58);
    // The two deeper pools pass behind the left text column: kept light so
    // titles and meta stay readable at every phase.
    light(.12 + .1 * math.cos(t), .24 + .06 * math.sin(t), .54, .53, _soft, .2);
    light(
      .38 + .12 * math.sin(t + 1),
      .20 + .07 * math.cos(t + 1),
      .51,
      .50,
      _deep,
      .18,
    );
    light(.75 + .06 * math.cos(t + 2), .48, .54, .51, _haze, .6);
    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * .40),
          Offset(0, size.height * .78),
          const [Colors.white, Color(0x00FFFFFF)],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(V2FlowingLightPainter old) =>
      old.strength != strength ||
      old.clock != clock ||
      old.stillPhase != stillPhase;
}

/// A fine, fixed print grain that keeps gradients from banding and gives the
/// space a paper/film tooth. Deterministic and static.
class V2GrainPainter extends CustomPainter {
  const V2GrainPainter({this.opacity = 1});

  final double opacity;

  static Float32List? _points;
  static Size? _pointsSize;

  Float32List _grain(Size size) {
    if (_points != null && _pointsSize == size) return _points!;
    final random = math.Random(1729);
    final count = (size.width * size.height / 70).round().clamp(0, 24000);
    final list = Float32List(count * 2);
    for (var i = 0; i < count; i++) {
      list[i * 2] = random.nextDouble() * size.width;
      list[i * 2 + 1] = random.nextDouble() * size.height;
    }
    _pointsSize = size;
    return _points = list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final points = _grain(size);
    final half = points.length ~/ 2;
    final light = Float32List.sublistView(points, 0, half - half % 2);
    final dark = Float32List.sublistView(points, half - half % 2);
    canvas.drawRawPoints(
      ui.PointMode.points,
      light,
      Paint()
        ..color = Colors.white.withValues(alpha: .10 * opacity)
        ..strokeWidth = 1,
    );
    canvas.drawRawPoints(
      ui.PointMode.points,
      dark,
      Paint()
        ..color = const Color(0xFF1C3552).withValues(alpha: .035 * opacity)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(V2GrainPainter old) => old.opacity != opacity;
}
