import 'package:flutter/material.dart';

abstract final class MongColor {
  static const paper = Color(0xFFFBFAF7);
  static const paperPure = Color(0xFFFFFFFF);
  static const paperShade = Color(0xFFF2F0EB);
  static const line = Color(0xFFE4E1DA);
  static const ink = Color(0xFF1E1D1B);
  static const ink2 = Color(0xFF55524D);
  static const ink3 = Color(0xFF74716B);
  static const sky100 = Color(0xFFE8F0F4);
  static const sky300 = Color(0xFFC2D8E4);
  static const sky500 = Color(0xFF93B9CF);
  static const sky700 = Color(0xFF4D7C9B);

  static const nightPaper = Color(0xFF161513);
  static const nightShade = Color(0xFF201F1C);
  static const nightInk = Color(0xFFE8E5DF);
  static const nightMeta = Color(0xFF9C9891);
  static const nightSky = Color(0xFF7FA3BA);
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

ThemeData mumumongTheme() {
  const uiText = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w700,
      fontSize: 40,
      height: 1.15,
      color: MongColor.ink,
    ),
    displayMedium: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.25,
      color: MongColor.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
      fontSize: 21,
      height: 1.4,
      color: MongColor.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'MaruBuri',
      fontWeight: FontWeight.w400,
      fontSize: 18,
      height: 1.8,
      color: MongColor.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w400,
      fontSize: 15,
      height: 1.5,
      color: MongColor.ink,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.4,
      color: MongColor.ink,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
      fontSize: 11,
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
      backgroundColor: MongColor.paperPure,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
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
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: dark ? MongColor.ink : Colors.transparent,
          foregroundColor: dark ? MongColor.paper : MongColor.ink,
          disabledBackgroundColor: MongColor.paperShade,
          disabledForegroundColor: MongColor.ink3,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: dark
                ? BorderSide.none
                : const BorderSide(color: MongColor.ink),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Text(label),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
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
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: MongColor.ink,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        shape: const RoundedRectangleBorder(),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(label),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: MongMotion.micro,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? MongColor.sky100 : MongColor.paperShade,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? MongColor.sky700 : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
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
    transitionsBuilder: (_, animation, _, child) {
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
