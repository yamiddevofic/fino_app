import 'package:flutter/material.dart';

/// Colores neutros de la app. Los acentos por sección viven en [RecordKind].
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.positive,
    required this.negative,
    required this.brand,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color positive;
  final Color negative;
  final Color brand;

  static const light = AppTokens(
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF0F3),
    border: Color(0xFFE3E6EB),
    text: Color(0xFF0E1116),
    textMuted: Color(0xFF5B6472),
    positive: Color(0xFF059669),
    negative: Color(0xFFE11D48),
    brand: Color(0xFF4F46E5),
  );

  static const dark = AppTokens(
    background: Color(0xFF0A0C10),
    surface: Color(0xFF12151B),
    surfaceMuted: Color(0xFF1A1E26),
    border: Color(0xFF232833),
    text: Color(0xFFE8EBF0),
    textMuted: Color(0xFF8B93A1),
    positive: Color(0xFF34D399),
    negative: Color(0xFFFB7185),
    brand: Color(0xFF818CF8),
  );

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>()!;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
    );
  }
}

/// Estilo para cifras: dígitos de ancho fijo para que no "bailen" al animar.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? AppTokens.dark
      : AppTokens.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: tokens.brand,
        brightness: brightness,
      ).copyWith(
        primary: tokens.brand,
        surface: tokens.surface,
        onSurface: tokens.text,
        onSurfaceVariant: tokens.textMuted,
        outline: tokens.border,
        outlineVariant: tokens.border,
        error: tokens.negative,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: tokens.background,
    extensions: [tokens],
  );

  final text = base.textTheme.apply(
    bodyColor: tokens.text,
    displayColor: tokens.text,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      labelMedium: text.labelMedium?.copyWith(
        color: tokens.textMuted,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: tokens.text,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tokens.text,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.border, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surface.withValues(alpha: 0.72),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? tokens.text
              : tokens.textMuted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.negative),
      ),
      labelStyle: TextStyle(color: tokens.textMuted),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: tokens.surfaceMuted,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: tokens.text,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: tokens.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.text,
      contentTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: tokens.background,
      ),
      actionTextColor: tokens.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
