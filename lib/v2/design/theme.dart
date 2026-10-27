// V2 Material defaults (DESIGN_V2.md §2). Material widgets that V2 screens
// still use (TextField, scroll physics, SnackBar host) inherit V2 values.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData v2Theme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: V2Color.sky500,
        brightness: Brightness.light,
        surface: V2Color.paper,
      ).copyWith(
        primary: V2Color.ink,
        onPrimary: Colors.white,
        secondary: V2Color.sky600,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: V2Color.paper,
    fontFamily: V2Font.sans,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      displayLarge: V2Type.displayXL,
      displayMedium: V2Type.display,
      headlineSmall: V2Type.title,
      titleMedium: V2Type.headline,
      bodyLarge: V2Type.reading,
      bodyMedium: V2Type.body,
      bodySmall: V2Type.bodySmall,
      labelLarge: V2Type.label,
      labelSmall: V2Type.meta,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: V2Color.sky600,
      selectionColor: V2Color.sky200.withValues(alpha: .8),
      selectionHandleColor: V2Color.sky600,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: V2Color.ink3),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Screen-to-screen transition: the next page rises a few points out of
/// the same space and the previous one recedes (Reference E). Reduced
/// motion crossfades without movement.
Route<T> v2Route<T>(Widget page, {bool opaque = true}) => PageRouteBuilder<T>(
  opaque: opaque,
  transitionDuration: V2Motion.page,
  reverseTransitionDuration: V2Motion.base,
  pageBuilder: (context, _, _) => page,
  transitionsBuilder: (context, animation, secondary, child) {
    final reduced = V2Motion.reduced(context);
    final enter = CurvedAnimation(
      parent: animation,
      curve: V2Motion.settle,
      reverseCurve: V2Motion.exit,
    );
    final leave = CurvedAnimation(parent: secondary, curve: V2Motion.settle);
    if (reduced) return FadeTransition(opacity: animation, child: child);
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: .985).animate(leave),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  },
);
