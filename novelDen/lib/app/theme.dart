import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReaderTheme { light, sepia, dark, amoled }

final readerThemeProvider = StateProvider<ReaderTheme>((ref) => ReaderTheme.light);
final fontSizeProvider = StateProvider<double>((ref) => 18.0);
final fontFamilyProvider = StateProvider<String>((ref) => 'Literata');
final lineHeightProvider = StateProvider<double>((ref) => 1.6);
final marginProvider = StateProvider<double>((ref) => 24.0);

class ReaderThemeData {
  final Color background;
  final Color text;
  final Color secondary;
  final Color accent;

  const ReaderThemeData({
    required this.background,
    required this.text,
    required this.secondary,
    required this.accent,
  });

  static const Map<ReaderTheme, ReaderThemeData> themes = {
    ReaderTheme.light: ReaderThemeData(
      background: Color(0xFFFFFFFF),
      text: Color(0xFF1A1A1A),
      secondary: Color(0xFF666666),
      accent: Color(0xFF5C6BC0),
    ),
    ReaderTheme.sepia: ReaderThemeData(
      background: Color(0xFFF4ECD8),
      text: Color(0xFF3B2F2F),
      secondary: Color(0xFF7B5B3A),
      accent: Color(0xFF8B6914),
    ),
    ReaderTheme.dark: ReaderThemeData(
      background: Color(0xFF1E1E2E),
      text: Color(0xFFCDD6F4),
      secondary: Color(0xFF9399B2),
      accent: Color(0xFF89B4FA),
    ),
    ReaderTheme.amoled: ReaderThemeData(
      background: Color(0xFF000000),
      text: Color(0xFFEEEEEE),
      secondary: Color(0xFF888888),
      accent: Color(0xFF80CBC4),
    ),
  };
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5C6BC0),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF89B4FA),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E2E),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xFF313244),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
