// Dot-matrix numerals and labels (DESIGN_V2.md §3.2). Every lit cell is one
// memory dot, so dates, percentages and chapter numbers speak the same dot
// language as the manuscript. Used only for numbers and short Latin labels.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

const _glyphs = <String, List<String>>{
  '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': ['#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.'],
  '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
  'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
  'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
  'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
  'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.####'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  'J': ['..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..'],
  'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
  'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
  'N': ['#...#', '#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#'],
  'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
  'Q': ['.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'],
  'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
  'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
  'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '.#.#.'],
  'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
  '.': ['.', '.', '.', '.', '.', '.', '#'],
  ':': ['.', '.', '#', '.', '.', '#', '.'],
  '·': ['.', '.', '.', '#', '.', '.', '.'],
  '/': ['....#', '...#.', '...#.', '..#..', '.#...', '.#...', '#....'],
  '%': ['##...', '##..#', '...#.', '..#..', '.#...', '#..##', '...##'],
  '+': ['.....', '..#..', '..#..', '#####', '..#..', '..#..', '.....'],
  '-': ['...', '...', '...', '###', '...', '...', '...'],
  '>': ['#....', '.#...', '..#..', '...#.', '..#..', '.#...', '#....'],
  ' ': ['...', '...', '...', '...', '...', '...', '...'],
};

/// Width in cells of [text] at one cell gap between glyphs.
int dotMatrixColumns(String text) {
  var columns = 0;
  final chars = text.toUpperCase().split('');
  for (var i = 0; i < chars.length; i++) {
    final glyph = _glyphs[chars[i]] ?? _glyphs[' ']!;
    columns += glyph.first.length + (i == chars.length - 1 ? 0 : 1);
  }
  return columns;
}

/// Lit cells of [text] as (column, row) pairs, left to right.
List<(int, int)> dotMatrixCells(String text) {
  final cells = <(int, int)>[];
  var x = 0;
  for (final char in text.toUpperCase().split('')) {
    final glyph = _glyphs[char] ?? _glyphs[' ']!;
    for (var row = 0; row < 7; row++) {
      final line = glyph[row];
      for (var col = 0; col < line.length; col++) {
        if (line[col] == '#') cells.add((x + col, row));
      }
    }
    x += glyph.first.length + 1;
  }
  return cells;
}

class V2DotMatrix extends StatelessWidget {
  const V2DotMatrix(
    this.text, {
    super.key,
    this.pitch = 3,
    this.color,
    this.ghost,
    this.lit = 1,
    this.semanticsLabel,
  });

  final String text;

  /// Distance between dot centers. Cap height is 7 × pitch.
  final double pitch;
  final Color? color;

  /// Optional unlit-cell color (a faint matrix behind the glyphs).
  final Color? ghost;

  /// Fraction of dots shown, in a stable scattered order. Used when a
  /// number is printed dot by dot after a real change; 1 at rest.
  final double lit;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    // Respect Dynamic Type without letting numerals overwhelm the layout.
    final scaled = MediaQuery.textScalerOf(context).scale(pitch * 10) / 10;
    final p = math.min(scaled, pitch * 1.7);
    final columns = dotMatrixColumns(text);
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Never overflow: a long label tightens its dot pitch to fit.
          final fit = constraints.hasBoundedWidth && columns > 0
              ? math.min(p, constraints.maxWidth / columns)
              : p;
          return CustomPaint(
            size: Size(columns * fit, 7 * fit),
            painter: DotMatrixPainter(
              text: text,
              pitch: fit,
              color:
                  color ??
                  DefaultTextStyle.of(context).style.color ??
                  V2Color.ink,
              ghost: ghost,
              lit: lit,
            ),
          );
        },
      ),
    );
  }
}

class DotMatrixPainter extends CustomPainter {
  DotMatrixPainter({
    required this.text,
    required this.pitch,
    required this.color,
    this.ghost,
    this.lit = 1,
  }) : _cells = dotMatrixCells(text);

  final String text;
  final double pitch;
  final Color color;
  final Color? ghost;
  final double lit;
  final List<(int, int)> _cells;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = pitch * .36;
    if (ghost != null) {
      final paint = Paint()..color = ghost!;
      final columns = (size.width / pitch).round();
      for (var x = 0; x < columns; x++) {
        for (var y = 0; y < 7; y++) {
          canvas.drawCircle(
            Offset((x + .5) * pitch, (y + .5) * pitch),
            radius * .7,
            paint,
          );
        }
      }
    }
    final paint = Paint()..color = color;
    for (var i = 0; i < _cells.length; i++) {
      final (x, y) = _cells[i];
      if (lit < 1) {
        // Stable scatter: a cell's turn depends on its position only.
        final turn = ((x * 73 + y * 151) % 97) / 97;
        if (turn >= lit) continue;
      }
      canvas.drawCircle(
        Offset((x + .5) * pitch, (y + .5) * pitch),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DotMatrixPainter old) =>
      old.text != text ||
      old.pitch != pitch ||
      old.color != color ||
      old.ghost != ghost ||
      old.lit != lit;
}
