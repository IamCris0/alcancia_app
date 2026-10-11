import 'package:intl/intl.dart';

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol);
  final String code;
  final String name;
  final String symbol;
}

const supportedCurrencies = <CurrencyInfo>[
  CurrencyInfo('USD', 'Dólar estadounidense', r'$'),
  CurrencyInfo('MXN', 'Peso mexicano', r'$'),
  CurrencyInfo('COP', 'Peso colombiano', r'$'),
  CurrencyInfo('ARS', 'Peso argentino', r'$'),
  CurrencyInfo('CLP', 'Peso chileno', r'$'),
  CurrencyInfo('PEN', 'Sol peruano', 'S/'),
  CurrencyInfo('EUR', 'Euro', '€'),
  CurrencyInfo('BRL', 'Real brasileño', r'R$'),
  CurrencyInfo('GTQ', 'Quetzal', 'Q'),
  CurrencyInfo('CRC', 'Colón costarricense', '₡'),
];

CurrencyInfo currencyByCode(String code) => supportedCurrencies.firstWhere(
  (c) => c.code == code,
  orElse: () => supportedCurrencies.first,
);

/// Formatea centavos como "$1,234.50".
String formatMoney(int cents, String currencyCode) {
  final symbol = currencyByCode(currencyCode).symbol;
  return NumberFormat.currency(
    symbol: symbol,
    decimalDigits: 2,
  ).format(cents / 100);
}

/// Convierte texto escrito por el usuario ("12,5", "1.200.50", "-30") a
/// centavos. Devuelve null si no es un número válido.
int? parseMoneyToCents(String input) {
  var s = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (s.isEmpty) return null;
  final lastDot = s.lastIndexOf('.');
  if (lastDot != -1) {
    // Si hay varios puntos, solo el último es decimal.
    s = s.substring(0, lastDot).replaceAll('.', '') + s.substring(lastDot);
  }
  final value = double.tryParse(s);
  if (value == null || !value.isFinite) return null;
  return (value * 100).round();
}
