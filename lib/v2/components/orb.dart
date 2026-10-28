// V1's Thinking Orb in the V2 palette: one 64px banded sphere that turns
// while real work is waiting (processing, opening the app, reading a draft).
// The package pauses on hidden routes and in the background and shows a
// still frame with Reduce Motion. The surrounding screen carries the words.
import 'package:flutter/material.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;

import '../design/tokens.dart';

class V2ThinkingOrb extends StatelessWidget {
  const V2ThinkingOrb({super.key, this.color = V2Color.sky700});

  final Color color;

  static const size = 64.0;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: orbs.ThinkingOrb(
          state: orbs.OrbState.composing,
          size: orbs.OrbSize.size64,
          color: color,
        ),
      ),
    ),
  );
}
