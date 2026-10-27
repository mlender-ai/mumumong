// The memory swarm (DESIGN_V2.md §5.3): one set of dots that carries a dream
// from loose input to a scene. The same particles are loose while the user
// writes or speaks, gather into one memory fragment on save, split into
// elements, link, line up as sentences while the engine writes, and dissolve
// into the real text on reveal. Every transition is started by an input
// event or a real job stage; the swarm never animates on its own.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'halftone.dart' show DotBatch;
import 'tokens.dart';

enum SwarmShape { field, fragment, clusters, linked, rows, page, dissolve }

@immutable
class SwarmFormation {
  const SwarmFormation._(
    this.shape, {
    this.count = 0,
    this.center,
    this.rect,
    this.groups = 4,
    this.lines = 5,
    this.lineHeight = 24,
    this.titleGap = 58,
  });

  /// Loose dots in the capture field; [count] follows the amount written.
  const SwarmFormation.field({required int count, required Offset center})
    : this._(SwarmShape.field, count: count, center: center);

  /// One memory fragment: size grows with how much was remembered.
  const SwarmFormation.fragment({required Offset center})
    : this._(SwarmShape.fragment, center: center);

  /// Extracted elements as separate groups.
  const SwarmFormation.clusters({required Offset center, int groups = 4})
    : this._(SwarmShape.clusters, center: center, groups: groups);

  /// Groups drawn together with visible links.
  const SwarmFormation.linked({required Offset center, int groups = 4})
    : this._(SwarmShape.linked, center: center, groups: groups);

  /// Sentences being written inside [rect].
  const SwarmFormation.rows({
    required Rect rect,
    int lines = 5,
    double lineHeight = 24,
    double titleGap = 58,
  }) : this._(
         SwarmShape.rows,
         rect: rect,
         lines: lines,
         lineHeight: lineHeight,
         titleGap: titleGap,
       );

  /// Settled page being checked.
  const SwarmFormation.page({
    required Rect rect,
    int lines = 5,
    double lineHeight = 24,
    double titleGap = 58,
  }) : this._(
         SwarmShape.page,
         rect: rect,
         lines: lines,
         lineHeight: lineHeight,
         titleGap: titleGap,
       );

  /// Rows give way to the real text, line by line.
  const SwarmFormation.dissolve({
    required Rect rect,
    int lines = 5,
    double lineHeight = 24,
    double titleGap = 58,
  }) : this._(
         SwarmShape.dissolve,
         rect: rect,
         lines: lines,
         lineHeight: lineHeight,
         titleGap: titleGap,
       );

  final SwarmShape shape;
  final int count;
  final Offset? center;
  final Rect? rect;
  final int groups;
  final int lines;
  final double lineHeight;
  final double titleGap;

  /// Identity used to skip re-forming when nothing changed.
  String get signature =>
      '${shape.name}|$count|${center?.dx.round()},${center?.dy.round()}|'
      '${rect?.left.round()},${rect?.top.round()},${rect?.width.round()}|$groups|$lines';
}

class _Dot {
  _Dot(this.seed);

  final int seed;
  late final double r1, r2, r3, r4;
  Offset from = Offset.zero, to = Offset.zero, at = Offset.zero;
  double fromRadius = 0, toRadius = 0, radius = 0;
  double fromAlpha = 0, toAlpha = 0, alpha = 0;

  /// 0 = sky, 1 = ink.
  double fromTone = 0, toTone = 0, tone = 0;
  double start = 0, duration = 0;
  int group = 0;
  bool live = false;
}

class MemorySwarm extends ChangeNotifier {
  MemorySwarm({
    required TickerProvider vsync,
    this.capacity = 180,
    int seed = 11,
  }) : _dots = List.generate(capacity, (i) => _Dot(i)) {
    final random = math.Random(seed);
    for (final dot in _dots) {
      dot
        ..r1 = random.nextDouble()
        ..r2 = random.nextDouble()
        ..r3 = random.nextDouble()
        ..r4 = random.nextDouble();
    }
    _ticker = vsync.createTicker(_tick);
  }

  final int capacity;
  final List<_Dot> _dots;
  late final Ticker _ticker;
  double _time = 0, _base = 0;
  Size _size = Size.zero;
  SwarmFormation? _formation;
  int _visible = 0;
  double _level = 0, _targetLevel = 0;
  double _links = 0, _linksFrom = 0, _linksTo = 0;
  double _sweep = -1;
  double _sweepStart = 0;
  bool reduced = false;
  bool _disposed = false;

  SwarmFormation? get formation => _formation;
  int get visible => _visible;
  double get level => _level;
  bool get animating => _ticker.isActive;

  /// Dots a dream of [characters] characters leaves in the field.
  /// An empty field keeps a few waiting dots so the space reads as ready.
  static int dotsForText(int characters, {int capacity = 180}) =>
      (7 + characters * .9).round().clamp(0, capacity);

  void resize(Size size) {
    if (size == _size || size.isEmpty) return;
    final first = _size.isEmpty;
    _size = size;
    final formation = _formation;
    if (formation != null) _apply(formation, jump: true);
    if (!first) notifyListeners();
  }

  /// Voice energy from the real speech level (rms), 0..1.
  void setLevel(double level) {
    _targetLevel = level.clamp(0.0, 1.0);
    if (reduced) {
      _level = _targetLevel;
      notifyListeners();
      return;
    }
    _ensureTicking();
  }

  /// Sets how many memory dots exist without moving them, e.g. for a saved
  /// dream reopened from the archive.
  void seed(int count) {
    _visible = count.clamp(0, capacity);
  }

  void form(
    SwarmFormation formation, {
    Duration duration = V2Motion.gather,
    double stagger = .35,
  }) {
    final previous = _formation;
    if (previous?.signature == formation.signature) return;
    _formation = formation;
    if (formation.shape == SwarmShape.field) {
      if (_size.isEmpty) _visible = formation.count.clamp(0, capacity);
    }
    if (_size.isEmpty) return;
    if (formation.shape == SwarmShape.field &&
        previous?.shape == SwarmShape.field) {
      if ((previous!.center! - formation.center!).distance < 2) {
        _grow(formation);
      } else {
        _apply(formation, duration: V2Motion.page, stagger: .2);
      }
      return;
    }
    _apply(formation, duration: duration, stagger: stagger);
  }

  void _grow(SwarmFormation formation) {
    final next = formation.count.clamp(0, capacity);
    final center = formation.center!;
    for (var i = 0; i < capacity; i++) {
      final dot = _dots[i];
      final home = _fieldHome(dot, center);
      if (i < next && !dot.live) {
        // A new memory dot rises from the writing line into the field.
        _retarget(
          dot,
          from: Offset(
            center.dx + (dot.r2 - .5) * 60,
            center.dy + _size.height * .22,
          ),
          to: home,
          fromRadius: 0,
          toRadius: _fieldRadius(dot),
          fromAlpha: 0,
          toAlpha: _fieldAlpha(dot),
          tone: _fieldTone(dot),
          start: _time + (i - _visible).clamp(0, 12) * .025,
          duration: .62,
        );
        dot.live = true;
      } else if (i >= next && dot.live) {
        _retarget(
          dot,
          from: dot.at,
          to: Offset(dot.at.dx, dot.at.dy + 18),
          fromRadius: dot.radius,
          toRadius: 0,
          fromAlpha: dot.alpha,
          toAlpha: 0,
          tone: dot.tone,
          start: _time,
          duration: .32,
        );
        dot.live = false;
      }
    }
    _visible = next;
    if (reduced) {
      notifyListeners();
    } else {
      _ensureTicking();
    }
  }

  void _apply(
    SwarmFormation formation, {
    bool jump = false,
    Duration duration = V2Motion.gather,
    double stagger = .35,
  }) {
    final seconds = jump || reduced ? 0.0 : duration.inMilliseconds / 1000;
    if (formation.shape == SwarmShape.field) {
      _visible = formation.count.clamp(0, capacity);
    }
    final n = _visible;
    final targets = _targets(formation, n);
    for (var i = 0; i < capacity; i++) {
      final dot = _dots[i];
      if (i >= n) {
        dot.live = false;
        dot
          ..alpha = 0
          ..toAlpha = 0
          ..radius = 0
          ..toRadius = 0
          ..duration = 0;
        continue;
      }
      final target = targets[i];
      final delay = seconds * stagger * target.$5;
      _retarget(
        dot,
        from: jump || !dot.live ? target.$1 : dot.at,
        to: target.$1,
        fromRadius: jump || !dot.live ? target.$2 : dot.radius,
        toRadius: target.$2,
        fromAlpha: jump || !dot.live ? target.$3 : dot.alpha,
        toAlpha: target.$3,
        tone: target.$4,
        start: _time + delay,
        duration: seconds * (1 - stagger),
      );
      dot.live = true;
    }
    final linked = formation.shape == SwarmShape.linked;
    _linksFrom = _links;
    _linksTo = linked ? 1 : 0;
    if (formation.shape == SwarmShape.page && !jump && !reduced) {
      _sweepStart = _time + seconds * .55;
      _sweep = 0;
    } else if (formation.shape != SwarmShape.page) {
      _sweep = -1;
    }
    if (seconds == 0) {
      _links = _linksTo;
      _settleAll();
      notifyListeners();
    } else {
      _ensureTicking();
    }
  }

  void _retarget(
    _Dot dot, {
    required Offset from,
    required Offset to,
    required double fromRadius,
    required double toRadius,
    required double fromAlpha,
    required double toAlpha,
    required double tone,
    required double start,
    required double duration,
  }) {
    dot
      ..from = from
      ..to = to
      ..fromRadius = fromRadius
      ..toRadius = toRadius
      ..fromAlpha = fromAlpha
      ..toAlpha = toAlpha
      ..fromTone = dot.tone
      ..toTone = tone
      ..start = start
      ..duration = duration;
    if (duration <= 0 || reduced) {
      dot
        ..at = to
        ..radius = toRadius
        ..alpha = toAlpha
        ..tone = tone;
    }
  }

  void _settleAll() {
    for (final dot in _dots) {
      dot
        ..at = dot.to
        ..radius = dot.toRadius
        ..alpha = dot.toAlpha
        ..tone = dot.toTone;
    }
  }

  // Target: (position, radius, alpha, tone, stagger order 0..1).
  List<(Offset, double, double, double, double)> _targets(
    SwarmFormation formation,
    int n,
  ) {
    final out = <(Offset, double, double, double, double)>[];
    final w = _size.width, h = _size.height;
    switch (formation.shape) {
      case SwarmShape.field:
        final c = formation.center!;
        for (var i = 0; i < n; i++) {
          final dot = _dots[i];
          out.add((
            _fieldHome(dot, c),
            _fieldRadius(dot),
            _fieldAlpha(dot),
            _fieldTone(dot),
            dot.r3,
          ));
        }
      case SwarmShape.fragment:
        final c = formation.center!;
        const pitch = 4.3;
        for (var i = 0; i < n; i++) {
          final angle = i * 2.39996;
          final base = pitch * math.sqrt(i + .5);
          final torn =
              1 + .20 * math.sin(3 * angle + 1.3) + .09 * math.sin(5 * angle);
          final p = Offset(
            c.dx + math.cos(angle) * base * torn * 1.25,
            c.dy + math.sin(angle) * base * torn * .9,
          );
          out.add((
            p,
            2.0 + _dots[i].r1 * .5,
            .95,
            .82,
            1 - i / math.max(1, n),
          ));
        }
      case SwarmShape.clusters || SwarmShape.linked:
        final c = formation.center!;
        final k = formation.groups.clamp(2, 7);
        final linked = formation.shape == SwarmShape.linked;
        final rx = w * (linked ? .22 : .30), ry = h * (linked ? .085 : .12);
        final counts = List.filled(k, 0);
        for (var i = 0; i < n; i++) {
          final g = i % k;
          _dots[i].group = g;
          final angle = g / k * math.pi * 2 - math.pi / 2 + .35;
          final wobble = (g.isEven ? 1 : -1) * .18;
          final gc = Offset(
            c.dx + math.cos(angle) * rx * (1 + wobble * .4),
            c.dy + math.sin(angle) * ry * (1 - wobble * .3),
          );
          final j = counts[g]++;
          final a = j * 2.39996;
          final rr = 4.6 * math.sqrt(j + .5);
          out.add((
            gc + Offset(math.cos(a) * rr, math.sin(a) * rr),
            2.1 + _dots[i].r2 * .4,
            .92,
            g.isEven ? .78 : .55,
            g / k * .6 + _dots[i].r3 * .4,
          ));
        }
      case SwarmShape.rows || SwarmShape.page || SwarmShape.dissolve:
        final rect = formation.rect!;
        final lines = formation.lines.clamp(2, 8);
        final slots = <(Offset, double, int)>[];
        // A title line, then a ragged paragraph: the shape of a scene.
        const lengths = [.58, 1.0, .95, .99, .91, .97, .72, .88];
        final titleY = rect.top + 14;
        final bodyTop = rect.top + formation.titleGap;
        final lineGap = formation.lineHeight;
        var total = 0.0;
        final spans = <(double, double, double, int)>[]; // y, x0, x1, line
        for (var l = 0; l < lines; l++) {
          final y = l == 0 ? titleY : bodyTop + (l - 1) * lineGap;
          final length = rect.width * lengths[l % lengths.length];
          spans.add((y, rect.left, rect.left + length, l));
          total += length;
        }
        for (var i = 0; i < n; i++) {
          var s = (i + .5) / n * total;
          for (final span in spans) {
            final length = span.$3 - span.$2;
            if (s <= length) {
              slots.add((Offset(span.$2 + s, span.$1), length, span.$4));
              break;
            }
            s -= length;
          }
        }
        final page = formation.shape == SwarmShape.page;
        final dissolve = formation.shape == SwarmShape.dissolve;
        for (var i = 0; i < n; i++) {
          final slot = slots[math.min(i, slots.length - 1)];
          final title = slot.$3 == 0;
          final jitter = page || dissolve ? 0.0 : 1.6;
          final p =
              slot.$1 +
              Offset(
                (_dots[i].r1 - .5) * jitter,
                (_dots[i].r2 - .5) * jitter * 1.6,
              );
          final along = ((slot.$1.dx - rect.left) / rect.width).clamp(0.0, 1.0);
          final order = slot.$3 / lines * .7 + along * .3;
          out.add((
            dissolve ? p.translate(0, -5) : p,
            dissolve ? 0 : (title ? 2.7 : 1.85),
            dissolve ? 0 : .95,
            page ? 1 : .9,
            order,
          ));
        }
    }
    return out;
  }

  /// The field is a growing halftone patch, not a scatter: dots fill a
  /// sunflower lattice outward from the center, larger and darker inside,
  /// finer at the frayed edge. More remembered → a larger, denser patch.
  Offset _fieldHome(_Dot dot, Offset center) {
    final i = dot.seed;
    final angle = i * 2.39996;
    final r = 6.6 * math.sqrt(i + .5);
    final x = center.dx + math.cos(angle) * r * 1.42 + (dot.r1 - .5) * 2.4;
    final y = center.dy + math.sin(angle) * r * .82 + (dot.r2 - .5) * 2.4;
    return Offset(
      x.clamp(12, _size.width - 12),
      y.clamp(12, _size.height - 12),
    );
  }

  double _fieldRadius(_Dot dot) {
    final edge = (dot.seed / capacity).clamp(0.0, 1.0);
    return 2.7 - edge * 1.5 + dot.r3 * .5;
  }

  double _fieldAlpha(_Dot dot) =>
      .92 - (dot.seed / capacity).clamp(0.0, 1.0) * .35 - dot.r4 * .1;
  double _fieldTone(_Dot dot) =>
      dot.seed < 36 ? (dot.r4 < .7 ? .62 : .2) : (dot.r4 < .3 ? .55 : .14);

  void _ensureTicking() {
    if (_disposed || _ticker.isActive) return;
    _base = _time;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    _time = _base + elapsed.inMicroseconds / 1e6;
    var moving = false;
    for (final dot in _dots) {
      if (dot.duration <= 0) continue;
      final t = ((_time - dot.start) / dot.duration).clamp(0.0, 1.0);
      if (t < 1) moving = true;
      final e = V2Motion.settle.transform(t);
      dot
        ..at = Offset.lerp(dot.from, dot.to, e)!
        ..radius = dot.fromRadius + (dot.toRadius - dot.fromRadius) * e
        ..alpha = dot.fromAlpha + (dot.toAlpha - dot.fromAlpha) * e
        ..tone = dot.fromTone + (dot.toTone - dot.fromTone) * e;
      if (t >= 1) dot.duration = 0;
    }
    if (_links != _linksTo) {
      _links += (_linksTo - _linksFrom) * .04;
      if ((_linksTo - _links).abs() < .04 ||
          (_linksTo > _linksFrom ? _links > _linksTo : _links < _linksTo)) {
        _links = _linksTo;
      } else {
        moving = true;
      }
    }
    if (_sweep >= 0) {
      final t = ((_time - _sweepStart) / .9).clamp(0.0, 1.0);
      if (_time >= _sweepStart) _sweep = t;
      if (t < 1) {
        moving = true;
      } else {
        _sweep = -1;
      }
    }
    if ((_level - _targetLevel).abs() > .002) {
      _level += (_targetLevel - _level) * .22;
      moving = true;
    } else {
      _level = _targetLevel;
    }
    notifyListeners();
    if (!moving) _ticker.stop();
  }

  void paint(Canvas canvas, Size size) {
    final sky = DotBatch(), mid = DotBatch(), ink = DotBatch();
    final faint = DotBatch();
    final formation = _formation;
    final field = formation?.shape == SwarmShape.field;
    final center = formation?.center ?? size.center(Offset.zero);
    final groupSums = <int, Offset>{};
    final groupCounts = <int, int>{};
    final rect = formation?.rect;
    for (final dot in _dots) {
      if (dot.alpha <= .01 || dot.radius <= .2) continue;
      var p = dot.at;
      var r = dot.radius;
      if (field && _level > 0) {
        // Voice pushes the memory outward with the speaker's real level.
        final d = p - center;
        final len = d.distance + .001;
        final push = _level * (4 + dot.r3 * 13);
        p += d / len * push;
        r *= 1 + _level * .35 * dot.r1;
      }
      var tone = dot.tone;
      if (_sweep >= 0 && rect != null) {
        final x = rect.left + rect.width * _sweep;
        final near = math.exp(-math.pow((p.dx - x) / 26, 2).toDouble());
        tone -= near * .9;
        r *= 1 + near * .3;
      }
      if (formation?.shape == SwarmShape.linked ||
          formation?.shape == SwarmShape.clusters) {
        groupSums[dot.group] = (groupSums[dot.group] ?? Offset.zero) + p;
        groupCounts[dot.group] = (groupCounts[dot.group] ?? 0) + 1;
      }
      final effective = r * math.sqrt(dot.alpha.clamp(0.0, 1.0));
      if (dot.alpha < .35) {
        faint.add(p.dx, p.dy, effective);
      } else if (tone < .33) {
        sky.add(p.dx, p.dy, effective);
      } else if (tone < .7) {
        mid.add(p.dx, p.dy, effective);
      } else {
        ink.add(p.dx, p.dy, effective);
      }
    }
    if (_links > 0 && groupSums.length > 1) {
      final centers = [
        for (final g in groupSums.keys.toList()..sort())
          groupSums[g]! / groupCounts[g]!.toDouble(),
      ];
      final paint = Paint()
        ..color = V2Color.sky500.withValues(alpha: .38 * _links)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < centers.length; i++) {
        final a = centers[i], b = centers[(i + 1) % centers.length];
        canvas.drawLine(a, Offset.lerp(a, b, _links)!, paint);
      }
    }
    faint.draw(canvas, Paint()..color = V2Color.sky500.withValues(alpha: .35));
    sky.draw(canvas, Paint()..color = V2Color.sky500.withValues(alpha: .9));
    mid.draw(canvas, Paint()..color = V2Color.sky700.withValues(alpha: .92));
    ink.draw(canvas, Paint()..color = V2Color.inkDot.withValues(alpha: .94));
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    super.dispose();
  }
}

/// Paints a [MemorySwarm] and reports its canvas size to it.
class MemorySwarmView extends StatelessWidget {
  const MemorySwarmView({super.key, required this.swarm});

  final MemorySwarm swarm;

  @override
  Widget build(BuildContext context) {
    swarm.reduced = V2Motion.reduced(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        swarm.resize(constraints.biggest);
        return RepaintBoundary(
          child: CustomPaint(
            size: constraints.biggest,
            painter: _SwarmPainter(swarm),
          ),
        );
      },
    );
  }
}

class _SwarmPainter extends CustomPainter {
  _SwarmPainter(this.swarm) : super(repaint: swarm);

  final MemorySwarm swarm;

  @override
  void paint(Canvas canvas, Size size) => swarm.paint(canvas, size);

  @override
  bool shouldRepaint(_SwarmPainter old) => old.swarm != swarm;
}
