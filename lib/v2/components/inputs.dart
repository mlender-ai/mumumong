// V2 inputs (DESIGN_V2.md §7.3): text capture, focused state, choices.
// The capture field is a lit glass well; its chromatic light gathers as the
// user writes, which is the same signal the memory dots respond to.
import 'package:flutter/material.dart';

import '../design/press.dart';
import '../design/surface.dart';
import '../design/tokens.dart';

class V2CaptureField extends StatefulWidget {
  const V2CaptureField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.recording = false,
    this.energy = 0,
    this.enabled = true,
    this.fieldKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool recording;

  /// 0..1 amount remembered so far; drives the field's light.
  final double energy;
  final bool enabled;
  final Key? fieldKey;

  @override
  State<V2CaptureField> createState() => _V2CaptureFieldState();
}

class _V2CaptureFieldState extends State<V2CaptureField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant V2CaptureField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final lit = widget.recording ? 1.0 : (focused ? 1.0 : 0.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: lit),
      duration: V2Motion.of(context, V2Motion.base),
      curve: V2Motion.settle,
      builder: (context, t, child) => Stack(
        fit: StackFit.expand,
        children: [
          V2Surface(
            kind: V2SurfaceKind.elevated,
            radius: V2Radius.field,
            padding: EdgeInsets.zero,
            chroma: .18 + widget.energy * .55 + (widget.recording ? .2 : 0),
            hover: t * .6,
            child: const SizedBox.expand(),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(V2Radius.field),
                  side: BorderSide(
                    color: (widget.recording ? V2Color.sky500 : V2Color.sky400)
                        .withValues(alpha: .9 * t),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          enableIMEPersonalizedLearning: false,
          expands: true,
          minLines: null,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: V2Color.sky600,
          cursorWidth: 2,
          style: V2Type.capture,
          decoration: InputDecoration.collapsed(
            hintText: widget.hint,
            hintStyle: V2Type.capture.copyWith(color: V2Color.ink3),
          ),
        ),
      ),
    );
  }
}

/// A single-choice chip. Selected chips become ink with a sky dot.
class V2ChoiceChip extends StatelessWidget {
  const V2ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onSelected,
      selected: selected,
      semanticLabel: label,
      builder: (context, state) {
        final reduced = V2Motion.reduced(context);
        return Opacity(
          opacity: state.enabled ? 1 : .45,
          child: Transform.scale(
            scale: reduced ? 1 : 1 - .04 * state.depth,
            child: V2Surface(
              kind: selected ? V2SurfaceKind.ink : V2SurfaceKind.frosted,
              radius: V2Radius.chip,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sink: state.sink,
              hover: state.hover,
              chroma: selected ? 0 : .15,
              blur: 0,
              shadow: !selected,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: V2Motion.of(context, V2Motion.quick),
                    width: selected ? 6 : 0,
                    height: 6,
                    margin: EdgeInsets.only(right: selected ? 8 : 0),
                    decoration: const BoxDecoration(
                      color: V2Color.sky300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    label,
                    style: V2Type.label.copyWith(
                      fontSize: 14.5,
                      color: selected ? Colors.white : V2Color.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A consent/confirmation row with a round check made of light.
class V2CheckRow extends StatelessWidget {
  const V2CheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      checked: value,
      semanticLabel: label,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: V2Motion.of(context, V2Motion.quick),
              curve: V2Motion.settle,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? V2Color.sky600
                    : Colors.white.withValues(alpha: .7),
                border: Border.all(
                  color: value
                      ? V2Color.sky600
                      : V2Color.ink3.withValues(alpha: .55),
                  width: 1.4,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: V2Color.sky500.withValues(alpha: .35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: V2Type.body.copyWith(
                  color: V2Color.ink,
                  decoration: state.hover > .5
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glass segmented control with a sliding paper thumb.
class V2Segmented<T> extends StatelessWidget {
  const V2Segmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.$1 == value);
    return V2Surface(
      kind: V2SurfaceKind.frosted,
      radius: V2Radius.chip,
      padding: const EdgeInsets.all(4),
      blur: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: V2Motion.of(context, V2Motion.base),
                curve: V2Motion.settle,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: const V2Surface(
                  kind: V2SurfaceKind.paper,
                  radius: V2Radius.chip,
                  padding: EdgeInsets.zero,
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: V2Pressable(
                        onPressed: () => onChanged(segment.$1),
                        selected: segment.$1 == value,
                        semanticLabel: segment.$2,
                        builder: (context, state) => Center(
                          child: Text(
                            segment.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: V2Type.label.copyWith(
                              fontSize: 14,
                              color: segment.$1 == value
                                  ? V2Color.ink
                                  : V2Color.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A short single-line field on paper (confirmation words, small edits).
class V2TextField extends StatelessWidget {
  const V2TextField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => V2Surface(
    kind: V2SurfaceKind.paper,
    radius: V2Radius.small,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: TextField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      style: V2Type.body.copyWith(color: V2Color.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: V2Type.bodySmall.copyWith(color: V2Color.ink3),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
    ),
  );
}
