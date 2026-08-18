import 'package:flutter/material.dart';

class AppTheme {
  // Light theme - Card colors
  static const Color lightCardBackground = Color(0xFFFAFBFC);
  static const Color lightCardBorder = Color(0xFFE5E7EB);
  static const Color lightStatusSuccessBackground = Color(0xFFDCFCE7);
  static const Color lightStatusSuccessBorder = Color(0xFF86EFAC);
  static const Color lightStatusWarningBackground = Color(0xFFFEF3C7);
  static const Color lightStatusWarningBorder = Color(0xFFFBBF24);
  static const Color lightStatusErrorBackground = Color(0xFFFECDCD);
  static const Color lightStatusErrorBorder = Color(0xFFF87171);
  static const Color lightStatCardBackground = Color(0xFFF3F4F6);
  static const Color lightSummaryGradientStart = Color(0xFFEFF6FF);
  static const Color lightSummaryGradientEnd = Color(0xFFF3E8FF);
  static const Color lightAccentPurple = Color(0xFFA78BFA);

  // Dark theme - Card colors
  static const Color darkCardBackground = Color(0xFF1F2937);
  static const Color darkCardBorder = Color(0xFF374151);
  static const Color darkStatusSuccessBackground = Color(0xFF064E3B);
  static const Color darkStatusSuccessBorder = Color(0xFF10B981);
  static const Color darkStatusWarningBackground = Color(0xFF713F12);
  static const Color darkStatusWarningBorder = Color(0xFFFBBF24);
  static const Color darkStatusErrorBackground = Color(0xFF7F1D1D);
  static const Color darkStatusErrorBorder = Color(0xFFF87171);
  static const Color darkStatCardBackground = Color(0xFF2D3748);
  static const Color darkSummaryGradientStart = Color(0xFF1E3A8A);
  static const Color darkSummaryGradientEnd = Color(0xFF4C1D95);
  static const Color darkAccentPurple = Color(0xFF7C3AED);

  // Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF374151), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFF374151)),
        bodyMedium: TextStyle(color: Color(0xFF374151)),
        bodySmall: TextStyle(color: Color(0xFF6B7280)),
        labelLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF818CF8),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF111827),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1F2937),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        filled: true,
        fillColor: darkCardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF818CF8),
          side: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF818CF8)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
        bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
        bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
        labelLarge: TextStyle(color: Color(0xFFF3F4F6), fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
      ),
    );
  }
}
