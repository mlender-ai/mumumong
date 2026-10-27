// One interaction physics for every V2 control (DESIGN_V2.md §7.1).
// A control sinks on touch-down with a firm spring, releases with a small
// overshoot, shifts its light, and gives haptic feedback that matches the
// weight of the action. Hover and keyboard focus use the same state.
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

enum V2Haptic { none, selection, light, medium, success }

void v2Haptic(V2Haptic haptic) {
  switch (haptic) {
    case V2Haptic.none:
      return;
    case V2Haptic.selection:
      HapticFeedback.selectionClick();
    case V2Haptic.light:
      HapticFeedback.lightImpact();
    case V2Haptic.medium:
      HapticFeedback.mediumImpact();
    case V2Haptic.success:
      HapticFeedback.mediumImpact();
  }
}

/// What a control's painter needs to render one frame of its interaction.
@immutable
class V2PressState {
  const V2PressState({
    required this.press,
    required this.hover,
    required this.focused,
    required this.enabled,
    required this.loading,
  });

  static const idle = V2PressState(
    press: 0,
    hover: 0,
    focused: false,
    enabled: true,
    loading: false,
  );

  /// Spring value. 0 at rest, 1 fully sunk; briefly below 0 on release.
  final double press;
  final double hover;
  final bool focused;
  final bool enabled;
  final bool loading;

  /// Press clamped for colors and opacities.
  double get sink => press.clamp(0.0, 1.0);

  /// Signed press for geometry, so release can overshoot past rest.
  double get depth => press.clamp(-0.35, 1.0);

  bool get interactive => enabled && !loading;
}

typedef V2PressBuilder =
    Widget Function(BuildContext context, V2PressState state);

class V2Pressable extends StatefulWidget {
  const V2Pressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.haptic = V2Haptic.selection,
    this.semanticLabel,
    this.loading = false,
    this.selected,
    this.toggled,
    this.checked,
    this.minSize = const Size(V2Size.touch, V2Size.touch),
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
  });

  final V2PressBuilder builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final V2Haptic haptic;
  final String? semanticLabel;
  final bool loading;
  final bool? selected;
  final bool? toggled;
  final bool? checked;
  final Size minSize;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;

  @override
  State<V2Pressable> createState() => _V2PressableState();
}

class _V2PressableState extends State<V2Pressable>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: V2Motion.quick,
  );
  bool _focused = false;
  bool _down = false;

  bool get _enabled => widget.onPressed != null || widget.onLongPress != null;
  bool get _interactive => _enabled && !widget.loading;

  @override
  void dispose() {
    _press.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _spring(SpringDescription description, double target) {
    if (V2Motion.reduced(context)) {
      _press.value = target;
      return;
    }
    _press.animateWith(
      SpringSimulation(
        description,
        _press.value,
        target,
        _press.velocity,
        tolerance: const Tolerance(distance: .001, velocity: .01),
      ),
    );
  }

  void _sink() {
    if (!_interactive || _down) return;
    _down = true;
    _spring(V2Motion.press, 1);
  }

  void _rise() {
    if (!_down) return;
    _down = false;
    _spring(V2Motion.release, 0);
  }

  void _activate() {
    if (!_interactive || widget.onPressed == null) return;
    v2Haptic(widget.haptic);
    widget.onPressed!();
  }

  void _keyboardActivate() {
    if (!_interactive) return;
    _sink();
    Future<void>.delayed(V2Motion.tap, () {
      if (mounted) _rise();
    });
    _activate();
  }

  @override
  void didUpdateWidget(covariant V2Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _down) _rise();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedBuilder(
      animation: Listenable.merge([_press, _hover]),
      builder: (context, _) => widget.builder(
        context,
        V2PressState(
          press: _press.value,
          hover: _hover.value,
          focused: _focused,
          enabled: _enabled,
          loading: widget.loading,
        ),
      ),
    );

    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _interactive ? (_) => _sink() : null,
      onTapUp: _interactive ? (_) => _rise() : null,
      onTapCancel: _interactive ? _rise : null,
      onTap: _interactive && widget.onPressed != null ? _activate : null,
      onLongPress: _interactive && widget.onLongPress != null
          ? () {
              _rise();
              v2Haptic(V2Haptic.medium);
              widget.onLongPress!();
            }
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minSize.width,
          minHeight: widget.minSize.height,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );

    child = FocusableActionDetector(
      enabled: _interactive,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      onShowHoverHighlight: (value) {
        if (V2Motion.reduced(context)) {
          _hover.value = value ? 1 : 0;
        } else if (value) {
          _hover.forward();
        } else {
          _hover.reverse();
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _keyboardActivate();
            return null;
          },
        ),
      },
      child: child,
    );

    final label = widget.semanticLabel;
    child = Semantics(
      container: label != null,
      button: true,
      enabled: _interactive,
      selected: widget.selected,
      toggled: widget.toggled,
      checked: widget.checked,
      label: label,
      hint: widget.loading ? '진행 중' : null,
      onTap: _interactive && widget.onPressed != null ? _activate : null,
      excludeSemantics: label != null,
      child: child,
    );
    // Without an explicit label the visible text is the button's name.
    if (label == null) child = MergeSemantics(child: child);

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}
