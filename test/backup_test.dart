import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:platapets/core/database/app_database.dart';
import 'package:platapets/core/database/gamification_queries.dart';
import 'package:platapets/core/database/planning_queries.dart';
import 'package:platapets/features/backup/backup_service.dart';
import 'package:platapets/features/reports/report_service.dart';
import 'package:platapets/features/security/app_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppDatabase> _filled() async {
  final db = AppDatabase(NativeDatabase.memory());
  final a = await db.addAccount(
    AccountsCompanion.insert(
      name: 'Banco',
      type: AccountType.bank,
      colorValue: 0xFF4DABF7,
      iconKey: 'bank',
      initialBalance: const Value(50000),
    ),
  );
  final food = (await db.watchCategories(CategoryKind.expense).first).first;
  await db.addMovement(
    MovementsCompanion.insert(
      type: MovementType.expense,
      amount: 1250,
      accountId: a,
      categoryId: Value(food.id),
      note: const Value('Pizza, "la mejor"'),
      date: DateTime(2026, 10, 20, 13),
    ),
  );
  await db.upsertBudget(food.id, 30000);
  await db.awardXp('day:2026-10-20', 15);
  await db.unlockAchievement('primer_paso');
  final g = await db.saveGoal(
    GoalsCompanion.insert(
      name: 'Viaje',
      target: 100000,
      iconKey: 'travel',
      colorValue: 0,
      deadline: Value(DateTime(2027, 6, 1)),
    ),
  );
  await db.contribute(g, 2000, DateTime(2026, 10, 21));
  final d = await db.saveDebt(
    DebtsCompanion.insert(person: 'Ana', kind: DebtKind.theyOwe, amount: 5000),
  );
  await db.payDebt(d, 1000, DateTime(2026, 10, 22));
  await db.saveRecurring(
    RecurringsCompanion.insert(
      name: 'Netflix',
      type: MovementType.expense,
      amount: 1500,
      accountId: a,
      categoryId: Value(food.id),
      frequency: Frequency.monthly,
      startDate: DateTime(2026, 11, 5),
      nextDate: DateTime(2026, 11, 5),
    ),
  );
  return db;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('respaldo: exportar y restaurar en otra base deja todo igual', () async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Cris',
      'mascot_species': 'cat',
      'mascot_name': 'Michi',
    });
    final prefs = await SharedPreferences.getInstance();
    final source = await _filled();
    final json = await BackupService(source, prefs).exportJson();

    // Base nueva con otros datos (deben desaparecer).
    final target = AppDatabase(NativeDatabase.memory());
    await target.addAccount(
      AccountsCompanion.insert(
        name: 'Basura',
        type: AccountType.cash,
        colorValue: 0,
        iconKey: 'wallet',
      ),
    );
    await prefs.setString('user_name', 'Otro');
    final service = BackupService(target, prefs);

    final summary = service.inspect(json);
    expect(summary.accounts, 1);
    expect(summary.movements, 1);
    expect(summary.goals, 1);

    await service.restore(json);
    final accounts = await target.watchAccountsWithBalance().first;
    expect(accounts.single.account.name, 'Banco');
    expect(accounts.single.balance, 50000 - 1250);
    expect(
      (await target.watchMovements(const MovementFilter()).first)
          .single
          .movement
          .note,
      'Pizza, "la mejor"',
    );
    expect(await target.xpTotal(), 15);
    expect((await target.watchUnlocked().first).keys, ['primer_paso']);
    expect(
      (await target.watchBudgets(DateTime(2026, 10)).first).single.spent,
      1250,
    );
    final goal = (await target.watchGoals().first).single;
    expect(goal.saved, 2000);
    expect(goal.goal.deadline, DateTime(2027, 6, 1));
    expect((await target.watchDebts().first).single.remaining, 4000);
    expect(
      (await target.watchRecurrings().first).single.recurring.name,
      'Netflix',
    );
    expect(prefs.getString('user_name'), 'Cris');
    expect(prefs.getString('mascot_name'), 'Michi');

    await source.close();
    await target.close();
  });

  test('respaldo: rechaza archivos que no son de PlataPets', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final service = BackupService(db, await SharedPreferences.getInstance());
    expect(() => service.inspect('hola'), throwsA(isA<BackupException>()));
    expect(
      () => service.inspect(jsonEncode({'format': 'otra-app', 'tables': {}})),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => service.inspect(
        jsonEncode({
          'format': BackupService.format,
          'schema': 999,
          'tables': {},
        }),
      ),
      throwsA(isA<BackupException>()),
    );
    await db.close();
  });

  test('CSV escapa comas y comillas', () async {
    final db = await _filled();
    final csv = await movementsCsv(db);
    final lines = const LineSplitter().convert(csv);
    expect(lines.first, startsWith('fecha,tipo,monto'));
    expect(lines[1], contains('2026-10-20,gasto,12.50'));
    expect(lines[1], contains('"Pizza, ""la mejor"""'));
    await db.close();
  });

  test('reporte PDF del mes', () async {
    final db = await _filled();
    final bytes = await buildMonthReport(
      db: db,
      month: DateTime(2026, 10),
      currency: 'USD',
      userName: 'Cris',
    );
    expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
    expect(bytes.length, greaterThan(1000));
    await db.close();
  });

  test('PIN: hash con sal, nunca en claro', () {
    final a = hashPin('1234', 'sal-a', rounds: 50);
    expect(a, isNot(contains('1234')));
    expect(hashPin('1234', 'sal-a', rounds: 50), a);
    expect(hashPin('1234', 'sal-b', rounds: 50), isNot(a));
    expect(hashPin('4321', 'sal-a', rounds: 50), isNot(a));
  });
}
