import 'package:flutter/material.dart';

class AppColors {
  // Light Palette
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightBackgroundElement = Color(0xFFFFFFFF);
  static const Color lightBackgroundSelected = Color(0xFFF1F5F9);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightPrimary = Color(0xFF0D9488);
  static const Color lightPrimaryLight = Color(0xFFCCFBF1);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightDanger = Color(0xFFEF4444);

  // Dark Palette
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkBackgroundElement = Color(0xFF1E293B);
  static const Color darkBackgroundSelected = Color(0xFF334155);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF2DD4BF);
  static const Color darkPrimaryLight = Color(0xFF115E59);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFF87171);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightBackgroundElement,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightPrimaryLight,
        surface: AppColors.lightBackgroundElement,
        background: AppColors.lightBackground,
        error: AppColors.lightDanger,
        onPrimary: Colors.white,
        onSurface: AppColors.lightText,
        onBackground: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackgroundElement,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkBackgroundElement,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkPrimaryLight,
        surface: AppColors.darkBackgroundElement,
        background: AppColors.darkBackground,
        error: AppColors.darkDanger,
        onPrimary: Color(0xFF0F172A),
        onSurface: AppColors.darkText,
        onBackground: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackgroundElement,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      ),
    );
  }
}
