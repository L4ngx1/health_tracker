import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTheme {
  static WidgetStateProperty<Color?> _pressOverlay(Color color) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.1);
      }
      return null;
    });
  }

  static ThemeData get light {
    final base = ThemeData.light().textTheme;
    final vietnamese = GoogleFonts.beVietnamProTextTheme(base);

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
      textTheme: vietnamese.copyWith(
        displayLarge: vietnamese.displayLarge?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: vietnamese.displayMedium?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: vietnamese.displaySmall?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: vietnamese.headlineMedium?.copyWith(
          color: AppPalette.textMain,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: vietnamese.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.textMain,
      ),
      splashFactory: InkRipple.splashFactory,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          overlayColor: _pressOverlay(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return 1;
            }
            return 3;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          overlayColor: _pressOverlay(AppPalette.primary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(
                color: AppPalette.primaryDark,
                width: 1.3,
              );
            }
            return const BorderSide(color: AppPalette.primary, width: 1);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 140),
          overlayColor: _pressOverlay(AppPalette.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 120),
          overlayColor: _pressOverlay(AppPalette.primary),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
