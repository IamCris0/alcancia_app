import 'package:drift/drift.dart';

import 'app_database.dart';

/// Presupuesto con lo gastado en el mes consultado.
class BudgetStatus {
  const BudgetStatus({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.spent,
    this.categoryName,
    this.iconKey,
    this.colorValue,
  });

  final int id;

  /// Nulo = presupuesto general.
  final int? categoryId;
  final int limit;
  final int spent;
  final String? categoryName;
  final String? iconKey;
  final int? colorValue;

  bool get isGeneral => categoryId == null;
  int get remaining => limit - spent;
  double get ratio => limit <= 0 ? 0 : spent / limit;
}

class MonthTotals {
  const MonthTotals(this.month, this.income, this.expense, this.count);

  /// Primer día del mes.
  final DateTime month;
  final int income;
  final int expense;
  final int count;
}

class MovementCounts {
  const MovementCounts(this.total, this.incomes, this.transfers);

  final int total;
  final int incomes;
  final int transfers;
}

extension GamificationQueries on AppDatabase {
  // --- Presupuestos ---

  Stream<List<BudgetStatus>> watchBudgets(DateTime month) {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    return customSelect(
      'SELECT b.id, b.category_id, b.amount, c.name, c.icon_key, '
      'c.color_value, COALESCE((SELECT SUM(m.amount) FROM movements m '
      'WHERE m.type = ${MovementType.expense.index} '
      'AND m.date >= ?1 AND m.date < ?2 '
      'AND (b.category_id IS NULL OR m.category_id = b.category_id)), 0) '
      'AS spent '
      'FROM budgets b LEFT JOIN categories c ON c.id = b.category_id '
      'ORDER BY b.category_id IS NOT NULL, b.id',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {budgets, movements, categories},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          BudgetStatus(
            id: r.read<int>('id'),
            categoryId: r.readNullable<int>('category_id'),
            limit: r.read<int>('amount'),
            spent: r.read<int>('spent'),
            categoryName: r.readNullable<String>('name'),
            iconKey: r.readNullable<String>('icon_key'),
            colorValue: r.readNullable<int>('color_value'),
          ),
      ],
    );
  }

  /// Crea o actualiza el presupuesto de una categoría (o el general si
  /// [categoryId] es nulo).
  Future<void> upsertBudget(int? categoryId, int amount) async {
    final existing =
        await (select(budgets)..where(
              (b) => categoryId == null
                  ? b.categoryId.isNull()
                  : b.categoryId.equals(categoryId),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await into(budgets).insert(
        BudgetsCompanion.insert(categoryId: Value(categoryId), amount: amount),
      );
    } else {
      await (update(budgets)..where((b) => b.id.equals(existing.id))).write(
        BudgetsCompanion(amount: Value(amount)),
      );
    }
  }

  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  Future<int> countBudgets() async {
    final c = budgets.id.count();
    return (await (selectOnly(budgets)..addColumns([c])).getSingle()).read(c) ??
        0;
  }

  // --- Rachas ---

  /// Momento en que se creó cada movimiento (la racha mide el hábito de
  /// registrar, no la fecha contable del movimiento).
  Stream<List<DateTime>> watchLogTimes() =>
      (selectOnly(movements)..addColumns([movements.createdAt])).watch().map(
        (rows) => [for (final r in rows) r.read(movements.createdAt)!],
      );

  Future<List<DateTime>> logTimes() => watchLogTimes().first;

  Stream<Set<DateTime>> watchFrozenDays() =>
      select(streakFreezes)
          .watch()
          .map((rows) => {for (final r in rows) r.day});

  Future<void> freezeDay(DateTime day) => into(streakFreezes).insert(
    StreakFreezesCompanion.insert(day: day),
    mode: InsertMode.insertOrIgnore,
  );

  // --- XP ---

  Stream<int> watchXpTotal() {
    final sum = xpEvents.amount.sum();
    return (selectOnly(
      xpEvents,
    )..addColumns([sum])).watchSingle().map((r) => r.read(sum) ?? 0);
  }

  Future<int> xpTotal() => watchXpTotal().first;

  /// Otorga XP una sola vez por [key]. Devuelve si se otorgó.
  Future<bool> awardXp(String key, int amount, {DateTime? at}) =>
      transaction(() async {
        final exists = await (select(
          xpEvents,
        )..where((x) => x.key.equals(key))).getSingleOrNull();
        if (exists != null) return false;
        await into(xpEvents).insert(
          XpEventsCompanion.insert(
            key: key,
            amount: amount,
            createdAt: at == null ? const Value.absent() : Value(at),
          ),
        );
        return true;
      });

  Future<int> countXpKeys(String prefix, {DateTime? since}) async {
    final c = xpEvents.id.count();
    final q = selectOnly(xpEvents)
      ..addColumns([c])
      ..where(xpEvents.key.like('$prefix%'));
    if (since != null) q.where(xpEvents.createdAt.isBiggerOrEqualValue(since));
    return (await q.getSingle()).read(c) ?? 0;
  }

  // --- Logros ---

  Stream<Map<String, DateTime>> watchUnlocked() =>
      select(achievements)
          .watch()
          .map((rows) => {for (final r in rows) r.key: r.unlockedAt});

  Future<bool> unlockAchievement(String key) => transaction(() async {
    final exists = await (select(
      achievements,
    )..where((a) => a.key.equals(key))).getSingleOrNull();
    if (exists != null) return false;
    await into(achievements).insert(AchievementsCompanion.insert(key: key));
    return true;
  });

  // --- Estadísticas ---

  Future<MovementCounts> movementCounts() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS total, '
      'COALESCE(SUM(type = ${MovementType.income.index}), 0) AS incomes, '
      'COALESCE(SUM(type = ${MovementType.transfer.index}), 0) AS transfers '
      'FROM movements',
      readsFrom: {movements},
    ).getSingle();
    return MovementCounts(
      row.read<int>('total'),
      row.read<int>('incomes'),
      row.read<int>('transfers'),
    );
  }

  Future<int> expenseCategoriesUsed() async {
    final row = await customSelect(
      'SELECT COUNT(DISTINCT category_id) AS n FROM movements '
      'WHERE type = ${MovementType.expense.index} AND category_id IS NOT NULL',
      readsFrom: {movements},
    ).getSingle();
    return row.read<int>('n');
  }

  /// Ingresos y gastos por mes (hora local).
  Future<List<MonthTotals>> monthTotals() async {
    final rows = await customSelect(
      "SELECT strftime('%Y-%m', date, 'unixepoch', 'localtime') AS ym, "
      'SUM(CASE WHEN type = ${MovementType.income.index} THEN amount '
      'ELSE 0 END) AS income, '
      'SUM(CASE WHEN type = ${MovementType.expense.index} THEN amount '
      'ELSE 0 END) AS expense, COUNT(*) AS n '
      'FROM movements GROUP BY ym ORDER BY ym',
      readsFrom: {movements},
    ).get();
    return [
      for (final r in rows)
        MonthTotals(
          DateTime(
            int.parse(r.read<String>('ym').substring(0, 4)),
            int.parse(r.read<String>('ym').substring(5, 7)),
          ),
          r.read<int>('income'),
          r.read<int>('expense'),
          r.read<int>('n'),
        ),
    ];
  }

  Future<int?> generalBudgetAmount() async {
    final b = await (select(
      budgets,
    )..where((b) => b.categoryId.isNull())).getSingleOrNull();
    return b?.amount;
  }
}
