// Single implementation of DESIGN.md. Every value here maps 1:1 to a token
// in DESIGN.md; change the document first, then this file, never a screen.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// DESIGN.md §2.1 primitives.
abstract final class MongColor {
  // Level 0 canvas is a warm white; the PWA shell, manifest and system bars
  // use the same value so no band appears at the edges.
  static const paper = Color(0xFFFBFAF7);
  static const paperPure = Color(0xFFFFFFFF);
  static const paperShade = Color(0xFFF3F2EE);
  static const line = Color(0xFFE8E5DF);
  static const ink = Color(0xFF1E1D1B);
  static const ink2 = Color(0xFF55524D);
  // Meta ink must hold 4.5:1 even over the atmosphere's lightest tint.
  static const ink3 = Color(0xFF6B6862);
  static const alert = Color(0xFF9B514B);

  static const sky50 = Color(0xFFEEF7FC);
  static const sky100 = Color(0xFFDDEFF9);
  static const sky200 = Color(0xFFBFE2F5);
  static const sky300 = Color(0xFF9ED3EF);
  static const sky400 = Color(0xFF72C0E7);
  static const sky500 = Color(0xFF4FAADD);
  static const sky600 = Color(0xFF2F8FC7);
  static const sky700 = Color(0xFF1F6FA0);
  static const sky800 = Color(0xFF174F73);
  static const orbInk = Color(0xFF294E72);

  // Atmosphere lights (DESIGN.md §3). lightSoft replaces the former indigo.
  static const lightSky = Color(0xFF72CBF2);
  static const lightDeep = Color(0xFF288FD4);
  static const lightSoft = Color(0xFF5A8DD8);
  static const lightHaze = Color(0xFFE7F7FF);

  static const nightCanvas = Color(0xFF050C18);
  static const nightRaised = Color(0xFF111C2B);
  static const nightSubtle = Color(0xFF152131);
  static const nightInk = Color(0xFFE8E5DF);
  static const nightInk2 = Color(0xFFBEC7D1);
  static const nightMeta = Color(0xFFA5B2C1);
  static const nightLine = Color(0xFF314055);
  static const nightSky = Color(0xFF7FA3BA);
  static const nightAccentSoft = Color(0xFF203D54);

  /// Reader-only warm night paper; the app night canvas stays nightCanvas.
  static const readerNightPaper = Color(0xFF161513);
  static const readerNightMeta = Color(0xFF9C9891);
  static const readerNightLine = Color(0xFF2B2926);

  // Legacy aliases kept for existing call sites; new code uses the names above.
  static const dreamBlue = sky600;
  static const dreamBlueDeep = sky700;
  static const dreamMist = sky50;
  static const nightPaper = readerNightPaper;
  static const nightShade = Color(0xFF201F1C);
}

/// DESIGN.md §2.2 semantic roles. Raw primitives stay in [MongColor].
extension MongPalette on BuildContext {
  bool get isNight => Theme.of(this).brightness == Brightness.dark;
  Color get canvas => isNight ? MongColor.nightCanvas : MongColor.paper;
  Color get raised => isNight ? MongColor.nightRaised : MongColor.paperPure;
  Color get subtle => isNight ? MongColor.nightSubtle : MongColor.paperShade;
  Color get primaryInk => isNight ? MongColor.nightInk : MongColor.ink;
  Color get secondaryInk => isNight ? MongColor.nightInk2 : MongColor.ink2;
  Color get metaInk => isNight ? MongColor.nightMeta : MongColor.ink3;
  Color get hairline => isNight ? MongColor.nightLine : MongColor.line;
  Color get accent => isNight ? MongColor.nightSky : MongColor.sky600;
  Color get accentSoft =>
      isNight ? MongColor.nightAccentSoft : MongColor.sky100;
  Color get accentInk => isNight ? MongColor.nightSky : MongColor.sky700;
  Color get alertInk => isNight ? const Color(0xFFD08A84) : MongColor.alert;
}

/// DESIGN.md §9 motion tokens. Screens never declare their own durations.
abstract final class MongMotion {
  static const micro = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 420);
  static const settle = Duration(milliseconds: 650);
  static const gather = Duration(milliseconds: 900);
  static const growth = Duration(milliseconds: 1400);
  static const reveal = Duration(milliseconds: 2400);
  static const atmosphere = Duration(seconds: 14);
  static const revealStagger = Duration(milliseconds: 90);
  static const revealItem = Duration(milliseconds: 320);
  static const enter = Cubic(0.22, 1, 0.36, 1);
  static const pageCurve = Cubic(0.65, 0, 0.35, 1);
  static const form = Cubic(0.33, 0, 0.15, 1);
  static const pressScale = .975;

  /// Zero when the platform asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
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

  /// Top inset inside a panel/sheet before its first line.
  static const panel = 28.0;
}

abstract final class MongRadius {
  static const field = 20.0;
  static const tab = 22.0;
  static const panel = 28.0;
  static const sheet = 28.0;
  static const nav = 31.0;
  static const chip = 999.0;
  static const pill = 999.0;
}

abstract final class MongSize {
  static const touch = 44.0;
  static const action = 52.0;
  static const field = 56.0;
  static const nav = 62.0;
  static const modalMaxWidth = 480.0;
  static const formMaxWidth = 620.0;
  static const readingMaxWidth = 720.0;
  static const actionMaxWidth = 280.0;
}

/// DESIGN.md §6 glass values. Sigma and alphas are the only knobs.
abstract final class MongGlass {
  static const actionHeight = MongSize.action;
  static const actionMaxWidth = MongSize.actionMaxWidth;
  static const cornerRadius = MongSize.action / 2;
  static const blur = 16.0;
  static const elevatedBlur = 20.0;
  static const stroke = 1.0;
  static const frostedAlpha = .72;
  static const frostedPressedAlpha = .82;
  static const elevatedAlpha = .92;
  static const edgeAlpha = .72;
  static const slateEdge = Color(0xFF62778D);
  static const slateEdgeAlpha = .14;
}

/// DESIGN.md §5 elevation: exactly three shadows.
abstract final class MongShadow {
  static const whisper = [
    BoxShadow(color: Color(0x0A1E1D1B), blurRadius: 32, offset: Offset(0, 8)),
  ];
  static const float = [
    BoxShadow(color: Color(0x123B506A), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const modal = [
    BoxShadow(color: Color(0x1F1E1D1B), blurRadius: 40, offset: Offset(0, 12)),
  ];
}

/// The manuscript text style, defined once (DESIGN.md §4).
TextStyle manuscriptStyle(BuildContext context, {double scale = 1}) {
  final base = Theme.of(context).textTheme.bodyLarge!;
  return base.copyWith(fontSize: 18 * scale, color: context.primaryInk);
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

/// DESIGN.md §6 surface levels.
enum MongSurfaceLevel { paper, glass, elevated }

/// One translucent surface; never stacked on another glass, never under
/// manuscript text. `paper` is opaque and casts no shadow.
class MongSurface extends StatelessWidget {
  const MongSurface({
    super.key,
    required this.child,
    this.level = MongSurfaceLevel.glass,
    this.radius = MongRadius.panel,
    this.padding = EdgeInsets.zero,
    this.shadow = true,
  });

  final Widget child;
  final MongSurfaceLevel level;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    if (level == MongSurfaceLevel.paper) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.raised,
          borderRadius: border,
          border: Border.all(color: context.hairline, width: MongGlass.stroke),
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    final night = context.isNight;
    final elevated = level == MongSurfaceLevel.elevated;
    final alpha = elevated ? MongGlass.elevatedAlpha : MongGlass.frostedAlpha;
    final sigma = elevated ? MongGlass.elevatedBlur : MongGlass.blur;
    final tint = night ? MongColor.nightRaised : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: !shadow
            ? null
            : elevated
            ? MongShadow.modal
            : MongShadow.float,
      ),
      child: ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: border,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: (alpha + .1).clamp(0, 1)),
                  tint.withValues(alpha: alpha),
                ],
              ),
              border: Border.all(
                color: night
                    ? Colors.white.withValues(alpha: .18)
                    : Colors.white.withValues(alpha: MongGlass.edgeAlpha),
                width: MongGlass.stroke,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Legacy name for a frosted panel; prefer [MongSurface].
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
  Widget build(BuildContext context) => MongSurface(
    radius: radius,
    padding: padding,
    shadow: false,
    child: child,
  );
}

ThemeData mumumongTheme() {
  const uiText = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
      fontSize: 36,
      height: 1.2,
      letterSpacing: -.6,
      color: MongColor.ink,
    ),
    displayMedium: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
      fontSize: 28,
      height: 1.3,
      letterSpacing: -.4,
      color: MongColor.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
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
      secondary: MongColor.sky600,
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
      selectionColor: MongColor.sky200,
      selectionHandleColor: MongColor.sky600,
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
      fillColor: MongColor.paperPure,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MongSpace.md,
        vertical: MongSpace.md,
      ),
      hintStyle: uiText.bodyMedium?.copyWith(color: MongColor.ink2),
      errorStyle: uiText.bodySmall?.copyWith(color: MongColor.alert),
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
        borderSide: BorderSide(color: MongColor.sky600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(MongRadius.field)),
        borderSide: BorderSide(color: MongColor.alert),
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
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(MongColor.paperPure),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? MongColor.sky500
            : MongColor.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
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

/// The brand wordmark, one component (DESIGN.md §4). `animate` draws the
/// letters once from a soft sky tint into ink; it never loops.
class MongWordmark extends StatefulWidget {
  const MongWordmark({super.key, this.animate = false, this.color});
  final bool animate;
  final Color? color;

  @override
  State<MongWordmark> createState() => _MongWordmarkState();
}

class _MongWordmarkState extends State<MongWordmark>
    with SingleTickerProviderStateMixin {
  late final _settle = AnimationController(
    vsync: this,
    duration: MongMotion.gather,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _settle.value = 1;
    } else if (_settle.value == 0 && !_settle.isAnimating) {
      _settle.forward();
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.color ?? context.primaryInk;
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 2.4,
    );
    return Semantics(
      label: '무무몽',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _settle,
        builder: (context, _) {
          final t = MongMotion.enter.transform(_settle.value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 'MUMUMONG'.length; i++)
                Text(
                  'MUMUMONG'[i],
                  style: style.copyWith(
                    color: Color.lerp(
                      MongColor.sky400,
                      ink,
                      ((t * 1.6) - i * .08).clamp(0.0, 1.0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// DESIGN.md §7.1 variants.
enum MongButtonVariant { primary, secondary, solid, ghost }

/// The one button of the product. Same press feel everywhere: scale .975 in
/// 120 ms, no bounce, Duration.zero under reduced motion.
class MongButton extends StatefulWidget {
  const MongButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MongButtonVariant.primary,
    this.expanded = true,
    this.icon,
    this.lightContent = false,
    this.loadingLabel,
  });

  const MongButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : variant = MongButtonVariant.ghost,
       expanded = false,
       lightContent = false,
       loadingLabel = null;

  final String label;
  final VoidCallback? onPressed;
  final MongButtonVariant variant;
  final bool expanded;
  final IconData? icon;

  /// White text/edges for use over the atmosphere or night surfaces.
  final bool lightContent;

  /// When set, the button is disabled and shows this status instead of the
  /// label (loading state keeps the geometry, never a spinner).
  final String? loadingLabel;

  @override
  State<MongButton> createState() => _MongButtonState();
}

class _MongButtonState extends State<MongButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && widget.loadingLabel == null;

  void _setPressed(bool pressed) {
    if (!_enabled || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;
    if (variant == MongButtonVariant.ghost) return _ghost(context);
    final radius = BorderRadius.circular(MongGlass.cornerRadius);
    final night = context.isNight;
    final light = widget.lightContent || night;
    final solid = variant == MongButtonVariant.solid;
    final foreground = solid
        ? (night ? MongColor.nightCanvas : MongColor.paper)
        : light
        ? Colors.white
        : MongColor.ink;
    final label = widget.loadingLabel ?? widget.label;

    final content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 19, color: foreground),
          const SizedBox(width: MongSpace.xs),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ),
      ],
    );

    final inner = AnimatedContainer(
      duration: MongMotion.of(context, MongMotion.micro),
      curve: MongMotion.enter,
      constraints: const BoxConstraints(minHeight: MongGlass.actionHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: MongSpace.lg,
        vertical: 14,
      ),
      decoration: _decoration(variant, light, night, radius),
      child: content,
    );

    final button = Opacity(
      opacity: _enabled ? 1 : .48,
      child: AnimatedScale(
        scale: _pressed ? MongMotion.pressScale : 1,
        duration: MongMotion.of(context, MongMotion.micro),
        curve: MongMotion.enter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: solid ? MongShadow.whisper : MongShadow.float,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: solid
                ? _tap(radius, inner)
                : BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: MongGlass.blur,
                      sigmaY: MongGlass.blur,
                    ),
                    child: _tap(radius, inner),
                  ),
          ),
        ),
      ),
    );
    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _tap(BorderRadius radius, Widget child) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _enabled ? widget.onPressed : null,
      onHighlightChanged: _setPressed,
      borderRadius: radius,
      child: child,
    ),
  );

  BoxDecoration _decoration(
    MongButtonVariant variant,
    bool light,
    bool night,
    BorderRadius radius,
  ) {
    switch (variant) {
      case MongButtonVariant.solid:
        return BoxDecoration(
          borderRadius: radius,
          color: night ? MongColor.nightInk : MongColor.ink,
        );
      case MongButtonVariant.primary:
        // Sky glass: a blue tint keeps the surface legible as glass on paper.
        if (light) {
          return BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MongColor.sky400.withValues(alpha: _pressed ? .34 : .26),
                Colors.white.withValues(alpha: _pressed ? .14 : .08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .36),
              width: MongGlass.stroke,
            ),
          );
        }
        return BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MongColor.sky100.withValues(alpha: _pressed ? .96 : .90),
              Colors.white.withValues(alpha: _pressed ? .70 : .55),
            ],
          ),
          border: Border.all(
            color: MongColor.sky300.withValues(alpha: .55),
            width: MongGlass.stroke,
          ),
        );
      case MongButtonVariant.secondary:
      case MongButtonVariant.ghost:
        if (light) {
          return BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: _pressed ? .22 : .16),
                Colors.white.withValues(alpha: _pressed ? .10 : .06),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .32),
              width: MongGlass.stroke,
            ),
          );
        }
        return BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(
                alpha: _pressed
                    ? MongGlass.frostedPressedAlpha
                    : MongGlass.frostedAlpha,
              ),
              Colors.white.withValues(alpha: _pressed ? .62 : .46),
            ],
          ),
          border: Border.all(
            color: MongGlass.slateEdge.withValues(
              alpha: MongGlass.slateEdgeAlpha,
            ),
            width: MongGlass.stroke,
          ),
        );
    }
  }

  Widget _ghost(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: widget.lightContent
          ? Colors.white
          : context.secondaryInk,
      minimumSize: const Size(MongSize.touch, MongSize.touch),
      padding: const EdgeInsets.symmetric(horizontal: MongSpace.sm),
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400),
      shape: const StadiumBorder(),
    );
    final label = Text(widget.loadingLabel ?? widget.label);
    if (widget.icon == null) {
      return TextButton(
        onPressed: _enabled ? widget.onPressed : null,
        style: style,
        child: label,
      );
    }
    return TextButton.icon(
      onPressed: _enabled ? widget.onPressed : null,
      style: style,
      icon: Icon(widget.icon, size: 18),
      label: label,
    );
  }
}

/// DESIGN.md §7.2.
enum MongIconButtonVariant { plain, glass, recording }

class MongIconButton extends StatefulWidget {
  const MongIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = MongIconButtonVariant.plain,
    this.active = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final MongIconButtonVariant variant;

  /// Recording in progress: sky edge, no pulse, no level meter.
  final bool active;

  @override
  State<MongIconButton> createState() => _MongIconButtonState();
}

class _MongIconButtonState extends State<MongIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.variant == MongIconButtonVariant.plain) {
      return IconButton(
        onPressed: widget.onPressed,
        tooltip: widget.semanticLabel,
        icon: Icon(widget.icon, size: 22),
      );
    }
    final night = context.isNight;
    final recording = widget.variant == MongIconButtonVariant.recording;
    final edge = widget.active
        ? MongColor.sky400
        : night
        ? Colors.white.withValues(alpha: .18)
        : MongColor.sky300.withValues(alpha: recording ? .8 : .5);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.onPressed != null,
      child: Opacity(
        opacity: widget.onPressed == null ? .48 : 1,
        child: AnimatedScale(
          scale: _pressed ? MongMotion.pressScale : 1,
          duration: MongMotion.of(context, MongMotion.micro),
          curve: MongMotion.enter,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: MongShadow.float,
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: MongGlass.blur,
                  sigmaY: MongGlass.blur,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    onHighlightChanged: (v) {
                      if (widget.onPressed != null) {
                        setState(() => _pressed = v);
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: MongMotion.of(context, MongMotion.micro),
                      width: MongSize.action,
                      height: MongSize.action,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: night
                              ? [
                                  Colors.white.withValues(alpha: .16),
                                  Colors.white.withValues(alpha: .06),
                                ]
                              : [
                                  (recording ? MongColor.sky100 : Colors.white)
                                      .withValues(alpha: _pressed ? .96 : .88),
                                  Colors.white.withValues(alpha: .55),
                                ],
                        ),
                        border: Border.all(
                          color: edge,
                          width: widget.active ? 1.5 : MongGlass.stroke,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: night ? MongColor.nightInk : MongColor.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// DESIGN.md §7.5. Selection is carried by fill and edge, not colour alone.
class MongChip extends StatelessWidget {
  const MongChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MongRadius.chip),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MongSize.touch),
        child: AnimatedContainer(
          duration: MongMotion.of(context, MongMotion.micro),
          padding: const EdgeInsets.symmetric(
            horizontal: MongSpace.md,
            vertical: MongSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? context.accentSoft : context.subtle,
            borderRadius: BorderRadius.circular(MongRadius.chip),
            border: Border.all(
              color: selected ? context.accent : context.hairline,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: context.primaryInk,
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Legacy names. They render the DESIGN.md components; new code uses MongButton.
// ---------------------------------------------------------------------------

/// The primary sky-glass action (legacy name).
class GlassActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) => MongButton(
    label: label,
    onPressed: onPressed,
    expanded: expanded,
    lightContent: lightContent,
    icon: icon,
  );
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
      MongButton(label: label, onPressed: onPressed, expanded: expanded);
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
  Widget build(BuildContext context) =>
      MongButton.ghost(label: label, onPressed: onPressed);
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
  Widget build(BuildContext context) =>
      MongChip(label: label, selected: selected, onTap: onTap);
}

/// DESIGN.md §7.7 bottom navigation: one pill bar, selected tab as a quiet
/// pill. Labels only; no icons, no badges.
class MongBottomNav extends StatelessWidget {
  const MongBottomNav({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ColoredBox(
      color: context.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MongSpace.md,
          6,
          MongSpace.md,
          MongSpace.xs,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.canvas,
            borderRadius: BorderRadius.circular(MongRadius.nav),
            border: Border.all(color: context.hairline),
            boxShadow: MongShadow.whisper,
          ),
          child: SizedBox(
            height: MongSize.nav,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == selectedIndex,
                      button: true,
                      child: InkWell(
                        onTap: () => onSelect(i),
                        borderRadius: BorderRadius.circular(MongRadius.nav),
                        child: AnimatedContainer(
                          duration: MongMotion.of(context, MongMotion.base),
                          curve: MongMotion.enter,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: i == selectedIndex
                                ? context.subtle
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(MongRadius.tab),
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: MongMotion.of(
                                context,
                                MongMotion.micro,
                              ),
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
                                    color: i == selectedIndex
                                        ? context.primaryInk
                                        : context.metaInk,
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// DESIGN.md §7.7 contextual navigation: 44 px leading action, meta/title in
/// the middle, optional trailing action. Padding 24/14/16/12.
class MongContextBar extends StatelessWidget {
  const MongContextBar({
    super.key,
    this.leading,
    required this.child,
    this.trailing,
  });

  final Widget? leading;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      leading == null ? MongSpace.screen : MongSpace.md,
      14,
      trailing == null ? MongSpace.screen : MongSpace.md,
      MongSpace.sm,
    ),
    child: Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 2)],
        Expanded(child: child),
        if (trailing != null) ...[const SizedBox(width: 2), trailing!],
      ],
    ),
  );
}

/// A navigable list row: title, description and a quiet chevron. Used by
/// settings and library lists; destructive rows use the alert ink.
class MongListRow extends StatelessWidget {
  const MongListRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ink = destructive ? context.alertInk : context.primaryInk;
    final secondary = destructive ? context.alertInk : context.secondaryInk;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MongRadius.field),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: MongSpace.md),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: MongSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MongSpace.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: MongSpace.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: destructive ? context.alertInk : context.metaInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DESIGN.md §2.2: toggles use the accent track on every platform. The
/// adaptive Cupertino switch ignores the Material switch theme, so colours
/// are passed explicitly here rather than in each screen.
class MongSwitchRow extends StatelessWidget {
  const MongSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.contentPadding,
    this.shape,
  });

  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: contentPadding,
    shape: shape,
    title: title,
    subtitle: subtitle,
    value: value,
    onChanged: onChanged,
    activeThumbColor: MongColor.paperPure,
    activeTrackColor: context.isNight ? MongColor.nightSky : MongColor.sky500,
    inactiveTrackColor: context.hairline,
    inactiveThumbColor: MongColor.paperPure,
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  );
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
