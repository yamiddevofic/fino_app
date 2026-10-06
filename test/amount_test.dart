import 'package:fino_app/utils/amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmount', () {
    final cases = {
      '1500': 1500.0,
      '1.500': 1500.0,
      '1.500.000': 1500000.0,
      '1.500,50': 1500.5,
      '1500,5': 1500.5,
      '1500.50': 1500.5,
      r'$ 20.000': 20000.0,
      ' 42 ': 42.0,
      '0,99': 0.99,
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(parseAmount(input), expected);
      });
    });

    for (final invalid in ['', 'abc', '1,2,3', '-5', '12a']) {
      test('"$invalid" no es válido', () {
        expect(parseAmount(invalid), isNull);
      });
    }
  });

  group('formatCop', () {
    test('sin decimales cuando el monto es entero', () {
      expect(formatCop(1250000), r'$ 1.250.000');
    });

    test('con decimales cuando los hay', () {
      expect(formatCop(1500.5), r'$ 1.500,50');
    });

    test('negativos con el signo antes del símbolo', () {
      expect(formatCop(-20000), r'-$ 20.000');
    });

    test('lo que muestra se vuelve a leer igual', () {
      for (final v in [0.99, 20000.0, 1500.5, 1250000.0]) {
        expect(parseAmount(formatCop(v)), v);
      }
    });
  });
}
