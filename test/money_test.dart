import 'package:alcancia_app/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMoneyToCents', () {
    test('acepta punto y coma decimal', () {
      expect(parseMoneyToCents('12.5'), 1250);
      expect(parseMoneyToCents('12,5'), 1250);
    });
    test('ignora separadores de miles', () {
      expect(parseMoneyToCents('1.200.50'), 120050);
    });
    test('acepta negativos', () {
      expect(parseMoneyToCents('-30'), -3000);
    });
    test('rechaza texto inválido o vacío', () {
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents(''), isNull);
    });
  });

  test('formatMoney', () {
    expect(formatMoney(123450, 'USD'), r'$1,234.50');
    expect(formatMoney(-500, 'EUR'), '-€5.00');
  });
}
