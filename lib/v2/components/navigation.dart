// V2 navigation (DESIGN_V2.md §7.4): floating navigation with the capture
// CTA at its center, a contextual header that turns to glass only when
// content passes under it, glass bottom sheets and the reader navigation.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../design/dot_matrix.dart';
import '../design/press.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'buttons.dart';

@immutable
class V2NavItem {
  const V2NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class V2FloatingNav extends StatelessWidget {
  const V2FloatingNav({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.ctaLabel,
    required this.onCta,
    this.ctaIcon = Icons.edit_outlined,
  }) : assert(items.length == 2);

  final List<V2NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final String ctaLabel;
  final VoidCallback onCta;
  final IconData ctaIcon;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Like an iOS tab bar, the floating nav caps text growth so it never
    // covers content; every target keeps its label for assistive tech.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          V2Space.md,
          0,
          V2Space.md,
          bottom > 0 ? bottom - 6 : V2Space.md,
        ),
        child: Center(
          heightFactor: 1,
          child: V2Surface(
            kind: V2SurfaceKind.floating,
            radius: V2Radius.chip,
            padding: const EdgeInsets.all(6),
            chroma: .22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavTab(
                  item: items[0],
                  selected: selected == 0,
                  onTap: () => onSelect(0),
                ),
                const SizedBox(width: 4),
                V2Button(
                  label: ctaLabel,
                  icon: ctaIcon,
                  onPressed: onCta,
                  size: V2ButtonSize.compact,
                  haptic: V2Haptic.medium,
                ),
                const SizedBox(width: 4),
                _NavTab(
                  item: items[1],
                  selected: selected == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final V2NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: item.label,
      minSize: const Size(64, 46),
      builder: (context, state) => Transform.scale(
        scale: V2Motion.reduced(context) ? 1 : 1 - .05 * state.depth,
        child: SizedBox(
          width: 68,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? V2Color.ink : V2Color.ink3,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: V2Type.meta.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 0,
                  color: selected ? V2Color.ink : V2Color.ink3,
                ),
              ),
              AnimatedContainer(
                duration: V2Motion.of(context, V2Motion.quick),
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? V2Color.sky500 : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header that floats over content. It is clear at rest and becomes glass
/// once something scrolls under it ([elevated]).
class V2ContextHeader extends StatelessWidget {
  const V2ContextHeader({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.elevated = false,
    this.night = false,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final bool elevated;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedContainer(
      duration: V2Motion.of(context, V2Motion.base),
      padding: EdgeInsets.fromLTRB(12, top + 6, 12, 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: V2Motion.of(context, V2Motion.base),
                opacity: elevated ? 1 : 0,
                child: night
                    ? const ColoredBox(color: V2Color.nightPaper)
                    : const V2Surface(
                        kind: V2SurfaceKind.floating,
                        radius: V2Radius.chip,
                        padding: EdgeInsets.zero,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                leading ?? const SizedBox(width: V2Size.touch),
                const SizedBox(width: V2Space.xs),
                Expanded(child: Center(child: title)),
                const SizedBox(width: V2Space.xs),
                trailing ?? const SizedBox(width: V2Size.touch),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a glass bottom sheet with the V2 handle, padding and barrier.
Future<T?> showV2Sheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool night = false,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: V2Color.ink.withValues(alpha: .22),
    elevation: 0,
    builder: (sheetContext) =>
        V2SheetFrame(night: night, child: builder(sheetContext)),
  );
}

class V2SheetFrame extends StatelessWidget {
  const V2SheetFrame({super.key, required this.child, this.night = false});

  final Widget child;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        V2Space.lg,
        10,
        V2Space.lg,
        V2Space.lg + bottom + keyboard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: (night ? V2Color.nightMeta : V2Color.ink3).withValues(
                  alpha: .45,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: V2Space.md),
          Flexible(child: child),
        ],
      ),
    );
    // Shrink-wrap the content: the barrier above must stay tappable.
    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
        child: ClipRSuperellipse(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(V2Radius.sheet),
          ),
          child: night
              ? ColoredBox(color: const Color(0xFF26241F), child: content)
              : BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: V2Glass.heavyBlur,
                    sigmaY: V2Glass.heavyBlur,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          V2Color.paperPure.withValues(alpha: .93),
                          V2Color.paper.withValues(alpha: .97),
                        ],
                      ),
                      border: const Border(
                        top: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Reader navigation: previous / scene position / next on floating glass.
class V2ReaderNav extends StatelessWidget {
  const V2ReaderNav({
    super.key,
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    this.night = false,
  });

  final int index;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPick;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final ink = night ? V2Color.nightInk : V2Color.ink;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        V2IconButton(
          icon: Icons.chevron_left_rounded,
          semanticLabel: '이전 장면',
          variant: V2IconButtonVariant.plain,
          color: ink,
          onPressed: onPrevious,
        ),
        V2Pressable(
          onPressed: onPick,
          semanticLabel: '장면 ${index + 1} / $count · 장면 고르기',
          minSize: const Size(120, V2Size.touch),
          builder: (context, state) => Opacity(
            opacity: 1 - state.sink * .3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  V2DotMatrix('${index + 1}', pitch: 2.2, color: ink),
                  const SizedBox(width: 6),
                  V2DotMatrix(
                    '/$count',
                    pitch: 2.2,
                    color: night ? V2Color.nightMeta : V2Color.ink3,
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.expand_less_rounded, size: 18, color: ink),
                ],
              ),
            ),
          ),
        ),
        V2IconButton(
          icon: Icons.chevron_right_rounded,
          semanticLabel: '다음 장면',
          variant: V2IconButtonVariant.plain,
          color: ink,
          onPressed: onNext,
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom - 4 : V2Space.md),
      child: Center(
        heightFactor: 1,
        child: night
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2824),
                  borderRadius: BorderRadius.circular(V2Radius.chip),
                  border: Border.all(color: V2Color.nightLine),
                ),
                child: Padding(padding: const EdgeInsets.all(4), child: body),
              )
            : V2Surface(
                kind: V2SurfaceKind.floating,
                radius: V2Radius.chip,
                padding: const EdgeInsets.all(4),
                child: body,
              ),
      ),
    );
  }
}
