import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF6366F1);
  static const _secondary = Color(0xFF8B5CF6);

  static const cardRadius = 22.0;
  static const _lightBg = Color(0xFFF2F3FB);
  static const _lightCard = Color(0xFFFFFFFF);
  static const _darkBg = Color(0xFF0F1015);
  static const _darkCard = Color(0xFF1A1C24);

  static List<BoxShadow> softShadow(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const []
          : [
              BoxShadow(
                color: const Color(0xFF1B1F3B).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ];

  static Color hairline(ThemeData theme) => theme.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFF1B1F3B).withValues(alpha: 0.05);

  static LinearGradient heroGradient(ThemeData theme) => const LinearGradient(
        colors: [Color(0xFF7C6BF5), Color(0xFF9B7BF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _secondary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _lightBg,
        cardColor: _lightCard,
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          color: _lightCard,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: _lightCard,
          indicatorColor: _primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _secondary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _darkBg,
        cardColor: _darkCard,
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          color: _darkCard,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: _darkCard,
          indicatorColor: _primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static Color parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
