// V2 list rows (DESIGN_V2.md §7.6): settings and account pages. Every row is
// a V2Pressable over a frosted surface, so rows share the button physics.
import 'package:flutter/material.dart';

import '../design/press.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'feedback.dart';

/// A group caption above a run of rows.
class V2GroupLabel extends StatelessWidget {
  const V2GroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, V2Space.lg, 4, V2Space.xs),
    child: Semantics(header: true, child: V2Meta(label)),
  );
}

/// A navigation or action row: title, one line of detail, a quiet chevron.
class V2ListRow extends StatelessWidget {
  const V2ListRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.trailing,
    this.busy = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? trailing;

  /// The row's action is running; it stays visible but does not accept taps.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final ink = destructive ? V2Color.alert : V2Color.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: V2Space.xs),
      child: V2Pressable(
        onPressed: enabled ? onTap : null,
        loading: busy,
        semanticLabel: subtitle == null ? title : '$title, $subtitle',
        builder: (context, state) => V2Surface(
          kind: V2SurfaceKind.frosted,
          radius: V2Radius.field,
          sink: state.sink,
          hover: state.hover,
          blur: 0,
          padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
          child: Opacity(
            opacity: onTap == null ? .5 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: V2Type.headline.copyWith(
                          fontSize: 17,
                          color: ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: V2Type.bodySmall.copyWith(color: V2Color.ink3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: V2Space.xs),
                trailing ??
                    Icon(
                      busy
                          ? Icons.more_horiz_rounded
                          : Icons.chevron_right_rounded,
                      size: 22,
                      color: destructive ? V2Color.alert : V2Color.ink3,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An on/off row. The track is light (sky) when on, a hairline when off.
class V2SwitchRow extends StatelessWidget {
  const V2SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: V2Space.xs),
      child: V2Pressable(
        onPressed: enabled ? () => onChanged!(!value) : null,
        toggled: value,
        semanticLabel: subtitle == null ? title : '$title, $subtitle',
        builder: (context, state) => V2Surface(
          kind: V2SurfaceKind.frosted,
          radius: V2Radius.field,
          sink: state.sink,
          hover: state.hover,
          blur: 0,
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Opacity(
            opacity: enabled ? 1 : .55,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: V2Type.headline.copyWith(fontSize: 17),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: V2Type.bodySmall.copyWith(color: V2Color.ink3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: V2Space.sm),
                _Track(on: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final duration = V2Motion.of(context, V2Motion.quick);
    return AnimatedContainer(
      duration: duration,
      curve: V2Motion.settle,
      width: 50,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(V2Radius.chip),
        color: on ? V2Color.sky600 : V2Color.well,
        border: Border.all(
          color: on ? V2Color.sky600 : V2Color.ink3.withValues(alpha: .45),
          width: 1.2,
        ),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: V2Motion.settle,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: V2Color.inkDot.withValues(alpha: .18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
