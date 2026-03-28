import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light().textTheme;
    final sora = GoogleFonts.soraTextTheme(base);
    final display = GoogleFonts.frauncesTextTheme(base);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppPalette.primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: AppPalette.primary,
            secondary: AppPalette.accent,
            surface: AppPalette.surface,
          ),
      textTheme: sora.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: display.displaySmall?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: sora.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.textMain,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
