import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platapets/core/database/app_database.dart';
import 'package:platapets/core/database/gamification_queries.dart';
import 'package:platapets/features/gamification/gamification_service.dart';
import 'package:platapets/features/gamification/streak.dart';

void main() {
  late AppDatabase db;
  late GamificationService service;
  late int account;
  late int food;
  late int salary;
  var now = DateTime(2026, 10, 11, 15);

  Future<Movement> log(
    MovementType type,
    int amount, {
    DateTime? at,
    int? category,
  }) async {
    final when = at ?? now;
    final id = await db.addMovement(
      MovementsCompanion.insert(
        type: type,
        amount: amount,
        accountId: account,
        categoryId: Value(category ?? food),
        date: when,
        createdAt: Value(when),
      ),
    );
    return (db.select(db.movements)..where((m) => m.id.equals(id))).getSingle();
  }

  setUp(() async {
    now = DateTime(2026, 10, 11, 15);
    db = AppDatabase(NativeDatabase.memory());
    service = GamificationService(db, clock: () => now);
    account = await db.addAccount(
      AccountsCompanion.insert(
        name: 'Efectivo',
        type: AccountType.cash,
        colorValue: 0,
        iconKey: 'wallet',
      ),
    );
    final expense = await db.watchCategories(CategoryKind.expense).first;
    final income = await db.watchCategories(CategoryKind.income).first;
    food = expense.firstWhere((c) => c.name == 'Comida').id;
    salary = income.firstWhere((c) => c.name == 'Salario').id;
  });
  tearDown(() => db.close());

  test('primer movimiento: XP, bono diario y logro "Primer paso"', () async {
    final m = await log(MovementType.expense, 500);
    final r = await service.onMovementSaved(m);

    expect(r.unlocked.map((a) => a.key), contains('primer_paso'));
    // 10 por registrar + 5 de bono diario + 20 del logro.
    expect(r.xpGained, 35);
    expect(await db.xpTotal(), 35);
    expect(r.streak, 1);
  });

  test('la XP por registrar tiene tope diario', () async {
    for (var i = 0; i < 7; i++) {
      await service.onMovementSaved(await log(MovementType.expense, 100));
    }
    expect(
      await db.countXpKeys('mov:'),
      GamificationService.maxMovementXpPerDay,
    );
  });

  test('editar no da XP', () async {
    final m = await log(MovementType.expense, 100);
    final r = await service.onMovementSaved(m, isNew: false);
    expect(r.xpGained, 0);
    expect(await db.xpTotal(), 0);
  });

  test('racha de 3 días: bono mayor y logro "En marcha"', () async {
    await log(MovementType.expense, 100, at: addDays(now, -2));
    await log(MovementType.expense, 100, at: addDays(now, -1));
    final r = await service.onMovementSaved(
      await log(MovementType.expense, 100),
    );
    expect(r.streak, 3);
    expect(r.unlocked.map((a) => a.key), contains('racha_3'));
  });

  test('un congelador salva la racha si faltó un solo día', () async {
    // 8 días seguidos (gana un congelador), falta ayer, registra hoy.
    for (var i = 9; i >= 2; i--) {
      await log(MovementType.expense, 100, at: addDays(now, -i));
    }
    final r = await service.onMovementSaved(
      await log(MovementType.expense, 100),
    );
    expect(r.freezeUsed, isTrue);
    expect(r.streak, 10);
    expect(await db.watchFrozenDays().first, contains(dayOf(addDays(now, -1))));
  });

  test('alerta de presupuesto al 80 % y al pasarse', () async {
    await db.upsertBudget(food, 10000);
    final first = await service.onMovementSaved(
      await log(MovementType.expense, 8500),
    );
    expect(first.alert?.level, BudgetAlertLevel.warning);
    expect(first.alert?.name, 'Comida');

    final second = await service.onMovementSaved(
      await log(MovementType.expense, 2000),
    );
    expect(second.alert?.level, BudgetAlertLevel.exceeded);
    expect(second.alert?.remaining, -500);
  });

  test('presupuesto general: una sola fila y gasto del mes', () async {
    await db.upsertBudget(null, 5000);
    await db.upsertBudget(null, 9000);
    await log(MovementType.expense, 1200);
    await log(MovementType.income, 9999, category: salary);
    final budgets = await db.watchBudgets(now).first;
    expect(budgets, hasLength(1));
    expect(budgets.single.limit, 9000);
    expect(budgets.single.spent, 1200);
  });

  test('al abrir premia el mes anterior dentro del presupuesto', () async {
    await db.upsertBudget(null, 10000);
    await log(MovementType.expense, 4000, at: DateTime(2026, 9, 10, 12));
    await log(
      MovementType.income,
      9000,
      at: DateTime(2026, 9, 12, 12),
      category: salary,
    );

    final r = await service.syncOnStart();
    final keys = r.unlocked.map((a) => a.key);
    expect(keys, containsAll(['bajo_presupuesto', 'mes_positivo']));

    // No se premia dos veces.
    final again = await service.syncOnStart();
    expect(again.xpGained, 0);
    expect(again.unlocked, isEmpty);
  });
}
