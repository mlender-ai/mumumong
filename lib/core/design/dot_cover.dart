// DESIGN.md §8: the dot cover renderer. Dots are the state of a memory, not
// decoration. The field is seeded per volume so a cover stays the same across
// launches; density follows real progress; clarity never reaches 1.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'design_system.dart';

/// Dot life cycle shared by cover, stamp and processing (DESIGN.md §8).
enum DotState { dormant, forming, gathering, settled, merging, grown }

/// A few hand-tuned masks. Abstract is the default; motifs are chosen from
/// real volume data later, never guessed from dream text here.
enum DotMotif { abstract, door, window, moon }

/// Pure parameters for one cover; equal values paint identically.
@immutable
class DotCoverSpec {
  const DotCoverSpec({
    required this.seed,
    this.motif = DotMotif.abstract,
    this.density = .35,
    this.clarity = .5,
    this.jitter = .5,
  });

  /// Stable per volume (hash of its id).
  final int seed;
  final DotMotif motif;

  /// 0–1, follows progress. Controls how many cells are occupied.
  final double density;

  /// 0–[maxClarity]. Controls dropout and edge blur. Never 1.
  final double clarity;

  /// 0–1 positional noise.
  final double jitter;

  static const maxClarity = .9;
  static const minDropout = .1;
  static const cellMin = 2.0;
  static const cellMax = 4.0;

  double get effectiveClarity => clarity.clamp(0.0, maxClarity);
  double get dropout => (1 - effectiveClarity).clamp(minDropout, 1.0);

  DotCoverSpec copyWith({
    int? seed,
    DotMotif? motif,
    double? density,
    double? clarity,
    double? jitter,
  }) => DotCoverSpec(
    seed: seed ?? this.seed,
    motif: motif ?? this.motif,
    density: density ?? this.density,
    clarity: clarity ?? this.clarity,
    jitter: jitter ?? this.jitter,
  );

  @override
  bool operator ==(Object other) =>
      other is DotCoverSpec &&
      other.seed == seed &&
      other.motif == motif &&
      other.density == density &&
      other.clarity == clarity &&
      other.jitter == jitter;

  @override
  int get hashCode => Object.hash(seed, motif, density, clarity, jitter);
}

/// Paints the cover. `transition` (0–1) interpolates from the previous spec
/// so growth reads as dots arriving, not as a redraw. Nothing loops.
class DotCover extends StatelessWidget {
  const DotCover({
    super.key,
    required this.spec,
    this.previous,
    this.transition,
    this.color,
    this.settleColor,
  });

  final DotCoverSpec spec;
  final DotCoverSpec? previous;

  /// Drives growth; null paints [spec] directly.
  final ValueListenable<double>? transition;
  final Color? color;
  final Color? settleColor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: DotCoverPainter(
        spec: spec,
        previous: previous,
        transition: transition,
        arriveColor: color ?? MongColor.sky500,
        settleColor: settleColor ?? context.accentInk,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

@visibleForTesting
class DotCoverPainter extends CustomPainter {
  DotCoverPainter({
    required this.spec,
    this.previous,
    this.transition,
    required this.arriveColor,
    required this.settleColor,
  }) : super(repaint: transition);

  final DotCoverSpec spec;
  final DotCoverSpec? previous;
  final ValueListenable<double>? transition;
  final Color arriveColor;
  final Color settleColor;

  static const _columns = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Without a previous spec there is nothing to arrive from: paint settled.
    final t = previous == null
        ? 1.0
        : (transition?.value.clamp(0.0, 1.0) ?? 1.0);
    final from = previous ?? spec;
    final density = ui.lerpDouble(from.density, spec.density, t)!;
    final clarity = ui.lerpDouble(
      from.effectiveClarity,
      spec.effectiveClarity,
      t,
    )!;
    final dropout = (1 - clarity).clamp(DotCoverSpec.minDropout, 1.0);
    final cell = size.width / _columns;
    final rows = (size.height / cell).ceil();
    final random = math.Random(spec.seed);
    final dotSize = ui.lerpDouble(
      DotCoverSpec.cellMin,
      DotCoverSpec.cellMax,
      clarity,
    )!;
    // Soft edges even when settled: the dream never fully wakes.
    final blur = ui.MaskFilter.blur(
      ui.BlurStyle.normal,
      ui.lerpDouble(2.2, .6, clarity)!,
    );
    final paint = Paint()..maskFilter = blur;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < _columns; col++) {
        // One stable random draw per cell, independent of density/clarity.
        final occupancy = random.nextDouble();
        final drop = random.nextDouble();
        final jx = (random.nextDouble() - .5) * spec.jitter;
        final jy = (random.nextDouble() - .5) * spec.jitter;
        final arrive = random.nextDouble();

        final nx = (col + .5) / _columns;
        final ny = (row + .5) / rows;
        final mask = _mask(spec.motif, nx, ny);
        if (mask <= 0) continue;
        if (occupancy > density * mask) continue;
        if (drop < dropout * (1 - mask * .5)) continue;

        // Cells arrive in a staggered order during a growth transition.
        final arrival = ((t - arrive * .6) / .4).clamp(0.0, 1.0);
        if (arrival == 0 &&
            previous != null &&
            occupancy > from.density * mask) {
          continue;
        }
        final c = Color.lerp(arriveColor, settleColor, arrival)!;
        paint.color = c.withValues(alpha: .35 + .55 * mask * arrival);
        final center = Offset((col + .5 + jx) * cell, (row + .5 + jy) * cell);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: dotSize, height: dotSize),
            const Radius.circular(.8),
          ),
          paint,
        );
      }
    }
  }

  /// 0–1 weight of a normalised position inside the motif.
  static double _mask(DotMotif motif, double x, double y) {
    switch (motif) {
      case DotMotif.abstract:
        // A soft upper-left focal cloud, like the atmosphere light.
        final dx = x - .42, dy = y - .38;
        final d = math.sqrt(dx * dx + dy * dy * 1.4);
        return (1 - d / .55).clamp(0.0, 1.0);
      case DotMotif.door:
        final inside = x > .36 && x < .64 && y > .18 && y < .86;
        if (!inside) return 0;
        final edge = math.min(
          math.min(x - .36, .64 - x) / .06,
          math.min(y - .18, .86 - y) / .08,
        );
        return (.55 + .45 * edge.clamp(0.0, 1.0));
      case DotMotif.window:
        final inside = x > .28 && x < .72 && y > .26 && y < .70;
        if (!inside) return 0;
        final bar = (x - .5).abs() < .015 || (y - .48).abs() < .02;
        return bar ? .15 : .9;
      case DotMotif.moon:
        final dx = x - .5, dy = (y - .46) * 1.1;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > .26) return 0;
        final bite = math.sqrt((x - .60) * (x - .60) + dy * dy);
        return bite < .2 ? .12 : 1 - (d / .26) * .3;
    }
  }

  @override
  bool shouldRepaint(covariant DotCoverPainter old) =>
      old.spec != spec ||
      old.previous != previous ||
      old.transition != transition ||
      old.arriveColor != arriveColor ||
      old.settleColor != settleColor;
}

/// Derives a stable cover seed from a volume id.
int dotSeedFor(String volumeId) => volumeId.hashCode & 0x7fffffff;

/// The home cover spec for a volume at [progress] (0–1). Density and clarity
/// are pure functions of real progress; `growth` on Home interpolates from
/// the spec at the previous progress so new dots arrive instead of redraw.
DotCoverSpec homeCoverSpec(String volumeId, double progress) {
  final p = progress.clamp(0.0, 1.0);
  return DotCoverSpec(
    seed: dotSeedFor(volumeId),
    density: .22 + .62 * p,
    clarity: (.30 + .60 * p).clamp(0.0, DotCoverSpec.maxClarity),
    jitter: .55,
  );
}
