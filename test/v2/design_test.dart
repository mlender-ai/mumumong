// V2 design rules as tests (DESIGN_V2.md §2, §3, §5).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/v2/design/dot_matrix.dart';
import 'package:mumumong/v2/design/halftone.dart';
import 'package:mumumong/v2/design/memory_swarm.dart';
import 'package:mumumong/v2/design/tokens.dart';
import 'package:mumumong/v2/screens/format.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * channel(c.r) + .7152 * channel(c.g) + .0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

Color over(Color top, double alpha, Color bottom) =>
    Color.lerp(bottom, top.withValues(alpha: 1), alpha)!;

void main() {
  group('color', () {
    final frostedOnSky = over(Colors.white, V2Glass.fillBottom, V2Color.sky200);
    test('text tokens meet WCAG AA on every V2 surface', () {
      for (final (fg, bg, name) in [
        (V2Color.ink, V2Color.paper, 'ink/paper'),
        (V2Color.ink2, V2Color.paper, 'ink2/paper'),
        (V2Color.ink3, V2Color.paper, 'ink3/paper'),
        (V2Color.sky700, V2Color.paper, 'sky700/paper'),
        (V2Color.ink3, frostedOnSky, 'ink3/frosted over sky'),
        (V2Color.ink2, V2Color.sky200, 'ink2/atmosphere top'),
        (Colors.white, V2Color.ink, 'white/ink pill'),
        (V2Color.sky800, V2Color.sky100, 'sky800/status pill'),
        (V2Color.alert, V2Color.paper, 'alert/paper'),
        (V2Color.nightInk, V2Color.nightPaper, 'night ink'),
        (V2Color.nightMeta, V2Color.nightPaper, 'night meta'),
      ]) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
      }
    });

    test('the brand has one hue: every sky token is the same warm blue', () {
      final hues = [
        V2Color.sky300,
        V2Color.sky400,
        V2Color.sky500,
        V2Color.sky600,
        V2Color.sky700,
      ].map((c) => HSLColor.fromColor(c).hue);
      for (final hue in hues) {
        expect(hue, inInclusiveRange(205, 215));
      }
    });
  });

  group('halftone', () {
    test('clearer, but never completely clear', () {
      expect(halftoneClarity(1), V2Dot.maxClarity);
      expect(halftoneClarity(1), lessThan(1));
      expect(halftoneClarity(5), V2Dot.maxClarity);
      expect(halftoneClarity(0), V2Dot.minClarity);
    });

    test('presence and clarity only grow with real progress', () {
      var lastPresence = -1.0, lastClarity = -1.0;
      for (var p = 0.0; p <= 1.0; p += .05) {
        expect(halftonePresence(p), greaterThan(lastPresence));
        expect(halftoneClarity(p), greaterThan(lastClarity));
        lastPresence = halftonePresence(p);
        lastClarity = halftoneClarity(p);
      }
    });

    test('fields are deterministic per volume and cached', () {
      final a = HalftoneField.of(motif: V2Motif.door, seed: 3);
      final b = HalftoneField.of(motif: V2Motif.door, seed: 3);
      expect(identical(a, b), isTrue);
      expect(a.cells, isNotEmpty);
      for (final cell in a.cells) {
        expect(cell.density, inInclusiveRange(0, 1));
        expect(cell.rank, inInclusiveRange(0, 1));
      }
    });

    test('a frayed contour remains at full progress', () {
      final field = HalftoneField.of(motif: V2Motif.window, seed: 9);
      final frayed = field.cells.where((c) => c.edge < .5).length;
      expect(frayed / field.cells.length, greaterThan(.1));
    });

    test('cover motifs are real objects, never sky imagery', () {
      expect(
        motifFor(coverMotifId: 'red-door-water', volumeId: 'x'),
        V2Motif.door,
      );
      expect(
        motifFor(coverMotifId: 'rain-umbrella', volumeId: 'x'),
        V2Motif.umbrella,
      );
      expect(V2Motif.values.map((m) => m.name), isNot(contains('moon')));
      expect(V2Motif.values.map((m) => m.name), isNot(contains('star')));
    });
  });

  group('dots', () {
    test('every label V2 prints has a dot-matrix glyph', () {
      const used = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.:/%+->· ';
      for (final char in used.split('')) {
        expect(
          dotMatrixCells(char).isNotEmpty || char == ' ',
          isTrue,
          reason: char,
        );
      }
      expect(dotMatrixColumns('10'), 11);
    });

    test(
      'the memory field grows with what was remembered, within capacity',
      () {
        expect(MemorySwarm.dotsForText(0), greaterThan(0));
        var last = 0;
        for (var n = 0; n < 400; n += 20) {
          final dots = MemorySwarm.dotsForText(n);
          expect(dots, greaterThanOrEqualTo(last));
          expect(dots, lessThanOrEqualTo(180));
          last = dots;
        }
      },
    );
  });

  group('copy', () {
    test('keep-all joins syllables only inside words', () {
      const text = '복도 끝에는 붉은 문이 있었다.';
      final shown = v2KeepAll(text);
      expect(shown.replaceAll('⁠', ''), text);
      expect(shown.split(' ').length, text.split(' ').length);
    });

    test('progress reasons come only from recorded reasons', () {
      final event = ProgressEvent(
        id: 'e',
        volumeId: 'v',
        dreamId: 'd',
        deltaMu: 4,
        reasons: const [
          {'type': 'new_scene', 'n': 1},
          {'type': 'recall', 'n': 2},
          {'type': 'unknown_future_reason', 'n': 1},
        ],
        createdAt: DateTime.utc(2026),
      );
      expect(v2ProgressReason(event, 80), '+5%  ·  새 장면  ·  보강 2');
    });
  });
}
