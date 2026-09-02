import 'package:flutter/material.dart';

class AppTheme {
  static const String appFontFamily = 'Geist';
  static const String appMonoFontFamily = 'GeistMono';

  static const Color primaryBlue = Color(0xFF006A60);
  static const Color primaryBlueDark = Color(0xFF54DBC8);

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
      secondary: const Color(0xFF4A635F),
      tertiary: const Color(0xFF456179),
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
      secondary: const Color(0xFFB1CCC6),
      tertiary: const Color(0xFFADC9E6),
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

  static TextTheme _textTheme({required Color primary, required Color muted}) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
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

  static const Color lightCardBorder = lightBorder;
  static const Color lightStatusSuccessBackground = Color(0xFFDCFCE7);
  static const Color lightStatusSuccessBorder = Color(0xFF86EFAC);
  static const Color lightStatusWarningBackground = Color(0xFFFEF3C7);
  static const Color lightStatusWarningBorder = Color(0xFFFBBF24);

  static const Color darkCardBorder = darkBorder;
  static const Color darkStatusSuccessBackground = Color(0xFF064E3B);
  static const Color darkStatusSuccessBorder = Color(0xFF10B981);
  static const Color darkStatusWarningBackground = Color(0xFF713F12);
  static const Color darkStatusWarningBorder = Color(0xFFFBBF24);

  // Light theme
  static ThemeData lightTheme() {
    final colorScheme = _lightColorScheme();
    return _materialTheme(colorScheme, lightBackground);
  }

  static ThemeData darkTheme() {
    final colorScheme = _darkColorScheme();
    return _materialTheme(colorScheme, darkBackground);
  }

  static ThemeData _materialTheme(ColorScheme colorScheme, Color background) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      fontFamily: appFontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: appFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: roundedShape.copyWith(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: roundedShape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          side: BorderSide(color: colorScheme.outline),
          shape: roundedShape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 3,
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: _textTheme(
        primary: colorScheme.onSurface,
        muted: colorScheme.onSurfaceVariant,
      ),
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
  }
}
