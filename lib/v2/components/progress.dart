// V2 progress (DESIGN_V2.md §7.5). Progress is always drawn in dots that
// mean something: filled dots are written material, sky dots are what the
// latest dream added, rings are what is still unwritten.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../design/halftone.dart';
import '../design/tokens.dart';

class V2DotProgress extends StatelessWidget {
  const V2DotProgress({
    super.key,
    required this.value,
    this.recent = 0,
    this.dots = 36,
    this.semanticsLabel,
  });

  /// Real ratio 0..1.
  final double value;

  /// Portion of [value] added by the latest event (shown in sky).
  final double recent;
  final int dots;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? '원고 ${(value * 100).round()}%',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: V2Motion.of(context, V2Motion.growth),
        curve: V2Motion.settle,
        builder: (context, shown, _) => SizedBox(
          height: 10,
          child: CustomPaint(
            size: const Size(double.infinity, 10),
            painter: _DotProgressPainter(
              value: shown,
              recent: recent.clamp(0.0, shown),
              dots: dots,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotProgressPainter extends CustomPainter {
  const _DotProgressPainter({
    required this.value,
    required this.recent,
    required this.dots,
  });

  final double value;
  final double recent;
  final int dots;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / dots;
    final r = math.min(gap * .26, 3.4);
    final filled = value * dots;
    final recentFrom = (value - recent) * dots;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = V2Color.ink3.withValues(alpha: .38);
    for (var i = 0; i < dots; i++) {
      final c = Offset(gap * (i + .5), size.height / 2);
      final fill = (filled - i).clamp(0.0, 1.0);
      if (fill <= 0) {
        canvas.drawCircle(c, r * .82, ring);
        continue;
      }
      final isRecent = i + .5 >= recentFrom;
      final color = isRecent && recent > 0 ? V2Color.sky500 : V2Color.inkDot;
      canvas.drawCircle(c, r * (.6 + .4 * fill), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_DotProgressPainter old) =>
      old.value != value || old.recent != recent || old.dots != dots;
}

/// Segmented step progress (Reference: segmented header). Used for real
/// steps only: recall questions, engine stages.
class V2StepProgress extends StatelessWidget {
  const V2StepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.semanticsLabel,
  });

  final int steps;

  /// Completed steps plus the fraction of the current one, 0..steps.
  final double current;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? '${current.floor().clamp(0, steps)} / $steps 단계',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: current.clamp(0.0, steps.toDouble())),
        duration: V2Motion.of(context, V2Motion.stage),
        curve: V2Motion.settle,
        builder: (context, value, _) => Row(
          children: [
            for (var i = 0; i < steps; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _Segment(fill: (value - i).clamp(0.0, 1.0))),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fill});
  final double fill;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 7,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: V2Color.ink.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fill,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [V2Color.sky300, V2Color.sky600],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The manuscript object: a halftone print whose dots are the volume's real
/// material. Growth flies new dots in from below once per fresh event.
class V2Manuscript extends StatefulWidget {
  const V2Manuscript({
    super.key,
    required this.motif,
    required this.seed,
    required this.progress,
    this.growFrom,
    this.growthKey,
    this.assemble = false,
    this.interactive = false,
    this.columns = 34,
    this.onGrowthDone,
    this.semanticsLabel,
  });

  final V2Motif motif;
  final int seed;
  final double progress;

  /// Progress before the fresh event to animate, or null.
  final double? growFrom;

  /// Identity of the growth event; a new key replays growth once.
  final Object? growthKey;
  final bool assemble;
  final bool interactive;
  final int columns;
  final VoidCallback? onGrowthDone;
  final String? semanticsLabel;

  @override
  State<V2Manuscript> createState() => _V2ManuscriptState();
}

class _V2ManuscriptState extends State<V2Manuscript>
    with TickerProviderStateMixin {
  late final AnimationController _growth = AnimationController(
    vsync: this,
    duration: V2Motion.growth,
    value: 1,
  );
  late final AnimationController _assemble = AnimationController(
    vsync: this,
    duration: V2Motion.assemble,
    value: 1,
  );
  late final AnimationController _push = AnimationController.unbounded(
    vsync: this,
  );
  final _touch = ValueNotifier<V2Touch?>(null);
  Offset _touchAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _growth.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onGrowthDone?.call();
    });
    _push.addListener(() {
      _touch.value = V2Touch(_touchAt, _push.value.clamp(0.0, 1.5));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.assemble && !V2Motion.reduced(context)) {
        _assemble.forward(from: 0);
      }
      _maybeGrow(null);
    });
  }

  @override
  void didUpdateWidget(covariant V2Manuscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.growthKey != oldWidget.growthKey) {
      _maybeGrow(oldWidget.growthKey);
    }
  }

  void _maybeGrow(Object? previousKey) {
    if (widget.growFrom == null || widget.growthKey == null) return;
    if (V2Motion.reduced(context)) {
      _growth.value = 1;
      widget.onGrowthDone?.call();
      return;
    }
    _growth.forward(from: 0);
  }

  @override
  void dispose() {
    _growth.dispose();
    _assemble.dispose();
    _push.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _touchMove(Offset at) {
    _touchAt = at;
    if (_push.value < 1) {
      _push.animateTo(1, duration: V2Motion.quick, curve: V2Motion.settle);
    } else {
      _touch.value = V2Touch(at, _push.value);
    }
  }

  void _release() {
    _push.animateWith(SpringSimulation(V2Motion.release, _push.value, 0, 0));
  }

  @override
  Widget build(BuildContext context) {
    final field = HalftoneField.of(
      motif: widget.motif,
      seed: widget.seed,
      columns: widget.columns,
    );
    final growing = widget.growFrom != null && widget.growthKey != null;
    Widget paint = CustomPaint(
      painter: HalftonePainter(
        field: field,
        progress: widget.progress,
        fromProgress: growing ? widget.growFrom : null,
        growth: _growth,
        assemble: _assemble,
        touch: widget.interactive ? _touch : null,
      ),
      child: const SizedBox.expand(),
    );
    if (widget.interactive && !V2Motion.reduced(context)) {
      // Raw pointers so the push follows the finger without competing with
      // page or scroll gestures; horizontal drags stay on the object so a
      // playful touch never turns the onboarding page by accident.
      paint = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _touchMove(e.localPosition),
        onPointerMove: (e) => _touchMove(e.localPosition),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {},
          onHorizontalDragUpdate: (_) {},
          child: paint,
        ),
      );
    }
    return Semantics(
      image: true,
      label:
          widget.semanticsLabel ??
          '원고 형상, ${(widget.progress * 100).round()}% 쌓임',
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: RepaintBoundary(child: paint),
      ),
    );
  }
}

/// Completion Reveal (brief §6E). The finished manuscript is printed at the
/// capped clarity with its afterimage and frayed contour; a few loose dots
/// keep drifting out of the frame toward the next dream.
class V2CompletionReveal extends StatelessWidget {
  const V2CompletionReveal({
    super.key,
    required this.motif,
    required this.seed,
    this.playKey,
  });

  final V2Motif motif;
  final int seed;

  /// When set, the last stretch of clarity prints once on mount.
  final Object? playKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              V2Manuscript(
                motif: motif,
                seed: seed,
                progress: 1,
                growFrom: playKey == null ? null : .82,
                growthKey: playKey,
                semanticsLabel: '완성된 원고의 형상',
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _LooseDotsPainter()),
                ),
              ),
            ],
          ),
          const SizedBox(height: V2Space.lg),
          const Text('더 선명해졌지만,\n완전히 선명하지는 않아요.', style: V2Type.title),
          const SizedBox(height: V2Space.xs),
          const Text(
            'Clearer, but never completely clear.',
            style: V2Type.meta,
          ),
          const SizedBox(height: V2Space.sm),
          const Text('완결은 끝이 아니라, 다음 꿈이 시작될 자리예요.', style: V2Type.bodySmall),
        ],
      ),
    );
  }
}

class _LooseDotsPainter extends CustomPainter {
  const _LooseDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 14; i++) {
      final t = i / 13;
      // A loose trail leaving the lower right edge of the print.
      final x = size.width * (.78 + t * .26) + (random.nextDouble() - .5) * 18;
      final y = size.height * (.70 + t * .34) + (random.nextDouble() - .5) * 22;
      paint.color = V2Color.sky500.withValues(alpha: .75 - t * .5);
      canvas.drawCircle(Offset(x, y), 2.6 - t * 1.4, paint);
    }
  }

  @override
  bool shouldRepaint(_LooseDotsPainter old) => false;
}
