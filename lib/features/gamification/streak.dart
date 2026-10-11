/// Rachas: días seguidos registrando al menos un movimiento. Los días
/// "congelados" cuentan como registrados.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Usar el calendario (no restar 24 h) evita errores con cambios de horario.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.loggedToday,
    required this.freezesAvailable,
    required this.activeDays,
  });

  static const empty = StreakInfo(
    current: 0,
    best: 0,
    loggedToday: false,
    freezesAvailable: 0,
    activeDays: {},
  );

  final int current;
  final int best;
  final bool loggedToday;
  final int freezesAvailable;

  /// Días registrados o congelados (a medianoche local).
  final Set<DateTime> activeDays;

  /// La racha sigue viva pero hoy aún no se registró nada.
  bool get atRisk => current > 0 && !loggedToday;
}

/// Se gana un congelador por cada 7 días registrados; se guardan como
/// máximo 2 sin usar.
const maxFreezes = 2;

int freezesAvailable({required int loggedDays, required int usedFreezes}) =>
    ((loggedDays ~/ 7) - usedFreezes).clamp(0, maxFreezes);

StreakInfo computeStreak({
  required Set<DateTime> loggedDays,
  required Set<DateTime> frozenDays,
  required DateTime today,
}) {
  final t = dayOf(today);
  final logged = {for (final d in loggedDays) dayOf(d)};
  final active = {...logged, for (final d in frozenDays) dayOf(d)};

  var current = 0;
  // Si hoy no hay registro, la racha se cuenta hasta ayer (sigue viva).
  var cursor = active.contains(t) ? t : addDays(t, -1);
  while (active.contains(cursor)) {
    current++;
    cursor = addDays(cursor, -1);
  }

  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final d in active.toList()..sort()) {
    run = (prev != null && addDays(prev, 1) == d) ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }

  return StreakInfo(
    current: current,
    best: best,
    loggedToday: logged.contains(t),
    freezesAvailable: freezesAvailable(
      loggedDays: logged.length,
      usedFreezes: frozenDays.length,
    ),
    activeDays: active,
  );
}

/// Si al registrar hoy quedó un único día sin registrar entre la racha y
/// hoy, devuelve ese día para congelarlo (si hay congeladores).
DateTime? dayToFreeze({
  required Set<DateTime> activeDaysBeforeToday,
  required DateTime today,
  required int available,
}) {
  if (available <= 0) return null;
  final t = dayOf(today);
  final yesterday = addDays(t, -1);
  final before = addDays(t, -2);
  final days = {for (final d in activeDaysBeforeToday) dayOf(d)};
  if (!days.contains(yesterday) && days.contains(before)) return yesterday;
  return null;
}
