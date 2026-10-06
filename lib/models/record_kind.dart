import 'package:flutter/material.dart';

/// Metadatos de cada sección: textos, color de acento, icono y categorías.
enum RecordKind {
  income(
    title: 'Ingresos',
    singular: 'ingreso',
    boxName: 'incomesBox',
    icon: Icons.south_west_rounded,
    accentLight: Color(0xFF059669),
    accentDark: Color(0xFF34D399),
    categories: ['Salario', 'Freelance', 'Inversiones', 'Regalo', 'Otro'],
  ),
  expense(
    title: 'Gastos',
    singular: 'gasto',
    boxName: 'expensesBox',
    icon: Icons.north_east_rounded,
    accentLight: Color(0xFFE11D48),
    accentDark: Color(0xFFFB7185),
    categories: [
      'Vivienda',
      'Comida',
      'Transporte',
      'Servicios',
      'Salud',
      'Ocio',
      'Otro',
    ],
  ),
  debt(
    title: 'Deudas',
    singular: 'deuda',
    boxName: 'debtBox',
    icon: Icons.account_balance_rounded,
    accentLight: Color(0xFF7C3AED),
    accentDark: Color(0xFFA78BFA),
    categories: ['Tarjeta', 'Préstamo', 'Personal', 'Otro'],
  ),
  buy(
    title: 'Compras',
    singular: 'compra',
    boxName: 'buysBox',
    icon: Icons.shopping_bag_outlined,
    accentLight: Color(0xFFD97706),
    accentDark: Color(0xFFFBBF24),
    categories: ['Mercado', 'Hogar', 'Tecnología', 'Ropa', 'Otro'],
  );

  const RecordKind({
    required this.title,
    required this.singular,
    required this.boxName,
    required this.icon,
    required this.accentLight,
    required this.accentDark,
    required this.categories,
  });

  final String title;
  final String singular;
  final String boxName;
  final IconData icon;
  final Color accentLight;
  final Color accentDark;
  final List<String> categories;

  /// Color legible para texto o iconos encima de [accent].
  Color onAccent(BuildContext context) =>
      ThemeData.estimateBrightnessForColor(accent(context)) == Brightness.dark
      ? Colors.white
      : const Color(0xFF0E1116);

  /// Icono de una categoría, o el de la sección si no tiene categoría.
  IconData iconFor(String? category) => _categoryIcons[category] ?? icon;

  Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? accentDark
      : accentLight;
}

const _categoryIcons = <String, IconData>{
  'Salario': Icons.work_outline_rounded,
  'Freelance': Icons.laptop_mac_rounded,
  'Inversiones': Icons.trending_up_rounded,
  'Regalo': Icons.card_giftcard_rounded,
  'Vivienda': Icons.home_outlined,
  'Comida': Icons.restaurant_rounded,
  'Transporte': Icons.directions_car_outlined,
  'Servicios': Icons.bolt_rounded,
  'Salud': Icons.favorite_border_rounded,
  'Ocio': Icons.local_activity_outlined,
  'Tarjeta': Icons.credit_card_rounded,
  'Préstamo': Icons.account_balance_outlined,
  'Personal': Icons.person_outline_rounded,
  'Mercado': Icons.shopping_cart_outlined,
  'Hogar': Icons.chair_outlined,
  'Tecnología': Icons.devices_other_rounded,
  'Ropa': Icons.checkroom_rounded,
};
