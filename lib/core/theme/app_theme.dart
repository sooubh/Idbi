import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const Color base = Color(0xFF0A0F1E); // deep navy background
    const Color panel = Color(0xFF141C33); // dark card surface
    const Color panelAlt = Color(0xFF1E2845); // lighter container background
    const Color accent = Color(0xFFFFD700); // premium gold accent
    const Color accentHot = Color(0xFF3B82F6); // bright blue highlight
    const Color textPrimary = Colors.white; // high emphasis text
    const Color textSecondary = Colors.white70; // medium emphasis text

    final TextTheme textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: base,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        surface: panel,
        surfaceContainerHighest: panelAlt,
        primary: accent,
        secondary: accentHot,
        onPrimary: base,
        onSurface: textPrimary,
        primaryContainer: panel,
        onPrimaryContainer: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: base,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelAlt,
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: const Color(0xFF1E293B),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? textPrimary : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  static ThemeData light() {
    const Color base = Color(0xFFF4F6FA); // sleek soft grey/white background
    const Color panel = Colors.white; // pure white card surface
    const Color panelAlt = Color(0xFFE2E8F0); // subtle borders / light grey container
    const Color accent = Color(0xFF0F172A); // premium deep slate primary
    const Color accentHot = Color(0xFF2563EB); // royal blue highlight
    const Color textPrimary = Color(0xFF0F172A); // high contrast slate text
    const Color textSecondary = Color(0xFF475569); // slate text secondary

    final TextTheme textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: base,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        surface: panel,
        surfaceContainerHighest: panelAlt,
        primary: accent,
        secondary: accentHot,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        primaryContainer: panel,
        onPrimaryContainer: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: base,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // clean borders
        ),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.02),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDF2F7),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: accentHot.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? textPrimary : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }
}
