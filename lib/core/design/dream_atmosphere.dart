import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'design_system.dart';
import 'sampled_motion.dart';

/// The light has a focal point and fades out before the reading/action plane.
/// Only the painter ticks; no full-screen filter or parent frame rebuild.
class DreamAtmosphere extends StatefulWidget {
  const DreamAtmosphere({
    super.key,
    this.animate = true,
    this.night = false,
    this.strength = 1,
    this.memoryObject = false,
  });
  final bool animate;
  final bool night;
  final double strength;
  final bool memoryObject;
  @override
  State<DreamAtmosphere> createState() => _DreamAtmosphereState();
}

class _DreamAtmosphereState extends State<DreamAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
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
  void didUpdateWidget(covariant DreamAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!_foreground ||
        !widget.animate ||
        MediaQuery.disableAnimationsOf(context)) {
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
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: DreamAtmospherePainter(
            night: widget.night,
            strength: widget.strength,
            clock: still ? null : _sampled,
            memoryObject: widget.memoryObject,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

@visibleForTesting
class DreamAtmospherePainter extends CustomPainter {
  DreamAtmospherePainter({
    this.clock,
    this.night = false,
    this.strength = 1,
    this.stillPhase = .24,
    this.memoryObject = false,
  }) : super(repaint: clock);
  final ValueListenable<double>? clock;
  final bool night;
  final double strength;
  final double stillPhase;
  final bool memoryObject;
  double get phase => clock?.value ?? stillPhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = phase * 2 * math.pi;
    final amount = strength.clamp(0.0, 1.0);
    final ink = night ? const Color(0xFF050C18) : MongColor.paper;
    canvas.drawRect(Offset.zero & size, Paint()..color = ink);
    void light(
      double x,
      double y,
      double rx,
      double ry,
      Color color,
      double alpha,
    ) {
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
              color.withValues(alpha: alpha * amount),
              color.withValues(alpha: alpha * amount * .55),
              color.withValues(alpha: 0),
            ],
            [0, .38, 1],
          ),
      );
      canvas.restore();
    }

    light(
      .66 + .1 * math.sin(t),
      .17 + .06 * math.cos(t),
      .82,
      .65,
      const Color(0xFF72CBF2),
      night ? .64 : .95,
    );
    light(
      .12 + .10 * math.cos(t),
      .24 + .06 * math.sin(t),
      .54,
      .53,
      const Color(0xFF5666CD),
      night ? .86 : .88,
    );
    light(
      .38 + .12 * math.sin(t + 1),
      .20 + .07 * math.cos(t + 1),
      .51,
      .50,
      const Color(0xFF288FD4),
      night ? .90 : .72,
    );
    light(
      .75 + .06 * math.cos(t + 2),
      .48,
      .54,
      .51,
      const Color(0xFFE7F7FF),
      night ? .12 : .96,
    );
    if (memoryObject) {
      canvas.save();
      canvas.translate(size.width * .53, size.height * .37);
      canvas.rotate(-.14 + .035 * math.sin(t));
      final w = (size.width * .12).clamp(38.0, 64.0);
      final paper = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: w * 1.3),
        const Radius.circular(9),
      );
      canvas.drawRRect(
        paper.shift(const Offset(-7, 6)),
        Paint()..color = Colors.white.withValues(alpha: .20),
      );
      canvas.drawRRect(
        paper,
        Paint()
          ..shader = ui.Gradient.linear(Offset(-w / 2, -w), Offset(w / 2, w), [
            Colors.white.withValues(alpha: .86),
            Colors.white.withValues(alpha: .24),
          ]),
      );
      canvas.drawRRect(
        paper,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = Colors.white.withValues(alpha: .7),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(-w * .22, -w * .12 + i * 8),
          Offset(w * (i == 2 ? .08 : .22), -w * .12 + i * 8),
          Paint()
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF5078A1).withValues(alpha: .35),
        );
      }
      canvas.restore();
    }
    // The entire lower third is the uncoloured content plane.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * .40),
          Offset(0, size.height * .96),
          [ink.withValues(alpha: 0), ink],
          [0, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * .12),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height * .12),
          [ink, ink.withValues(alpha: 0)],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant DreamAtmospherePainter old) =>
      old.clock != clock ||
      old.night != night ||
      old.strength != strength ||
      old.memoryObject != memoryObject ||
      old.stillPhase != stillPhase;
}

/// A small, one-shot stamp after local save succeeds. Never used while typing.
class MemoryStamp extends StatefulWidget {
  const MemoryStamp({super.key, this.size = 32});
  final double size;
  @override
  State<MemoryStamp> createState() => _MemoryStampState();
}

class _MemoryStampState extends State<MemoryStamp>
    with SingleTickerProviderStateMixin {
  late final _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle.value = 1;
    } else if (_settle.value == 0) {
      _settle.forward();
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _MemoryStampPainter(
            _settle,
            Theme.of(context).brightness == Brightness.dark
                ? MongColor.nightSky
                : MongColor.sky700,
          ),
        ),
      ),
    ),
  );
}

class _MemoryStampPainter extends CustomPainter {
  _MemoryStampPainter(this.settle, this.color) : super(repaint: settle);
  final Animation<double> settle;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final progress = Curves.easeOutCubic.transform(settle.value);
    const cells = [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1), (2, 2), (3, 1)];
    for (var i = 0; i < cells.length; i++) {
      final target = Offset(
        (cells[i].$1 + .5) * size.width / 4,
        (cells[i].$2 + .5) * size.height / 3,
      );
      final origin = Offset(
        size.width * (.1 + (i * .31) % .8),
        size.height * (.08 + (i * .43) % .85),
      );
      final point = Offset.lerp(origin, target, progress)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point,
            width: size.width * .12,
            height: size.width * .12,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = color.withValues(alpha: .35 + .55 * progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryStampPainter old) =>
      old.settle != settle || old.color != color;
}

/// Same geometry and semantic roles in the persisted application night theme.
ThemeData dreamNightTheme() {
  final base = mumumongTheme();
  return base.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050C18),
    colorScheme: const ColorScheme.dark(
      primary: MongColor.nightInk,
      surface: Color(0xFF050C18),
      onSurface: MongColor.nightInk,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: MongColor.nightInk,
      displayColor: MongColor.nightInk,
    ),
    iconTheme: base.iconTheme.copyWith(color: MongColor.nightInk),
    dividerColor: const Color(0xFF314055),
    dividerTheme: base.dividerTheme.copyWith(color: const Color(0xFF314055)),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: const Color(0xFF050C18),
      foregroundColor: MongColor.nightInk,
      surfaceTintColor: Colors.transparent,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: MongColor.nightInk,
      selectionColor: Color(0xFF314E66),
      selectionHandleColor: MongColor.nightSky,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: const Color(0xFF111C2B),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: const Color(0xFF111C2B),
      titleTextStyle: base.textTheme.titleMedium?.copyWith(
        color: MongColor.nightInk,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: MongColor.nightInk,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      textColor: MongColor.nightInk,
      iconColor: MongColor.nightInk,
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? MongColor.nightMeta
              : MongColor.nightInk,
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF152131),
      hintStyle: base.textTheme.bodyMedium?.copyWith(
        color: const Color(0xFFA5B2C1),
      ),
      labelStyle: base.textTheme.bodyMedium?.copyWith(
        color: const Color(0xFFA5B2C1),
      ),
    ),
    checkboxTheme: base.checkboxTheme.copyWith(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? MongColor.nightInk
            : const Color(0xFF152131),
      ),
      checkColor: const WidgetStatePropertyAll(Color(0xFF050C18)),
      side: const BorderSide(color: MongColor.nightMeta),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: const Color(0xFF111C2B),
      textStyle: base.textTheme.bodyMedium?.copyWith(color: MongColor.nightInk),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: base.iconButtonTheme.style?.copyWith(
        foregroundColor: const WidgetStatePropertyAll(MongColor.nightInk),
      ),
    ),
  );
}
