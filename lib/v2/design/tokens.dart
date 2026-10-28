// MUMUMONG V2 tokens. DESIGN_V2.md is the source of truth and these values
// are 1:1 with it. V2 screens never define colors, sizes, radii, shadows or
// durations of their own; they read them from here or from V2 components.
import 'package:flutter/material.dart';

/// Warm Sky Blue is the only brand hue. Warm light and haze tints exist only
/// inside the atmosphere and glass light, never as UI fills or text.
abstract final class V2Color {
  static const sky50 = Color(0xFFF2F7FC);
  static const sky100 = Color(0xFFE3EEF9);
  static const sky200 = Color(0xFFCCE1F4);
  static const sky300 = Color(0xFFADCEEE);
  static const sky400 = Color(0xFF8DBDE8);
  static const sky500 = Color(0xFF5E9DD8);
  static const sky600 = Color(0xFF3B7DBE);
  static const sky700 = Color(0xFF2A609A);
  static const sky800 = Color(0xFF1C4471);

  static const paper = Color(0xFFFBF9F5);
  static const paperPure = Color(0xFFFFFEFB);
  static const well = Color(0xFFF1F3F5);

  static const lightWarm = Color(0xFFF8ECC8);
  static const lightHaze = Color(0xFFF4E9DF);

  static const ink = Color(0xFF15181D);
  static const ink2 = Color(0xFF454A52);
  static const ink3 = Color(0xFF646970);
  static const inkDot = Color(0xFF1F2E40);
  static const hairline = Color(0x1715181D);
  static const alert = Color(0xFFA2412F);

  static const nightPaper = Color(0xFF1C1B19);
  static const nightInk = Color(0xFFE9E4DA);
  static const nightMeta = Color(0xFFA29C91);
  static const nightLine = Color(0xFF34322E);
  static const nightDot = Color(0xFFB8CCE0);
}

abstract final class V2Font {
  static const serif = 'MaruBuri';
  static const sans = 'Pretendard';
}

/// Editorial serif for what is read and remembered; sans for what is operated.
abstract final class V2Type {
  static const displayXL = TextStyle(
    fontFamily: V2Font.serif,
    fontSize: 37,
    height: 1.24,
    letterSpacing: -0.9,
    color: V2Color.ink,
  );
  static const display = TextStyle(
    fontFamily: V2Font.serif,
    fontSize: 30,
    height: 1.28,
    letterSpacing: -0.6,
    color: V2Color.ink,
  );
  static const title = TextStyle(
    fontFamily: V2Font.serif,
    fontSize: 23,
    height: 1.36,
    letterSpacing: -0.35,
    color: V2Color.ink,
  );
  static const headline = TextStyle(
    fontFamily: V2Font.sans,
    fontWeight: FontWeight.w500,
    fontSize: 17.5,
    height: 1.42,
    letterSpacing: -0.25,
    color: V2Color.ink,
  );
  static const body = TextStyle(
    fontFamily: V2Font.sans,
    fontSize: 16,
    height: 1.62,
    letterSpacing: -0.15,
    color: V2Color.ink2,
  );
  static const bodySmall = TextStyle(
    fontFamily: V2Font.sans,
    fontSize: 14,
    height: 1.55,
    letterSpacing: -0.1,
    color: V2Color.ink2,
  );
  static const label = TextStyle(
    fontFamily: V2Font.sans,
    fontWeight: FontWeight.w500,
    fontSize: 15.5,
    height: 1.25,
    letterSpacing: -0.15,
    color: V2Color.ink,
  );
  // ink2, not ink3: meta sits on the drifting sky and must stay readable
  // under every phase of the light.
  static const meta = TextStyle(
    fontFamily: V2Font.sans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.4,
    letterSpacing: 0.5,
    color: V2Color.ink2,
  );
  static const reading = TextStyle(
    fontFamily: V2Font.serif,
    fontSize: 18,
    height: 1.88,
    letterSpacing: -0.2,
    color: V2Color.ink,
  );
  static const capture = TextStyle(
    fontFamily: V2Font.serif,
    fontSize: 18,
    height: 1.72,
    letterSpacing: -0.2,
    color: V2Color.ink,
  );
}

abstract final class V2Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 72.0;

  /// Editorial margin (Reference B): wide, never below 24 on phones.
  static const gutter = 24.0;
  static const readingMeasure = 560.0;
  static const contentMax = 640.0;
}

abstract final class V2Radius {
  static const chip = 999.0;
  static const field = 26.0;
  static const card = 30.0;
  static const hero = 40.0;
  static const sheet = 34.0;
  static const small = 14.0;
}

abstract final class V2Size {
  static const touch = 44.0;
  static const button = 54.0;
  static const buttonCompact = 46.0;
  static const icon = 44.0;
  static const record = 76.0;
  static const nav = 64.0;
  static const navCta = 52.0;
}

/// Shadows are cool-tinted and soft (Reference E): depth without darkness.
abstract final class V2Shadow {
  static const _tint = Color(0xFF1C3552);

  static List<BoxShadow> rest = [
    BoxShadow(
      color: _tint.withValues(alpha: .07),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: _tint.withValues(alpha: .05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> raised = [
    BoxShadow(
      color: _tint.withValues(alpha: .11),
      blurRadius: 40,
      spreadRadius: -4,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: _tint.withValues(alpha: .06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: _tint.withValues(alpha: .16),
      blurRadius: 48,
      spreadRadius: -6,
      offset: const Offset(0, 22),
    ),
    BoxShadow(
      color: _tint.withValues(alpha: .08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> pressed = [
    BoxShadow(
      color: _tint.withValues(alpha: .06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

abstract final class V2Glass {
  static const blur = 18.0;
  static const heavyBlur = 28.0;
  static const fillTop = .66;
  static const fillBottom = .48;
  static const elevatedTop = .80;
  static const elevatedBottom = .66;
}

/// Nothing moves unless something happened (DESIGN_V2.md §6). Durations are
/// for responses to a user action or a real state change, never idle loops.
abstract final class V2Motion {
  static const tap = Duration(milliseconds: 90);
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 280);
  static const page = Duration(milliseconds: 460);
  static const gather = Duration(milliseconds: 1150);
  static const stage = Duration(milliseconds: 1250);
  static const assemble = Duration(milliseconds: 1900);
  static const reveal = Duration(milliseconds: 1700);
  static const growth = Duration(milliseconds: 2300);
  static const revealStagger = Duration(milliseconds: 110);

  static const settle = Cubic(0.2, 0.8, 0.2, 1.0);
  static const emphasize = Cubic(0.3, 0.0, 0.0, 1.0);
  static const exit = Cubic(0.4, 0.0, 1.0, 1.0);
  static const drift = Cubic(0.45, 0.05, 0.25, 1.0);

  /// Press sinks fast and firmly; release overshoots a little so the surface
  /// "pops" back (Reference A tactile depth).
  static const press = SpringDescription(mass: 1, stiffness: 700, damping: 46);
  static const release = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 21,
  );

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Halftone/dot language constants (DESIGN_V2.md §5).
abstract final class V2Dot {
  /// Clearer, but never completely clear.
  static const maxClarity = .86;
  static const minClarity = .28;
  static const afterimage = .16;
  static const minPresence = .10;
}
