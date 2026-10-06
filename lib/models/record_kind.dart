import 'package:fino_app/theme/app_theme.dart';
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
      'Deudas',
      'Compras',
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
    doneLabel: 'Pagada',
    pendingLabel: 'Pendiente',
    settledCategory: 'Deudas',
    settledNote: 'Pago de deuda',
  ),
  buy(
    title: 'Compras',
    singular: 'compra',
    boxName: 'buysBox',
    icon: Icons.shopping_bag_outlined,
    accentLight: Color(0xFFD97706),
    accentDark: Color(0xFFFBBF24),
    categories: ['Mercado', 'Hogar', 'Tecnología', 'Ropa', 'Otro'],
    doneLabel: 'Comprada',
    pendingLabel: 'Por comprar',
    settledCategory: 'Compras',
    settledNote: 'Compra de la lista',
    allowsPendingPrice: true,
  );

  const RecordKind({
    required this.title,
    required this.singular,
    required this.boxName,
    required this.icon,
    required this.accentLight,
    required this.accentDark,
    required this.categories,
    this.doneLabel,
    this.pendingLabel,
    this.allowsPendingPrice = false,
    this.settledCategory,
    this.settledNote,
  });

  final String title;
  final String singular;
  final String boxName;
  final IconData icon;
  final Color accentLight;
  final Color accentDark;
  final List<String> categories;

  /// Texto para un registro marcado como hecho (deuda cancelada, compra
  /// realizada). `null` si la sección no se puede marcar.
  final String? doneLabel;
  final String? pendingLabel;

  /// Si se puede registrar sin precio y definirlo después.
  final bool allowsPendingPrice;

  /// Categoría y nota del gasto que se registra al marcar como lista.
  final String? settledCategory;
  final String? settledNote;

  bool get canMarkDone => doneLabel != null;

  /// Color legible para texto o iconos encima de [accent].
  Color onAccent(BuildContext context) => onColor(accent(context));

  /// Icono de una categoría, o el de la sección si no tiene categoría.
  /// Las categorías creadas por el usuario usan una etiqueta genérica.
  IconData iconFor(String? category) {
    if (category == null || category == 'Otro') return icon;
    return _categoryIcons[category] ?? Icons.sell_outlined;
  }

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
  'Deudas': Icons.account_balance_outlined,
  'Compras': Icons.shopping_bag_outlined,
  'Tarjeta': Icons.credit_card_rounded,
  'Préstamo': Icons.account_balance_outlined,
  'Personal': Icons.person_outline_rounded,
  'Mercado': Icons.shopping_cart_outlined,
  'Hogar': Icons.chair_outlined,
  'Tecnología': Icons.devices_other_rounded,
  'Ropa': Icons.checkroom_rounded,
};
