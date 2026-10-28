import 'package:drift/drift.dart';

import 'app_database.dart';

class GoalStatus {
  const GoalStatus(this.goal, this.saved);

  final Goal goal;
  final int saved;

  double get progress => goal.target <= 0 ? 0 : saved / goal.target;
  int get remaining => goal.target - saved;
  bool get completed => goal.completedAt != null;
}

class DebtStatus {
  const DebtStatus(this.debt, this.paid);

  final Debt debt;
  final int paid;

  int get remaining => debt.amount - paid;
  double get progress => debt.amount <= 0 ? 0 : paid / debt.amount;
  bool get settled => debt.settledAt != null;
}

class RecurringDetails {
  const RecurringDetails(this.recurring, this.account, this.category);

  final Recurring recurring;
  final Account account;
  final Category? category;
}

extension PlanningQueries on AppDatabase {
  // --- Metas ---

  Stream<List<GoalStatus>> watchGoals() =>
      customSelect(
        'SELECT g.*, COALESCE((SELECT SUM(c.amount) FROM goal_contributions c '
        'WHERE c.goal_id = g.id), 0) AS saved FROM goals g '
        'ORDER BY g.completed_at IS NOT NULL, g.id',
        readsFrom: {goals, goalContributions},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            GoalStatus(goals.map(r.data), r.read<int>('saved')),
        ],
      );

  Future<GoalStatus> goalStatus(int id) async =>
      (await watchGoals().first).firstWhere((g) => g.goal.id == id);

  Future<int> saveGoal(GoalsCompanion goal) => goal.id.present
      ? (update(goals)..where((g) => g.id.equals(goal.id.value)))
            .write(goal)
            .then((_) => goal.id.value)
      : into(goals).insert(goal);

  Future<void> deleteGoal(int id) => transaction(() async {
    await (delete(goalContributions)..where((c) => c.goalId.equals(id))).go();
    await (delete(goals)..where((g) => g.id.equals(id))).go();
  });

  /// Registra un aporte (o retiro si es negativo) y devuelve si con él la
  /// meta quedó cumplida por primera vez.
  Future<bool> contribute(int goalId, int amount, DateTime date) =>
      transaction(() async {
        await into(goalContributions).insert(
          GoalContributionsCompanion.insert(
            goalId: goalId,
            amount: amount,
            date: date,
          ),
        );
        final status = await goalStatus(goalId);
        if (!status.completed && status.saved >= status.goal.target) {
          await (update(goals)..where((g) => g.id.equals(goalId))).write(
            GoalsCompanion(completedAt: Value(date)),
          );
          return true;
        }
        return false;
      });

  Stream<List<GoalContribution>> watchContributions(int goalId) =>
      (select(goalContributions)
            ..where((c) => c.goalId.equals(goalId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.date),
              (c) => OrderingTerm.desc(c.id),
            ]))
          .watch();

  // --- Deudas ---

  Stream<List<DebtStatus>> watchDebts() =>
      customSelect(
        'SELECT d.*, COALESCE((SELECT SUM(p.amount) FROM debt_payments p '
        'WHERE p.debt_id = d.id), 0) AS paid FROM debts d '
        'ORDER BY d.settled_at IS NOT NULL, d.due_date IS NULL, d.due_date, d.id',
        readsFrom: {debts, debtPayments},
      ).watch().map(
        (rows) => [
          for (final r in rows)
            DebtStatus(debts.map(r.data), r.read<int>('paid')),
        ],
      );

  Future<int> saveDebt(DebtsCompanion debt) => debt.id.present
      ? (update(debts)..where((d) => d.id.equals(debt.id.value)))
            .write(debt)
            .then((_) => debt.id.value)
      : into(debts).insert(debt);

  Future<void> deleteDebt(int id) => transaction(() async {
    await (delete(debtPayments)..where((p) => p.debtId.equals(id))).go();
    await (delete(debts)..where((d) => d.id.equals(id))).go();
  });

  /// Registra un abono y devuelve si con él la deuda quedó saldada.
  Future<bool> payDebt(int debtId, int amount, DateTime date) =>
      transaction(() async {
        await into(debtPayments).insert(
          DebtPaymentsCompanion.insert(
            debtId: debtId,
            amount: amount,
            date: date,
          ),
        );
        final status = (await watchDebts().first).firstWhere(
          (d) => d.debt.id == debtId,
        );
        if (!status.settled && status.paid >= status.debt.amount) {
          await (update(debts)..where((d) => d.id.equals(debtId))).write(
            DebtsCompanion(settledAt: Value(date)),
          );
          return true;
        }
        return false;
      });

  Stream<List<DebtPayment>> watchDebtPayments(int debtId) =>
      (select(debtPayments)
            ..where((p) => p.debtId.equals(debtId))
            ..orderBy([(p) => OrderingTerm.desc(p.date)]))
          .watch();

  // --- Recurrentes ---

  Stream<List<RecurringDetails>> watchRecurrings() {
    final q = select(recurrings).join([
      innerJoin(accounts, accounts.id.equalsExp(recurrings.accountId)),
      leftOuterJoin(categories, categories.id.equalsExp(recurrings.categoryId)),
    ])..orderBy([OrderingTerm.asc(recurrings.nextDate)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RecurringDetails(
            r.readTable(recurrings),
            r.readTable(accounts),
            r.readTableOrNull(categories),
          ),
      ],
    );
  }

  Future<int> saveRecurring(RecurringsCompanion r) => r.id.present
      ? (update(recurrings)..where((x) => x.id.equals(r.id.value)))
            .write(r)
            .then((_) => r.id.value)
      : into(recurrings).insert(r);

  Future<int> deleteRecurring(int id) =>
      (delete(recurrings)..where((r) => r.id.equals(id))).go();

  // --- Conteos para logros ---

  Future<({int goals, int goalsDone, int debtsSettled, int recurrings})>
  planningCounts() async {
    final row = await customSelect(
      'SELECT (SELECT COUNT(*) FROM goals) AS g, '
      '(SELECT COUNT(*) FROM goals WHERE completed_at IS NOT NULL) AS gd, '
      '(SELECT COUNT(*) FROM debts WHERE settled_at IS NOT NULL) AS ds, '
      '(SELECT COUNT(*) FROM recurrings) AS r',
      readsFrom: {goals, debts, recurrings},
    ).getSingle();
    return (
      goals: row.read<int>('g'),
      goalsDone: row.read<int>('gd'),
      debtsSettled: row.read<int>('ds'),
      recurrings: row.read<int>('r'),
    );
  }
}
