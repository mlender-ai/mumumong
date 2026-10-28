// V2 feedback and page scaffolding (DESIGN_V2.md §7.6): status pill,
// inline notice, toast, glass dialog, and the page frame every V2 screen
// uses so margins, atmosphere and safe areas never differ per screen.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../design/atmosphere.dart';
import '../design/keep_all.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'buttons.dart';

/// Small uppercase/meta label.
class V2Meta extends StatelessWidget {
  const V2Meta(this.text, {super.key, this.color, this.textAlign});

  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    style: V2Type.meta.copyWith(color: color),
  );
}

/// Glass status pill (Reference: "Health Improving"): one real change, said
/// once, with its reason underneath.
class V2StatusPill extends StatelessWidget {
  const V2StatusPill({
    super.key,
    required this.title,
    this.detail,
    this.icon = Icons.north_east_rounded,
  });

  final String title;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: detail == null ? title : '$title, $detail',
      excludeSemantics: true,
      child: V2Surface(
        kind: V2SurfaceKind.elevated,
        radius: V2Radius.chip,
        chroma: .5,
        padding: const EdgeInsets.fromLTRB(16, 9, 20, 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: V2Color.ink),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: V2Type.label.copyWith(fontSize: 14.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: V2Type.meta.copyWith(
                        color: V2Color.ink2,
                        letterSpacing: .1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class V2Notice extends StatelessWidget {
  const V2Notice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.actions = const [],
  });

  final String message;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: V2Surface(
        kind: V2SurfaceKind.frosted,
        radius: V2Radius.card - 8,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: V2Color.sky700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v2KeepAll(message),
                    style: V2Type.bodySmall.copyWith(color: V2Color.ink),
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 4, runSpacing: 0, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

void showV2Toast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(V2Space.md, 0, V2Space.md, 96),
        content: V2Surface(
          kind: V2SurfaceKind.floating,
          radius: V2Radius.card - 6,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Text(
            v2KeepAll(message),
            style: V2Type.bodySmall.copyWith(color: V2Color.ink),
          ),
        ),
      ),
    );
}

/// A glass dialog. [actions] are V2 buttons, primary last.
Future<T?> showV2Dialog<T>(
  BuildContext context, {
  required String title,
  String? body,
  Widget? content,
  required List<Widget> Function(BuildContext dialogContext) actions,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: '닫기',
    barrierColor: V2Color.ink.withValues(alpha: .18),
    transitionDuration: V2Motion.of(context, V2Motion.base),
    pageBuilder: (dialogContext, _, _) => PopScope(
      canPop: dismissible,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(V2Space.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                type: MaterialType.transparency,
                child: V2Surface(
                  kind: V2SurfaceKind.floating,
                  radius: V2Radius.card,
                  chroma: .3,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: V2Type.title),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: 10),
                        Text(v2KeepAll(body), style: V2Type.body),
                      ],
                      if (content != null) ...[
                        const SizedBox(height: 14),
                        content,
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: actions(dialogContext),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: V2Motion.settle);
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 6 * animation.value,
          sigmaY: 6 * animation.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: .97, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// The frame of every V2 screen: atmosphere behind, safe area, editorial
/// gutter and a readable maximum width.
class V2Page extends StatelessWidget {
  const V2Page({
    super.key,
    required this.mood,
    required this.child,
    this.energy = 0,
    this.stage = 0,
    this.resizeToAvoidBottomInset = true,
    this.bottom,
  });

  final V2Mood mood;
  final Widget child;
  final double energy;
  final int stage;
  final bool resizeToAvoidBottomInset;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Color.paper,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: true,
      bottomNavigationBar: bottom,
      body: V2Atmosphere(
        mood: mood,
        energy: energy,
        stage: stage,
        child: child,
      ),
    );
  }
}

/// Content fades into the space at the top edge instead of being cut off
/// under the status bar. A full-bleed scroll view passes the status bar
/// height as [inset]: nothing shows above it, then content fades in over
/// [extent].
class V2EdgeFade extends StatelessWidget {
  const V2EdgeFade({
    super.key,
    required this.child,
    this.extent = 22,
    this.inset = 0,
  });

  final Widget child;
  final double extent;
  final double inset;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Colors.white,
        Colors.white,
      ],
      stops: [
        0,
        (inset / rect.height).clamp(0.0, 1.0),
        ((inset + extent) / rect.height).clamp(0.0, 1.0),
        1,
      ],
    ).createShader(rect),
    child: child,
  );
}

/// Primary action plus quiet alternatives, stacked with V2 spacing.
class V2ActionStack extends StatelessWidget {
  const V2ActionStack({
    super.key,
    required this.primary,
    this.secondary = const [],
  });

  final Widget primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      primary,
      for (final action in secondary) ...[
        const SizedBox(height: V2Space.xs),
        Center(child: action),
      ],
    ],
  );
}

/// Convenience for the ink primary action at full width.
class V2PrimaryAction extends StatelessWidget {
  const V2PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => V2Button(
    label: label,
    onPressed: onPressed,
    loading: loading,
    loadingLabel: loadingLabel,
    icon: icon,
    expand: true,
  );
}

/// A centred line of state inside a page: a real wait (with still dots),
/// an empty list, or a failure with one way forward.
class V2InlineStatus extends StatelessWidget {
  const V2InlineStatus(
    this.message, {
    super.key,
    this.waiting = false,
    this.action,
  });

  final String message;
  final bool waiting;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: V2Space.xl),
    child: Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Text(
            v2KeepAll(message),
            textAlign: TextAlign.center,
            style: V2Type.body.copyWith(color: V2Color.ink2),
          ),
          if (waiting) ...[
            const SizedBox(height: V2Space.sm),
            const ExcludeSemantics(child: V2LoadingDots(color: V2Color.sky600)),
          ],
          if (action case final widget?) ...[
            const SizedBox(height: V2Space.md),
            widget,
          ],
        ],
      ),
    ),
  );
}
