// V2 buttons (DESIGN_V2.md §7.2). Every button is a V2Pressable over a
// V2 surface, so primary, secondary, glass, floating, icon and recording
// controls share one physics: sink, light shift, spring release, haptics.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/press.dart';
import '../design/surface.dart';
import '../design/tokens.dart';

enum V2ButtonVariant {
  /// Ink pill: the one decisive action on a screen.
  primary,

  /// Warm paper pill: a real alternative.
  secondary,

  /// Frosted glass pill with chromatic light (Reference A).
  glass,

  /// Elevated ink pill that floats above content.
  floating,
}

enum V2ButtonSize { regular, compact }

class V2Button extends StatelessWidget {
  const V2Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = V2ButtonVariant.primary,
    this.size = V2ButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
    this.haptic,
    this.semanticLabel,
  });

  const V2Button.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = V2ButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
    this.haptic,
    this.semanticLabel,
  }) : variant = V2ButtonVariant.secondary;

  const V2Button.glass({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = V2ButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
    this.haptic,
    this.semanticLabel,
  }) : variant = V2ButtonVariant.glass;

  const V2Button.floating({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.loadingLabel,
    this.expand = false,
    this.haptic,
    this.semanticLabel,
  }) : variant = V2ButtonVariant.floating,
       size = V2ButtonSize.regular;

  final String label;
  final VoidCallback? onPressed;
  final V2ButtonVariant variant;
  final V2ButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final String? loadingLabel;
  final bool expand;
  final V2Haptic? haptic;
  final String? semanticLabel;

  bool get _ink =>
      variant == V2ButtonVariant.primary || variant == V2ButtonVariant.floating;

  @override
  Widget build(BuildContext context) {
    final height = size == V2ButtonSize.compact
        ? V2Size.buttonCompact
        : V2Size.button;
    final horizontal = size == V2ButtonSize.compact ? 18.0 : 26.0;
    return V2Pressable(
      onPressed: onPressed,
      loading: loading,
      haptic: haptic ?? (_ink ? V2Haptic.light : V2Haptic.selection),
      semanticLabel: semanticLabel ?? (loading ? loadingLabel ?? label : label),
      minSize: Size(V2Size.touch, math.max(V2Size.touch, height)),
      builder: (context, state) {
        final kind = switch (variant) {
          V2ButtonVariant.primary ||
          V2ButtonVariant.floating => V2SurfaceKind.ink,
          V2ButtonVariant.secondary => V2SurfaceKind.paper,
          V2ButtonVariant.glass => V2SurfaceKind.frosted,
        };
        final foreground = _ink ? Colors.white : V2Color.ink;
        final enabled = state.enabled;
        final reduced = V2Motion.reduced(context);
        final scale = reduced ? 1.0 : 1 - .032 * state.depth;
        final text = loading ? (loadingLabel ?? label) : label;
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: V2Type.label.copyWith(color: foreground),
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 10),
              _LoadingDots(color: foreground),
            ] else if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18, color: foreground),
            ],
          ],
        );
        Widget surface = V2Surface(
          kind: kind,
          radius: height / 2,
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          chroma: variant == V2ButtonVariant.glass ? .55 : 0,
          sink: state.sink,
          hover: state.hover,
          blur: variant == V2ButtonVariant.glass ? V2Glass.blur : 0,
          shadow: enabled && variant != V2ButtonVariant.floating,
          child: Center(
            widthFactor: expand ? null : 1,
            child: Transform.translate(
              offset: Offset(0, reduced ? 0 : .6 * state.sink),
              child: content,
            ),
          ),
        );
        if (variant == V2ButtonVariant.floating) {
          surface = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: enabled
                  ? BoxShadow.lerpList(
                      V2Shadow.floating,
                      V2Shadow.pressed,
                      state.sink,
                    )
                  : null,
            ),
            child: surface,
          );
        }
        return Opacity(
          opacity: enabled ? 1 : .42,
          child: _FocusRing(
            focused: state.focused,
            radius: height / 2,
            child: Transform.scale(scale: scale, child: surface),
          ),
        );
      },
    );
  }
}

/// A quiet text action for tertiary choices ("나중에 만들기").
class V2TextAction extends StatelessWidget {
  const V2TextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, state) {
        final base = color ?? V2Color.ink2;
        return Opacity(
          opacity: state.enabled ? 1 - state.sink * .35 : .4,
          child: _FocusRing(
            focused: state.focused,
            radius: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: V2Type.label.copyWith(
                        color: base,
                        fontSize: 14.5,
                        decoration: state.hover > .5
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, size: 16, color: base),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum V2IconButtonVariant { glass, plain, ink }

class V2IconButton extends StatelessWidget {
  const V2IconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = V2IconButtonVariant.glass,
    this.size = V2Size.icon,
    this.color,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final V2IconButtonVariant variant;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: semanticLabel,
      minSize: Size(math.max(size, V2Size.touch), math.max(size, V2Size.touch)),
      builder: (context, state) {
        final reduced = V2Motion.reduced(context);
        final foreground =
            color ??
            (variant == V2IconButtonVariant.ink ? Colors.white : V2Color.ink);
        final glyph = Icon(icon, size: size * .45, color: foreground);
        Widget face;
        if (variant == V2IconButtonVariant.plain) {
          face = SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: V2Color.ink.withValues(
                  alpha: .07 * state.sink + .04 * state.hover,
                ),
              ),
              child: Center(child: glyph),
            ),
          );
        } else {
          face = V2Surface(
            kind: variant == V2IconButtonVariant.ink
                ? V2SurfaceKind.ink
                : V2SurfaceKind.frosted,
            radius: size / 2,
            width: size,
            height: size,
            padding: EdgeInsets.zero,
            chroma: variant == V2IconButtonVariant.glass ? .3 : 0,
            sink: state.sink,
            hover: state.hover,
            blur: variant == V2IconButtonVariant.glass ? V2Glass.blur : 0,
            child: Center(child: glyph),
          );
        }
        return Opacity(
          opacity: state.enabled ? 1 : .4,
          child: _FocusRing(
            focused: state.focused,
            radius: size / 2,
            child: Transform.scale(
              scale: reduced ? 1 : 1 - .06 * state.depth,
              child: face,
            ),
          ),
        );
      },
    );
  }
}

/// The recording control (Reference C). Idle: glass with a microphone.
/// Recording: warm sky fill and a ring of memory dots driven by the real
/// speech level, so the control shows that it is listening.
class V2RecordButton extends StatelessWidget {
  const V2RecordButton({
    super.key,
    required this.recording,
    required this.onPressed,
    this.level,
    this.semanticLabel,
  });

  final bool recording;
  final VoidCallback? onPressed;
  final ValueListenable<double>? level;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const size = V2Size.record;
    return V2Pressable(
      onPressed: onPressed,
      haptic: recording ? V2Haptic.light : V2Haptic.medium,
      semanticLabel: semanticLabel ?? (recording ? '녹음 멈추기' : '말로 기록하기'),
      toggled: recording,
      minSize: const Size(size + 20, size + 20),
      builder: (context, state) {
        final reduced = V2Motion.reduced(context);
        final Widget face = recording
            ? Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [V2Color.sky500, V2Color.sky700],
                    center: Alignment(-.3, -.45),
                    radius: 1.05,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: V2Color.sky600.withValues(
                        alpha: .34 * (1 - state.sink),
                      ),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: .28 * (1 - state.sink)),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.stop_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              )
            : V2Surface(
                kind: V2SurfaceKind.elevated,
                radius: size / 2,
                width: size,
                height: size,
                padding: EdgeInsets.zero,
                chroma: .6,
                sink: state.sink,
                hover: state.hover,
                child: const Center(
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 30,
                    color: V2Color.ink,
                  ),
                ),
              );
        return Opacity(
          opacity: state.enabled ? 1 : .4,
          child: SizedBox.square(
            dimension: size + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (recording)
                  Positioned.fill(
                    child: ValueListenableBuilder<double>(
                      valueListenable: level ?? const _Zero(),
                      builder: (context, value, _) => CustomPaint(
                        painter: _ListeningRingPainter(
                          level: reduced ? 0 : value,
                        ),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: reduced ? 1 : 1 - .05 * state.depth,
                  child: face,
                ),
                if (state.focused)
                  IgnorePointer(
                    child: Container(
                      width: size + 8,
                      height: size + 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: V2Color.sky600, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Zero implements ValueListenable<double> {
  const _Zero();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  double get value => 0;
}

class _ListeningRingPainter extends CustomPainter {
  const _ListeningRingPainter({required this.level});

  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const count = 28;
    final base = V2Size.record / 2 + 6;
    final paint = Paint()..color = V2Color.sky500;
    for (var i = 0; i < count; i++) {
      final angle = i / count * math.pi * 2;
      // Uneven response so the ring reads as a voice, not a spinner.
      final response = .55 + .45 * math.sin(i * 2.7).abs();
      final reach = base + level * 9 * response;
      final r = 1.3 + level * 1.6 * response;
      paint.color = V2Color.sky500.withValues(alpha: .45 + .5 * level);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * reach, math.sin(angle) * reach),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ListeningRingPainter old) => old.level != level;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .4 + i * .25),
            shape: BoxShape.circle,
          ),
        ),
    ],
  );
}

class _FocusRing extends StatelessWidget {
  const _FocusRing({
    required this.focused,
    required this.radius,
    required this.child,
  });

  final bool focused;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!focused) return child;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius + 3),
          side: const BorderSide(
            color: V2Color.sky600,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: child,
    );
  }
}
