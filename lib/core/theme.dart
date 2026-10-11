import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Paleta de Alcancía. Verde = entra dinero, coral = sale, violeta = marca y
/// transferencias, oro = ahorro y monedas.
class AppColors {
  static const brand = Color(0xFF6C4CF1);
  static const brandLight = Color(0xFF9B7BFF);
  static const pink = Color(0xFFFF7EB3);
  static const income = Color(0xFF12B886);
  static const expense = Color(0xFFFA5252);
  static const transfer = Color(0xFF7C5CFF);
  static const savings = Color(0xFFFFC233);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B3FE0), Color(0xFF8B5CF6), Color(0xFFD16BA5)],
    stops: [0, 0.55, 1],
  );

  static const fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFF), Color(0xFFFF7EB3)],
  );
}

/// Sombra suave y difusa para tarjetas en modo claro.
List<BoxShadow> softShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const []
    : [
        BoxShadow(
          color: const Color(0xFF2A1F5C).withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: brightness,
      ).copyWith(
        surface: dark ? const Color(0xFF111019) : const Color(0xFFF6F5FB),
        surfaceContainerLow: dark ? const Color(0xFF1C1A28) : Colors.white,
        surfaceContainerHighest: dark
            ? const Color(0xFF2A2838)
            : const Color(0xFFEDEAF6),
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    ),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  const pill = StadiumBorder();
  final radius16 = BorderRadius.circular(16);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: pill,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: pill),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: pill,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: pill,
      side: BorderSide.none,
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
