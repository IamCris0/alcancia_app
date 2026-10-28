import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platapets/core/database/app_database.dart';
import 'package:platapets/core/database/gamification_queries.dart';

/// Simula una base creada por la versión anterior (esquema v3) con datos
/// reales y comprueba que al abrirla con el código actual no se pierde nada.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('platapets_mig');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('v3 → v4 conserva cuentas, movimientos, presupuestos y XP', () async {
    // 1. Crear datos y "bajar" el archivo a la forma exacta de v3.
    var db = AppDatabase(NativeDatabase(file));
    final account = await db.addAccount(
      AccountsCompanion.insert(
        name: 'Banco',
        type: AccountType.bank,
        colorValue: 0,
        iconKey: 'bank',
        initialBalance: const Value(100000),
      ),
    );
    final food = (await db.watchCategories(CategoryKind.expense).first).first;
    await db.addMovement(
      MovementsCompanion.insert(
        type: MovementType.expense,
        amount: 2500,
        accountId: account,
        categoryId: Value(food.id),
        date: DateTime(2026, 10, 20),
      ),
    );
    await db.upsertBudget(food.id, 50000);
    await db.awardXp('day:2026-10-20', 15);
    for (final t in [
      'goals',
      'goal_contributions',
      'recurrings',
      'debts',
      'debt_payments',
    ]) {
      await db.customStatement('DROP TABLE $t');
    }
    await db.customStatement('ALTER TABLE movements DROP COLUMN is_auto');
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();

    // 2. Abrir con el código actual: corre la migración.
    db = AppDatabase(NativeDatabase(file));
    final balances = await db.watchAccountsWithBalance().first;
    expect(balances.single.balance, 97500);
    final movements = await db.watchMovements(const MovementFilter()).first;
    expect(movements.single.movement.amount, 2500);
    expect(movements.single.movement.isAuto, isFalse);
    expect(
      (await db.watchBudgets(DateTime(2026, 10)).first).single.spent,
      2500,
    );
    expect(await db.xpTotal(), 15);

    // 3. Las tablas nuevas funcionan.
    final goal = await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            name: 'Viaje',
            target: 100000,
            iconKey: 'travel',
            colorValue: 0,
          ),
        );
    expect(goal, greaterThan(0));
    await db.close();
  });
}
