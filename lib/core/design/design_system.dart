import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract final class MongColor {
  // Keep the app canvas identical to the opaque white iOS/PWA system surround.
  static const paper = Color(0xFFFFFFFF);
  static const paperPure = Color(0xFFFFFFFF);
  static const paperShade = Color(0xFFF3F4F4);
  static const line = Color(0xFFE8E5DF);
  static const ink = Color(0xFF1E1D1B);
  static const ink2 = Color(0xFF55524D);
  static const ink3 = Color(0xFF74716B);
  static const sky100 = Color(0xFFE8F0F4);
  static const sky300 = Color(0xFFC2D8E4);
  static const sky500 = Color(0xFF93B9CF);
  static const sky700 = Color(0xFF4D7C9B);
  static const orbInk = Color(0xFF294E72);
  static const dreamBlue = Color(0xFF238DC9);
  static const dreamBlueDeep = Color(0xFF176A9A);
  static const dreamMist = Color(0xFFEAF7FD);

  static const nightPaper = Color(0xFF161513);
  static const nightShade = Color(0xFF201F1C);
  static const nightInk = Color(0xFFE8E5DF);
  static const nightMeta = Color(0xFF9C9891);
  static const nightSky = Color(0xFF7FA3BA);
}

/// Semantic roles shared by every UI surface; raw primitives stay above.
extension MongPalette on BuildContext {
  bool get isNight => Theme.of(this).brightness == Brightness.dark;
  Color get canvas => isNight ? const Color(0xFF050C18) : MongColor.paper;
  Color get raised => isNight ? const Color(0xFF111C2B) : MongColor.paperPure;
  Color get subtle => isNight ? const Color(0xFF152131) : MongColor.paperShade;
  Color get primaryInk => isNight ? MongColor.nightInk : MongColor.ink;
  Color get secondaryInk => isNight ? const Color(0xFFBEC7D1) : MongColor.ink2;
  Color get metaInk => isNight ? const Color(0xFFA5B2C1) : MongColor.ink3;
  Color get hairline => isNight ? const Color(0xFF314055) : MongColor.line;
}

abstract final class MongMotion {
  static const micro = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 420);
  static const settle = Duration(milliseconds: 1500);
  static const reveal = Duration(milliseconds: 2400);
  static const enter = Cubic(0.22, 1, 0.36, 1);
  static const pageCurve = Cubic(0.65, 0, 0.35, 1);
  static const form = Cubic(0.33, 0, 0.15, 1);
}

/// One 4 px rhythm for screen layout and component internals.
abstract final class MongSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screen = 24.0;
  static const modal = 24.0;
}

abstract final class MongRadius {
  static const field = 20.0;
  static const panel = 28.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

abstract final class MongSize {
  static const touch = 44.0;
  static const action = 52.0;
  static const field = 56.0;
  static const modalMaxWidth = 480.0;
}

abstract final class MongGlass {
  static const actionHeight = MongSize.action;
  static const actionMaxWidth = 280.0;
  static const cornerRadius = MongSize.action / 2;
  static const blur = 18.0;
  static const stroke = 1.0;
}

/// Shared title rhythm for the navigable library/settings surfaces.
class MongPageHeader extends StatelessWidget {
  const MongPageHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      MongSpace.screen,
      MongSpace.lg,
      MongSpace.screen,
      MongSpace.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MongSpace.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: MongSpace.sm),
                trailing!,
              ],
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: MongSpace.xs),
          Text(
            description!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
        ],
      ],
    ),
  );
}

/// A quiet state page: breathing room surrounds the group, never separates
/// related copy from its action. Long text grows into a scrollable layout.
class MongFlowPage extends StatelessWidget {
  const MongFlowPage({super.key, required this.content, required this.actions});
  final Widget content;
  final Widget actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(MongSpace.screen),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - MongSpace.screen * 2).clamp(
            0.0,
            double.infinity,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: MongSpace.xl),
            actions,
          ],
        ),
      ),
    ),
  );
}

/// Same 280px primary width as entry, with low-emphasis supporting navigation.
class MongActionGroup extends StatelessWidget {
  const MongActionGroup({
    super.key,
    required this.primary,
    this.secondary = const [],
    this.secondaryColor,
  });
  final Widget primary;
  final List<Widget> secondary;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: MongGlass.actionMaxWidth),
          child: primary,
        ),
      ),
      if (secondary.isNotEmpty) ...[
        const SizedBox(height: MongSpace.xs),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: secondaryColor ?? context.secondaryInk,
              minimumSize: const Size(MongSize.touch, MongSize.touch),
              padding: const EdgeInsets.symmetric(horizontal: MongSpace.sm),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400),
              shape: const StadiumBorder(),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: MongSpace.xs,
            children: secondary,
          ),
        ),
      ],
    ],
  );
}

/// Shared translucent surface for compact overlays, never for manuscript text.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = MongRadius.panel,
    this.opacity = .3,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final double opacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: (opacity + .14).clamp(0, 1)),
                Colors.white.withValues(alpha: opacity.clamp(0, 1)),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .72),
              width: MongGlass.stroke,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

ThemeData mumumongTheme() {
  const uiText = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 36,
      height: 1.2,
      letterSpacing: -1.2,
      color: MongColor.ink,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 28,
      height: 1.3,
      letterSpacing: -.6,
      color: MongColor.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.35,
      color: MongColor.ink,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.4,
      color: MongColor.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
      fontSize: 18,
      height: 1.75,
      color: MongColor.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.55,
      color: MongColor.ink,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.5,
      color: MongColor.ink2,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.25,
      color: MongColor.ink,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.4,
      color: MongColor.ink2,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
      fontSize: 12,
      height: 1.4,
      letterSpacing: .44,
      color: MongColor.ink3,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: MongColor.paper,
    colorScheme: const ColorScheme.light(
      primary: MongColor.ink,
      onPrimary: MongColor.paper,
      surface: MongColor.paper,
      onSurface: MongColor.ink,
      outline: MongColor.line,
    ),
    fontFamily: 'Pretendard',
    textTheme: uiText,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: const DividerThemeData(
      color: MongColor.line,
      thickness: .5,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: MongColor.ink,
      selectionColor: MongColor.sky300,
      selectionHandleColor: MongColor.sky700,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      constraints: BoxConstraints(maxWidth: MongSize.modalMaxWidth),
      backgroundColor: MongColor.paperPure,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MongRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      constraints: const BoxConstraints(maxWidth: MongSize.modalMaxWidth),
      backgroundColor: MongColor.paperPure,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: EdgeInsets.symmetric(horizontal: MongSpace.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.panel)),
      ),
      titleTextStyle: uiText.titleMedium,
      contentTextStyle: uiText.bodyMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MongColor.paperShade,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MongSpace.md,
        vertical: MongSpace.md,
      ),
      hintStyle: uiText.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.field)),
        borderSide: BorderSide(color: MongColor.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.field)),
        borderSide: BorderSide(color: MongColor.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.field)),
        borderSide: BorderSide(color: MongColor.sky700, width: 1.5),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: MongSpace.screen),
      iconColor: MongColor.ink2,
      textColor: MongColor.ink,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MongColor.ink,
        disabledForegroundColor: MongColor.ink3,
        minimumSize: const Size(MongSize.touch, MongSize.touch),
        padding: const EdgeInsets.symmetric(horizontal: MongSpace.md),
        textStyle: uiText.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: MongColor.ink,
        minimumSize: const Size(MongSize.touch, MongSize.touch),
        shape: const CircleBorder(),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? MongColor.ink
            : MongColor.paperPure,
      ),
      checkColor: const WidgetStatePropertyAll(MongColor.paperPure),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MongSpace.xxs),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: MongColor.ink,
      contentTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        color: MongColor.paperPure,
        fontSize: 14,
        height: 1.5,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.field)),
      ),
    ),
  );
}

/// Shared handle for all bottom sheets. Sheets keep 24 px content insets.
class MongSheetHandle extends StatelessWidget {
  const MongSheetHandle({super.key, this.color = MongColor.line});

  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: color == MongColor.line ? context.hairline : color,
        borderRadius: BorderRadius.circular(MongRadius.pill),
      ),
    ),
  );
}

class MetaText extends StatelessWidget {
  const MetaText(this.text, {super.key, this.color, this.textAlign});

  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: color ?? context.metaInk),
    );
  }
}

/// The same colorless glass action on entry, consent and the main app.
class GlassActionButton extends StatefulWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.lightContent = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool lightContent;
  final IconData? icon;

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (widget.onPressed == null || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(MongGlass.cornerRadius);
    final light =
        widget.lightContent || Theme.of(context).brightness == Brightness.dark;
    final foreground = light ? Colors.white : MongColor.ink;
    final button = Opacity(
      opacity: widget.onPressed == null ? .48 : 1,
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : MongMotion.micro,
        curve: MongMotion.enter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF3B506A,
                ).withValues(alpha: _pressed ? .10 : .07),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: MongGlass.blur,
                sigmaY: MongGlass.blur,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  onHighlightChanged: _setPressed,
                  borderRadius: radius,
                  child: AnimatedContainer(
                    duration: MongMotion.micro,
                    curve: MongMotion.enter,
                    constraints: const BoxConstraints(
                      minHeight: MongGlass.actionHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MongSpace.lg,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (light ? Colors.white : const Color(0xFFF4F8FC))
                              .withValues(
                                alpha: light
                                    ? .16
                                    : _pressed
                                    ? .80
                                    : .66,
                              ),
                          Colors.white.withValues(
                            alpha: light
                                ? .06
                                : _pressed
                                ? .64
                                : .42,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: light
                            ? Colors.white.withValues(alpha: .32)
                            : const Color(0xFF62778D).withValues(alpha: .14),
                        width: MongGlass.stroke,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: widget.expanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 19, color: foreground),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: foreground),
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
    );
    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class EditorialButton extends StatelessWidget {
  const EditorialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.dark = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool dark;

  @override
  Widget build(BuildContext context) =>
      GlassActionButton(label: label, onPressed: onPressed, expanded: expanded);
}

class QuietTextButton extends StatelessWidget {
  const QuietTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassActionButton(
      label: label,
      onPressed: onPressed,
      expanded: false,
    );
  }
}

class ChoiceChipEditorial extends StatelessWidget {
  const ChoiceChipEditorial({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MongSize.touch),
          child: AnimatedContainer(
            duration: MongMotion.micro,
            padding: const EdgeInsets.symmetric(
              horizontal: MongSpace.md,
              vertical: MongSpace.sm,
            ),
            decoration: BoxDecoration(
              color: night
                  ? (selected
                        ? const Color(0xFF203D54)
                        : const Color(0xFF152131))
                  : selected
                  ? MongColor.dreamMist
                  : MongColor.paperShade,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: night
                    ? (selected ? MongColor.nightSky : const Color(0xFF314055))
                    : selected
                    ? MongColor.sky300
                    : MongColor.line,
                width: 1,
              ),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}

PageRoute<T> quietPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: MongMotion.page,
    reverseTransitionDuration: MongMotion.page,
    pageBuilder: (_, animation, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: MongMotion.pageCurve,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .05),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
