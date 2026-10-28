import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/database/planning_queries.dart';
import '../gamification/streak.dart';
import 'recurrence.dart';

/// Procesa los movimientos recurrentes: registra solos los automáticos y
/// permite confirmar u omitir los manuales.
class RecurringService {
  RecurringService(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  static DateTime _noon(DateTime d) => DateTime(d.year, d.month, d.day, 12);

  bool isDue(Recurring r) => !dayOf(r.nextDate).isAfter(dayOf(_clock()));

  /// Registra las ocurrencias vencidas de los recurrentes automáticos y
  /// devuelve cuántos movimientos creó.
  Future<int> processDue() async {
    final today = dayOf(_clock());
    var created = 0;
    for (final d in await db.watchRecurrings().first) {
      final r = d.recurring;
      if (!r.active || !r.autoRegister || !isDue(r)) continue;
      final dates = dueOccurrences(r.startDate, r.frequency, r.nextDate, today);
      await db.transaction(() async {
        for (final date in dates) {
          await db.addMovement(_movementFor(r, date, auto: true));
          created++;
        }
        await db.saveRecurring(
          RecurringsCompanion(
            id: Value(r.id),
            nextDate: Value(nextAfter(r.startDate, r.frequency, today)),
          ),
        );
      });
    }
    return created;
  }

  /// Registra la ocurrencia pendiente de un recurrente manual. Devuelve el
  /// movimiento creado (cuenta para racha y XP: lo registró el usuario).
  Future<Movement> confirm(Recurring r) async {
    final id = await db.transaction(() async {
      final id = await db.addMovement(_movementFor(r, r.nextDate, auto: false));
      await _advance(r);
      return id;
    });
    return (db.select(db.movements)..where((m) => m.id.equals(id))).getSingle();
  }

  Future<void> skip(Recurring r) => _advance(r);

  Future<void> _advance(Recurring r) => db.saveRecurring(
    RecurringsCompanion(
      id: Value(r.id),
      nextDate: Value(nextAfter(r.startDate, r.frequency, r.nextDate)),
    ),
  );

  MovementsCompanion _movementFor(
    Recurring r,
    DateTime date, {
    required bool auto,
  }) => MovementsCompanion.insert(
    type: r.type,
    amount: r.amount,
    accountId: r.accountId,
    categoryId: Value(r.type == MovementType.transfer ? null : r.categoryId),
    note: Value(r.name),
    date: _noon(date),
    isAuto: Value(auto),
  );
}
