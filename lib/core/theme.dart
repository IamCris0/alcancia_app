import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Paletas que el usuario puede elegir (Perfil → Tema).
enum AppPalette { violeta, oceano, bosque, atardecer, cereza, medianoche }

class PaletteColors {
  const PaletteColors({
    required this.label,
    required this.brand,
    required this.brandLight,
    required this.accent,
    required this.hero,
  });

  final String label;
  final Color brand;
  final Color brandLight;
  final Color accent;
  final List<Color> hero;
}

extension AppPaletteColors on AppPalette {
  PaletteColors get colors => switch (this) {
    AppPalette.violeta => const PaletteColors(
      label: 'Violeta',
      brand: Color(0xFF6C4CF1),
      brandLight: Color(0xFF9B7BFF),
      accent: Color(0xFFFF7EB3),
      hero: [Color(0xFF5B3FE0), Color(0xFF8B5CF6), Color(0xFFD16BA5)],
    ),
    AppPalette.oceano => const PaletteColors(
      label: 'Océano',
      brand: Color(0xFF1C7ED6),
      brandLight: Color(0xFF4DABF7),
      accent: Color(0xFF3BC9DB),
      hero: [Color(0xFF1864AB), Color(0xFF1C7ED6), Color(0xFF15AABF)],
    ),
    AppPalette.bosque => const PaletteColors(
      label: 'Bosque',
      brand: Color(0xFF2B8A3E),
      brandLight: Color(0xFF51CF66),
      accent: Color(0xFFC0EB75),
      hero: [Color(0xFF1B6B32), Color(0xFF2F9E44), Color(0xFF74B816)],
    ),
    AppPalette.atardecer => const PaletteColors(
      label: 'Atardecer',
      brand: Color(0xFFE8590C),
      brandLight: Color(0xFFFF922B),
      accent: Color(0xFFFFD43B),
      hero: [Color(0xFFC92A2A), Color(0xFFE8590C), Color(0xFFF59F00)],
    ),
    AppPalette.cereza => const PaletteColors(
      label: 'Cereza',
      brand: Color(0xFFD6336C),
      brandLight: Color(0xFFF06595),
      accent: Color(0xFFFFA8A8),
      hero: [Color(0xFFA61E4D), Color(0xFFD6336C), Color(0xFFF783AC)],
    ),
    AppPalette.medianoche => const PaletteColors(
      label: 'Medianoche',
      brand: Color(0xFF4263EB),
      brandLight: Color(0xFF748FFC),
      accent: Color(0xFFB197FC),
      hero: [Color(0xFF1B1F4B), Color(0xFF364FC7), Color(0xFF7048E8)],
    ),
  };
}

/// Colores de PlataPets. Verde = entra dinero, coral = sale, oro = ahorro.
/// Los de marca dependen de la paleta elegida ([use]).
class AppColors {
  static PaletteColors _p = AppPalette.violeta.colors;

  /// Cambia la paleta activa (lo llama la app al construir el tema).
  static void use(AppPalette palette) => _p = palette.colors;

  static Color get brand => _p.brand;
  static Color get brandLight => _p.brandLight;
  static Color get pink => _p.accent;
  static Color get transfer => _p.brandLight;
  static const income = Color(0xFF12B886);
  static const expense = Color(0xFFFA5252);
  static const savings = Color(0xFFFFC233);

  static LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _p.hero,
    stops: const [0, 0.55, 1],
  );

  static LinearGradient get fabGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_p.brandLight, _p.accent],
  );
}

/// Sombra en dos capas (contacto + difusa tintada por la marca).
List<BoxShadow> softShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ]
    : [
        BoxShadow(
          color: const Color(0xFF1A1033).withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AppColors.brand.withValues(alpha: 0.09),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 12),
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
