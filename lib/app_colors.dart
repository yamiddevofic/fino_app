import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AppSection { overview, income, expense, debt, purchase }

class AppColors {
  static const Color success = Color(0xFF047857);
  static const Color lightError = Color(0xFFB91C1C);
  static const Color darkError = Color(0xFFFCA5A5);

  // Asociaciones orientativas; cada categoria conserva tambien su etiqueta.
  static const List<Color> lightAccents = [
    Color(
        0xFF0F766E), // Teal 700: salud financiera, crecimiento, estabilidad (contraste >= 4.5)
    Color(0xFF15803D), // Verde: crecimiento e ingresos
    Color(0xFFB91C1C), // Rojo: gastos y atencion
    Color(0xFF6B4F3B), // Tierra: solidez y responsabilidad
    Color(0xFFB45309), // Ambar: compras y consumo
  ];

  static const List<Color> darkAccents = [
    Color(0xFF2DD4BF), // Teal 300: modo oscuro con contraste >= 4.5
    Color(0xFF4ADE80),
    Color(0xFFF87171),
    Color(0xFFD6BDAA),
    Color(0xFFFBBF24),
  ];

  static List<Color> accents(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccents : lightAccents;

  static Color forSection(AppSection section, Brightness brightness) =>
      accents(brightness)[section.index];

  static Color errorFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkError : lightError;

  static Color onAccent(Color background) {
    const darkForeground = Color(0xFF14202B);
    return contrastRatio(background, Colors.white) >=
            contrastRatio(background, darkForeground)
        ? Colors.white
        : darkForeground;
  }

  static double contrastRatio(Color first, Color second) {
    final firstLuminance = _relativeLuminance(first);
    final secondLuminance = _relativeLuminance(second);
    final lighter =
        firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
    final darker =
        firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
    return (lighter + .05) / (darker + .05);
  }

  static double _relativeLuminance(Color color) {
    double linearize(double value) {
      return value <= .04045
          ? value / 12.92
          : math.pow((value + .055) / 1.055, 2.4).toDouble();
    }

    return .2126 * linearize(color.r) +
        .7152 * linearize(color.g) +
        .0722 * linearize(color.b);
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double screen = 20;

  const AppSpacing._();
}

class AppRadius {
  static const double control = 14;
  static const double card = 20;
  static const double hero = 24;

  const AppRadius._();
}
