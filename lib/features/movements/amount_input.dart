import 'package:intl/intl.dart';

/// Estado inmutable del monto que se escribe con el teclado numérico propio.
/// Se guarda como texto ("12", "12.", "12.5") para respetar lo que el usuario
/// teclea, y se convierte a centavos al guardar.
class AmountInput {
  const AmountInput([this.text = '']);

  factory AmountInput.fromCents(int cents) {
    if (cents <= 0) return const AmountInput();
    final whole = cents ~/ 100;
    final rest = cents % 100;
    if (rest == 0) return AmountInput('$whole');
    return AmountInput('$whole.${rest.toString().padLeft(2, '0')}');
  }

  static const maxIntegerDigits = 9;

  final String text;

  bool get isEmpty => text.isEmpty;

  AmountInput press(String key) {
    if (key == '.') {
      if (text.contains('.')) return this;
      return AmountInput(text.isEmpty ? '0.' : '$text.');
    }
    if (text.contains('.')) {
      if (text.split('.')[1].length >= 2) return this;
      return AmountInput('$text$key');
    }
    if (text == '0') return AmountInput(key);
    if (text.length >= maxIntegerDigits) return this;
    if (text.isEmpty && key == '0') return const AmountInput('0');
    return AmountInput('$text$key');
  }

  AmountInput backspace() =>
      text.isEmpty ? this : AmountInput(text.substring(0, text.length - 1));

  int get cents {
    if (text.isEmpty) return 0;
    final parts = text.split('.');
    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0;
    final decimals = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return whole * 100 + (int.tryParse(decimals) ?? 0);
  }

  /// Texto para mostrar con separador de miles, conservando decimales
  /// parciales ("1,234." mientras el usuario escribe).
  String display(String symbol) {
    if (text.isEmpty) return '${symbol}0';
    final parts = text.split('.');
    final whole = NumberFormat('#,##0').format(int.tryParse(parts[0]) ?? 0);
    return parts.length > 1 ? '$symbol$whole.${parts[1]}' : '$symbol$whole';
  }

  @override
  bool operator ==(Object other) => other is AmountInput && other.text == text;

  @override
  int get hashCode => text.hashCode;
}
