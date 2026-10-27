// The manuscript as a halftone image, per DESIGN_V2.md §5. Each dot is a unit of
// remembered material. Real progress decides how many dots are present and
// how clearly the image reads; clarity is capped below 1, a sky afterimage
// never resolves and the contour stays incomplete. Clearer, but never
// completely clear.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Real objects remembered imperfectly. No moon, stars or space (brief §4).
enum V2Motif { door, window, stairs, umbrella, horizon }

V2Motif motifFor({String? coverMotifId, required String volumeId}) {
  final id = (coverMotifId ?? '').toLowerCase();
  if (id.contains('door')) return V2Motif.door;
  if (id.contains('window')) return V2Motif.window;
  if (id.contains('stair')) return V2Motif.stairs;
  if (id.contains('umbrella') || id.contains('rain')) return V2Motif.umbrella;
  if (id.contains('sea') || id.contains('horizon') || id.contains('shore')) {
    return V2Motif.horizon;
  }
  return V2Motif.values[_hash(volumeId) % V2Motif.values.length];
}

int v2Seed(String id) => _hash(id);

int _hash(String value) {
  var h = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

double _fract(double x) => x - x.floorToDouble();
double _rand(double x, double y) =>
    _fract(math.sin(x * 127.1 + y * 311.7) * 43758.5453);
double _smooth(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _noise(double x, double y) {
  final ix = x.floorToDouble(), iy = y.floorToDouble();
  final fx = x - ix, fy = y - iy;
  final ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy);
  final a = _rand(ix, iy), b = _rand(ix + 1, iy);
  final c = _rand(ix, iy + 1), d = _rand(ix + 1, iy + 1);
  return a + (b - a) * ux + (c - a) * uy + (a - b - c + d) * ux * uy;
}

/// Soft inside-test for an axis-aligned box; 1 inside, 0 outside.
double _box(
  double u,
  double v,
  double l,
  double t,
  double r,
  double b, [
  double soft = .006,
]) =>
    _smooth(l - soft, l + soft, u) *
    (1 - _smooth(r - soft, r + soft, u)) *
    _smooth(t - soft, t + soft, v) *
    (1 - _smooth(b - soft, b + soft, v));

/// Darkness 0..1 of [motif] at (u, v), both 0..1 over a 4:5 page.
double motifDensity(V2Motif motif, double u, double v) {
  final grain = (_noise(u * 9, v * 9) - .5) * .08;
  switch (motif) {
    case V2Motif.door:
      // A corridor wall, a closed door left ajar by a slit of light, and
      // shallow water on the floor carrying the door's reflection.
      const horizon = .70;
      var d = .09 + v * .07 + grain;
      final door = _box(u, v, .34, .16, .66, horizon);
      final frame = _box(u, v, .325, .148, .675, horizon) - door;
      d = d * (1 - frame) + .58 * frame;
      final panel = .80 - (v - .16) * .18;
      final insets =
          _box(u, v, .385, .22, .615, .40, .004) +
          _box(u, v, .385, .45, .615, .66, .004);
      d = d * (1 - door) + (panel - insets * .10) * door;
      d += _box(u, v, .392, .44, .408, .462, .004) * .2;
      final slit = math.exp(-math.pow((u - .628) / .016, 2).toDouble());
      if (v > .16 && v < horizon) d -= slit * .72 * door + slit * .18;
      if (v >= horizon) {
        final depth = (v - horizon) / (1 - horizon);
        final ripple = math.sin(v * 92 + _noise(u * 4, v * 6) * 5) * .07;
        var floor = .26 + depth * .10 + ripple + grain;
        final mirrorV = horizon - (v - horizon) * 1.25;
        final wobble = math.sin(v * 140) * .008;
        final reflection = _box(u + wobble, mirrorV, .34, .16, .66, horizon);
        floor = floor * (1 - reflection * .55) + .66 * reflection * .55;
        final streak = math.exp(
          -math.pow((u + wobble - .628) / .02, 2).toDouble(),
        );
        floor -= streak * .34 * (1 - depth * .6);
        d = floor;
      }
      d += math.exp(-math.pow((v - horizon) / .006, 2).toDouble()) * .25;
      return d.clamp(0.0, 1.0);
    case V2Motif.window:
      var d = .17 + v * .06 + grain;
      final pane = _box(u, v, .22, .14, .78, .62);
      final sky = .05 + v * .08 + (_noise(u * 5, v * 3) - .5) * .06;
      d = d * (1 - pane) + sky * pane;
      final bars =
          math.exp(-math.pow((u - .5) / .007, 2).toDouble()) +
          math.exp(-math.pow((v - .38) / .007, 2).toDouble());
      d += bars * pane * .62;
      final frame = _box(u, v, .205, .125, .795, .635) - pane;
      d = d * (1 - frame) + .62 * frame;
      final curtain = _box(u, v, .60, .09, .82, .74, .01);
      final folds = .34 + math.sin(u * 64) * .12 + (v - .09) * .08;
      d = d * (1 - curtain) + folds * curtain;
      final sill = _box(u, v, .19, .62, .81, .648);
      d = d * (1 - sill) + .66 * sill;
      if (v > .70) {
        final patchL = .26 + (v - .70) * .45, patchR = .62 + (v - .70) * .55;
        final patch = _box(u, v, patchL, .72, patchR, .95, .02);
        d = (.42 + grain) * (1 - patch) + .10 * patch;
      }
      return d.clamp(0.0, 1.0);
    case V2Motif.stairs:
      var d = .08 + grain;
      const steps = 7;
      for (var i = 0; i < steps; i++) {
        final top = .22 + i * .095;
        final left = .08 + i * .085;
        final tread = _box(u, v, left, top, .96, top + .028, .004);
        final riser = _box(u, v, left, top + .028, .96, top + .095, .004);
        d = d * (1 - tread) + (.24 + i * .02) * tread;
        d = d * (1 - riser) + (.58 + i * .025) * riser;
      }
      final rail = (v - (.12 + (u - .05) * .82)).abs();
      if (u > .05 && u < .92) {
        d += math.exp(-math.pow(rail / .008, 2).toDouble()) * .55;
      }
      final light = math.exp(
        -(math.pow((u - .18) / .3, 2) + math.pow((v - .1) / .25, 2)).toDouble(),
      );
      d -= light * .14;
      return d.clamp(0.0, 1.0);
    case V2Motif.umbrella:
      var d = .06 + v * .06 + grain;
      final rain = math.sin((u * 1.0 + v * .32) * 120) > .965 ? .16 : 0.0;
      d += rain * (1 - _smooth(.74, .80, v));
      final cx = .5, cy = .40;
      final ex = (u - cx) / .34, ey = (v - cy) / .20;
      final canopy = ey < 0 && ex * ex + ey * ey < 1 ? 1.0 : 0.0;
      final scallop =
          v > cy - .01 && v < cy + .02 + math.sin((u - cx) * 30).abs() * -.015
          ? (ex.abs() < 1 ? 1.0 : 0.0)
          : 0.0;
      final ribs = math.cos(math.atan2(v - cy, u - cx) * 8).abs() > .985
          ? .14
          : 0.0;
      d = d * (1 - canopy) + (.80 - ribs - (v - .2) * .2) * canopy;
      d = d * (1 - scallop) + .72 * scallop;
      final handle = _box(u, v, .495, .40, .508, .70, .003);
      d = d * (1 - handle) + .82 * handle;
      final hook =
          ((math.sqrt(math.pow(u - .478, 2) + math.pow(v - .70, 2)) - .022)
                      .abs() <
                  .006 &&
              v > .70)
          ? .8
          : 0.0;
      d = math.max(d, hook);
      if (v > .80) {
        final puddle = math.exp(
          -(math.pow((u - .5) / .26, 2) + math.pow((v - .88) / .05, 2))
              .toDouble(),
        );
        d = d * (1 - puddle * .6) + .5 * puddle * .6;
      }
      return d.clamp(0.0, 1.0);
    case V2Motif.horizon:
      const line = .56;
      var d = v < line
          ? .02 + v * .12 + (_noise(u * 3, v * 7) - .5) * .06
          : .30 +
                (v - line) * .26 +
                math.sin(v * 70 + _noise(u * 6, v * 2) * 4) * .08;
      d += grain;
      d += math.exp(-math.pow((v - line) / .005, 2).toDouble()) * .3;
      final figure =
          _box(u, v, .305, .62, .325, .76, .004) +
          (math.sqrt(math.pow(u - .315, 2) + math.pow(v - .605, 2)) < .016
              ? 1
              : 0);
      d = d * (1 - figure.clamp(0.0, 1.0)) + .86 * figure.clamp(0.0, 1.0);
      final glare = math.exp(
        -(math.pow((u - .66) / .05, 2) + math.pow((v - .62) / .14, 2))
            .toDouble(),
      );
      if (v > line) d -= glare * .3;
      return d.clamp(0.0, 1.0);
  }
}

@immutable
class HalftoneCell {
  const HalftoneCell({
    required this.u,
    required this.v,
    required this.density,
    required this.soft,
    required this.rank,
    required this.jx,
    required this.jy,
    required this.sx,
    required this.sy,
    required this.edge,
    required this.drop,
    required this.delay,
  });

  final double u, v, density, soft, rank, jx, jy, sx, sy, edge, drop, delay;
}

/// A precomputed hex halftone grid for one motif and seed.
class HalftoneField {
  HalftoneField._(
    this.motif,
    this.columns,
    this.rows,
    this.aspect,
    this.cells,
    this.mean,
  );

  static final Map<String, HalftoneField> _cache = {};

  factory HalftoneField.of({
    required V2Motif motif,
    required int seed,
    int columns = 30,
    double aspect = 1.25,
  }) {
    final key = '${motif.name}|$seed|$columns|$aspect';
    return _cache.putIfAbsent(key, () {
      final pitchU = 1 / columns;
      final pitchV = pitchU * math.sqrt(3) / 2 / aspect;
      final rows = (1 / pitchV).floor();
      final random = math.Random(seed);
      final cells = <HalftoneCell>[];
      var sum = 0.0;
      for (var row = 0; row < rows; row++) {
        final offset = row.isOdd ? pitchU / 2 : 0.0;
        for (var col = 0; col < columns; col++) {
          final u = (col + .5) * pitchU + offset;
          if (u > 1) continue;
          final v = (row + .5) * pitchV;
          // Light pre-blur so the print never shows hard geometry.
          var density = 0.0;
          for (final (du, dv) in const [
            (0.0, 0.0),
            (.6, 0.0),
            (-.6, 0.0),
            (0.0, .6),
            (0.0, -.6),
          ]) {
            density += motifDensity(motif, u + du * pitchU, v + dv * pitchV);
          }
          density /= 5;
          // A wide blur of the same image: what a faint memory looks like.
          var soft = 0.0;
          for (var k = 0; k < 12; k++) {
            final a = k / 12 * math.pi * 2;
            soft += motifDensity(
              motif,
              u + math.cos(a) * pitchU * 3.2,
              v + math.sin(a) * pitchV * 3.2,
            );
          }
          soft = (soft / 12 + density) / 2;
          // Irregular contour: the memory frays toward its edges.
          final ex = (u - .5) / .58, ey = (v - .5) / .60;
          final reach = 1 - math.sqrt(ex * ex + ey * ey);
          final fray = (_noise(u * 6 + seed % 13, v * 6) - .5) * .16;
          final inset = math.min(math.min(u, 1 - u), math.min(v, 1 - v));
          final edge = _smooth(0, .30, reach + fray) * _smooth(0, .05, inset);
          final r = random.nextDouble();
          final angle = random.nextDouble() * math.pi * 2;
          final scatterRadius = .45 + random.nextDouble() * .55;
          cells.add(
            HalftoneCell(
              u: u,
              v: v,
              density: density,
              soft: soft,
              // Every cell can arrive early; darker (more meaningful) cells a
              // little sooner, so an empty manuscript is an even, formless grain.
              rank: (r * (.72 + .28 * (1 - density))).clamp(0.0, .9999),
              jx: math.cos(angle),
              jy: math.sin(angle),
              sx: .5 + math.cos(angle) * scatterRadius * .9,
              sy: .5 + math.sin(angle) * scatterRadius * 1.1,
              edge: edge,
              drop: random.nextDouble(),
              delay: random.nextDouble() * .55,
            ),
          );
          sum += density;
        }
      }
      return HalftoneField._(
        motif,
        columns,
        rows,
        aspect,
        cells,
        sum / cells.length,
      );
    });
  }

  final V2Motif motif;
  final int columns;
  final int rows;
  final double aspect;
  final List<HalftoneCell> cells;
  final double mean;
}

double halftonePresence(double progress) =>
    V2Dot.minPresence +
    (1 - V2Dot.minPresence) * math.pow(progress.clamp(0.0, 1.0), .8).toDouble();

double halftoneClarity(double progress) =>
    V2Dot.minClarity +
    (V2Dot.maxClarity - V2Dot.minClarity) * progress.clamp(0.0, 1.0);

/// Groups dots by quantized radius so a frame costs a few raw-point draws.
class DotBatch {
  final Map<int, List<double>> _buckets = {};
  static const _step = .25;

  void add(double x, double y, double radius) {
    if (radius < .35) return;
    final key = (radius / _step).round();
    (_buckets[key] ??= <double>[])
      ..add(x)
      ..add(y);
  }

  bool get isEmpty => _buckets.isEmpty;

  void draw(Canvas canvas, Paint paint) {
    for (final entry in _buckets.entries) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(entry.value),
        paint
          ..strokeWidth = entry.key * _step * 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

class HalftonePainter extends CustomPainter {
  HalftonePainter({
    required this.field,
    required this.progress,
    this.fromProgress,
    this.growth,
    this.assemble,
    this.touch,
    this.ink = V2Color.inkDot,
    this.sky = V2Color.sky600,
    this.accent = V2Color.sky600,
    this.afterimage = true,
    this.dotScale = 1,
  }) : super(repaint: Listenable.merge([?growth, ?assemble, ?touch]));

  final HalftoneField field;

  /// Real progress 0..1 of the volume.
  final double progress;

  /// Progress before a fresh growth event; null when nothing is arriving.
  final double? fromProgress;
  final Animation<double>? growth;

  /// Onboarding: scattered (0) to printed (1).
  final Animation<double>? assemble;

  /// Touch push for the interactive brand object.
  final ValueNotifier<V2Touch?>? touch;
  final Color ink;
  final Color sky;
  final Color accent;
  final bool afterimage;
  final double dotScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final pitch = w / field.columns;
    final maxR = pitch * .56 * dotScale;
    final from = fromProgress;
    final t = growth?.value ?? 1.0;
    final arriving = from != null && from < progress && t < 1;
    final eased = Curves.easeInOutCubic.transform(t);
    final clarityProgress = arriving
        ? from + (progress - from) * eased
        : progress;
    final clarity = halftoneClarity(clarityProgress);
    final present = halftonePresence(progress);
    final presentBefore = from == null ? present : halftonePresence(from);
    final assembleT = assemble?.value ?? 1.0;
    final push = touch?.value;

    // Duotone print: light tones in sky, shadows in ink.
    final skyBatch = DotBatch();
    final midBatch = DotBatch();
    final inkBatch = DotBatch();
    final ghostBatch = DotBatch();
    final arrivalBatch = DotBatch();

    for (final cell in field.cells) {
      if (cell.rank >= present) continue;
      // Incomplete contour: frayed edge cells drop out, a little less as
      // clarity grows, never entirely.
      if (cell.drop > cell.edge * (.55 + .45 * clarity) + .02) continue;
      // A faint memory reads the blurred image; clarity sharpens it.
      final source = cell.soft + (cell.density - cell.soft) * clarity;
      final shown = (field.mean + (source - field.mean) * (.45 + .55 * clarity))
          .clamp(0.0, 1.0);
      final tone = math.pow(shown, 1.3).toDouble();
      if (tone < .035) continue;
      var r = maxR * math.sqrt(tone) * (.45 + .55 * cell.edge);
      // The print grid stays regular; uncertainty shows as softness and
      // missing dots, with only a slight drift.
      final jitter = pitch * (1 - clarity) * .2;
      var x = cell.u * w + cell.jx * jitter;
      var y = cell.v * h + cell.jy * jitter;
      var alpha = 1.0;

      if (assembleT < 1) {
        final local = ((assembleT - cell.delay) / .45).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(local);
        x = cell.sx * w + (x - cell.sx * w) * e;
        y = cell.sy * h + (y - cell.sy * h) * e;
        r *= .55 + .45 * e;
        alpha = .25 + .75 * e;
      }

      var arrival = false;
      if (arriving && cell.rank >= presentBefore) {
        final k = (cell.rank - presentBefore) / (present - presentBefore);
        final local = ((t - k * .5) / .5).clamp(0.0, 1.0);
        if (local <= 0) continue;
        final e = Curves.easeOutCubic.transform(local);
        final startX = w * (.5 + cell.jx * .18), startY = h * 1.16;
        final ctrlX = (startX + x) / 2 + cell.jy * w * .22;
        final ctrlY = math.min(startY, y) - h * .12;
        final a = 1 - e;
        x = a * a * startX + 2 * a * e * ctrlX + e * e * x;
        y = a * a * startY + 2 * a * e * ctrlY + e * e * y;
        r *= 1 + 1.1 * (1 - e) + .25 * math.sin(e * math.pi);
        arrival = local < 1;
      }

      if (push != null && push.strength > 0) {
        final dx = x - push.position.dx, dy = y - push.position.dy;
        final dist = math.sqrt(dx * dx + dy * dy) + .001;
        final force =
            push.strength *
            pitch *
            3.4 *
            math.exp(-(dist * dist) / (2 * math.pow(pitch * 4.5, 2)));
        x += dx / dist * force;
        y += dy / dist * force;
      }

      if (alpha < 1) r *= alpha;
      final batch = arrival
          ? arrivalBatch
          : shown < .30
          ? skyBatch
          : shown < .55
          ? midBatch
          : inkBatch;
      batch.add(x, y, r);
      if (afterimage && !arrival && shown > .3) {
        ghostBatch.add(x + pitch * .48, y - pitch * .34, r * .9);
      }
    }

    if (afterimage) {
      ghostBatch.draw(
        canvas,
        Paint()
          ..color = accent.withValues(
            alpha: V2Dot.afterimage + .08 * (1 - clarity),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8),
      );
    }
    skyBatch.draw(canvas, Paint()..color = sky.withValues(alpha: .9));
    midBatch.draw(
      canvas,
      Paint()..color = Color.lerp(sky, ink, .55)!.withValues(alpha: .92),
    );
    inkBatch.draw(canvas, Paint()..color = ink.withValues(alpha: .94));
    arrivalBatch.draw(canvas, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(HalftonePainter old) =>
      old.field != field ||
      old.progress != progress ||
      old.fromProgress != fromProgress ||
      old.ink != ink ||
      old.sky != sky ||
      old.accent != accent ||
      old.afterimage != afterimage ||
      old.dotScale != dotScale;
}

@immutable
class V2Touch {
  const V2Touch(this.position, this.strength);
  final Offset position;
  final double strength;
}
