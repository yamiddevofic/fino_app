import 'package:flutter/material.dart';
import 'package:fino_app/app_colors.dart';

class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA);
    final surface = isDark ? const Color(0xFF161C24) : Colors.white;
    final foreground =
        isDark ? const Color(0xFFE8EDF3) : const Color(0xFF18212B);
    final muted = isDark ? const Color(0xFFA0AAB6) : const Color(0xFF667281);
    final outline = isDark ? const Color(0xFF303A46) : const Color(0xFFE1E6EC);
    final brand = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final onBrand = isDark ? const Color(0xFF0D1928) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: brand,
      onPrimary: onBrand,
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: muted,
      outline: outline,
      error: AppColors.errorFor(brightness),
    );
    final controlRadius = BorderRadius.circular(AppRadius.control);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      fontFamily: 'Poppins',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: foreground,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: foreground,
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C242E) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    );
  }
}
