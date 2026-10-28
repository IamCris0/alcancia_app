import '../../core/database/app_database.dart';

String frequencyLabel(Frequency f) => switch (f) {
  Frequency.weekly => 'Cada semana',
  Frequency.monthly => 'Cada mes',
  Frequency.yearly => 'Cada año',
};

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Ocurrencia número [n] (0 = la primera) contada desde [start]. El día del
/// mes se ancla al de [start]: un pago del 31 cae el 28/29 en febrero y
/// vuelve al 31 en marzo.
DateTime occurrence(DateTime start, Frequency f, int n) {
  switch (f) {
    case Frequency.weekly:
      return DateTime(start.year, start.month, start.day + 7 * n);
    case Frequency.monthly:
      final month = start.month + n;
      final y = start.year + (month - 1) ~/ 12;
      final m = (month - 1) % 12 + 1;
      return DateTime(y, m, start.day.clamp(1, _daysInMonth(y, m)));
    case Frequency.yearly:
      final y = start.year + n;
      return DateTime(
        y,
        start.month,
        start.day.clamp(1, _daysInMonth(y, start.month)),
      );
  }
}

/// Primera ocurrencia estrictamente posterior a [after].
DateTime nextAfter(DateTime start, Frequency f, DateTime after) {
  var n = 0;
  var d = occurrence(start, f, n);
  while (!d.isAfter(after)) {
    n++;
    d = occurrence(start, f, n);
  }
  return d;
}

/// Ocurrencias desde [from] (inclusive) hasta [until] (inclusive), con tope
/// para no generar cientos si la app no se abrió en mucho tiempo.
List<DateTime> dueOccurrences(
  DateTime start,
  Frequency f,
  DateTime from,
  DateTime until, {
  int max = 12,
}) {
  final out = <DateTime>[];
  var n = 0;
  var d = occurrence(start, f, n);
  while (!d.isAfter(until) && out.length < max) {
    if (!d.isBefore(from)) out.add(d);
    n++;
    d = occurrence(start, f, n);
  }
  return out;
}
