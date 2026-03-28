import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: AppPalette.textMain,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppPalette.textMain,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppPalette.textMain,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: AppPalette.textMain),
        bodySmall: TextStyle(fontSize: 14, color: AppPalette.textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        hintStyle: const TextStyle(color: AppPalette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppPalette.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppPalette.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1412),
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: Colors.white),
        bodySmall: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            inherit: true,
          ),
        ),
      ),
    );
  }
}
