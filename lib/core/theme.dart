import 'package:flutter/material.dart';

/// Paleta de Alcancía.
class AppColors {
  static const income = Color(0xFF2EC4A0); // verde menta
  static const expense = Color(0xFFFF6B6B); // coral
  static const savings = Color(0xFFFFC233); // oro
  static const accent = Color(0xFF7C5CFF); // violeta
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
