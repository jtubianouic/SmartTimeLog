import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  static const String appFontFamily = 'Geist';
  static const String appMonoFontFamily = 'GeistMono';

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF60A5FA);

  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightText = Color(0xFF0B1220);
  static const Color lightTextMuted = Color(0xFF475569);
  static const Color lightBorder = Color(0xFFD8E1EC);

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceMuted = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFFA8B3C7);
  static const Color darkBorder = Color(0xFF334155);

  static Color surface(BuildContext context) =>
    Theme.of(context).colorScheme.surface;

  static Color mutedSurface(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerLow;

  static Color border(BuildContext context) =>
    Theme.of(context).colorScheme.outlineVariant;

  static Color mutedText(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

  static Color successBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? darkStatusSuccessBackground
      : lightStatusSuccessBackground;

  static Color successBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? darkStatusSuccessBorder
      : lightStatusSuccessBorder;

  static Color warningBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? darkStatusWarningBackground
      : lightStatusWarningBackground;

  static Color warningBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? darkStatusWarningBorder
      : lightStatusWarningBorder;

  static ColorScheme _lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: lightSurface,
      onSurface: lightText,
      onSurfaceVariant: lightTextMuted,
      outline: const Color(0xFF94A3B8),
      outlineVariant: lightBorder,
      surfaceContainerLow: lightSurfaceMuted,
      error: const Color(0xFFDC2626),
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
    );
  }

  static ColorScheme _darkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryBlueDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryBlueDark,
      secondary: primaryBlueDark,
      surface: darkSurface,
      onSurface: darkText,
      onSurfaceVariant: darkTextMuted,
      outline: const Color(0xFF64748B),
      outlineVariant: darkBorder,
      surfaceContainerLow: darkSurfaceMuted,
      error: const Color(0xFFF87171),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
    );
  }

  static TextTheme _textTheme({
    required Color primary,
    required Color muted,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      displaySmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primary, height: 1.35),
      bodyMedium: TextStyle(color: primary, height: 1.35),
      bodySmall: TextStyle(color: muted, height: 1.35),
      labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: primary, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: muted, fontWeight: FontWeight.w500),
    );
  }

  static ShadThemeData lightShadTheme() {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadBlueColorScheme.light(
        background: lightBackground,
        foreground: lightText,
        card: lightSurface,
        cardForeground: lightText,
        popover: lightSurface,
        popoverForeground: lightText,
        primary: primaryBlue,
        primaryForeground: Colors.white,
        secondary: lightSurfaceMuted,
        secondaryForeground: lightText,
        muted: lightSurfaceMuted,
        mutedForeground: lightTextMuted,
        accent: lightSurfaceMuted,
        accentForeground: lightText,
        destructive: Color(0xFFDC2626),
        destructiveForeground: Colors.white,
        border: lightBorder,
        input: lightBorder,
        ring: primaryBlue,
        selection: Color(0xFFBFDBFE),
      ),
    );
  }

  static ShadThemeData darkShadTheme() {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadBlueColorScheme.dark(
        background: darkBackground,
        foreground: darkText,
        card: darkSurface,
        cardForeground: darkText,
        popover: darkSurface,
        popoverForeground: darkText,
        primary: primaryBlueDark,
        primaryForeground: Color(0xFF0B1220),
        secondary: darkSurfaceMuted,
        secondaryForeground: darkText,
        muted: darkSurfaceMuted,
        mutedForeground: darkTextMuted,
        accent: darkSurfaceMuted,
        accentForeground: darkText,
        destructive: Color(0xFFF87171),
        destructiveForeground: Color(0xFF0B1220),
        border: darkBorder,
        input: darkBorder,
        ring: primaryBlueDark,
        selection: Color(0xFF1E3A5F),
      ),
    );
  }

  // Light theme - Card colors
  static const Color lightCardBackground = lightSurface;
  static const Color lightCardBorder = lightBorder;
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
  static const Color darkCardBackground = darkSurface;
  static const Color darkCardBorder = darkBorder;
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
    final colorScheme = _lightColorScheme();
    return ThemeData(
      fontFamily: appFontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
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
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue, width: 1.5),
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
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: _textTheme(
        primary: colorScheme.onSurface,
        muted: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = _darkColorScheme();
    return ThemeData(
      fontFamily: appFontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlueDark, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlueDark,
          side: BorderSide(color: primaryBlueDark, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryBlueDark),
      ),
      textTheme: _textTheme(
        primary: colorScheme.onSurface,
        muted: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
