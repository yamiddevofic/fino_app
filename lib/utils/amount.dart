import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0', 'es_CO');
final _cents = NumberFormat('#,##0.00', 'es_CO');

/// Formatea un monto en pesos colombianos: `$ 1.250.000`, o `-$ 1.250.000`
/// si es negativo. Solo muestra decimales cuando el monto los tiene.
String formatCop(double value) {
  final abs = value.abs();
  final hasCents = (abs * 100).round() % 100 != 0;
  final digits = (hasCents ? _cents : _whole).format(abs);
  return '${value < 0 ? '-' : ''}\$ $digits';
}

/// Interpreta un monto escrito con la convención colombiana (punto para
/// miles, coma para decimales). También acepta `1500.50`.
///
/// Devuelve `null` si el texto no es un número.
double? parseAmount(String input) {
  var s = input.replaceAll(RegExp(r'[\s$]'), '');
  if (s.isEmpty) return null;

  final dots = '.'.allMatches(s).length;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (dots > 1) {
    s = s.replaceAll('.', '');
  } else if (dots == 1 && s.length - s.indexOf('.') - 1 == 3) {
    // "1.500" se lee como mil quinientos, no como 1,5.
    s = s.replaceAll('.', '');
  }

  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return null;
  return double.tryParse(s);
}
