import 'package:platapets/features/movements/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

AmountInput type(String keys) {
  var a = const AmountInput();
  for (final k in keys.split('')) {
    a = a.press(k);
  }
  return a;
}

void main() {
  test('escribe enteros y decimales', () {
    expect(type('1250').cents, 125000);
    expect(type('12.5').cents, 1250);
    expect(type('12.05').cents, 1205);
  });

  test('máximo dos decimales y un solo punto', () {
    expect(type('1.234').text, '1.23');
    expect(type('1..2').text, '1.2');
  });

  test('punto inicial agrega cero y no hay ceros a la izquierda', () {
    expect(type('.5').text, '0.5');
    expect(type('007').text, '7');
  });

  test('borrar', () {
    expect(type('123').backspace().text, '12');
    expect(const AmountInput().backspace().text, '');
  });

  test('display con separador de miles', () {
    expect(type('1234567').display(r'$'), r'$1,234,567');
    expect(type('1234.').display(r'$'), r'$1,234.');
    expect(const AmountInput().display(r'$'), r'$0');
  });

  test('fromCents ida y vuelta', () {
    expect(AmountInput.fromCents(1205).cents, 1205);
    expect(AmountInput.fromCents(5000).text, '50');
  });
}
