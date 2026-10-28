import 'package:alcancia_app/core/database/app_database.dart';
import 'package:alcancia_app/features/dashboard/month_summary.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int a;
  late int b;
  late int food;
  late int salary;
  final oct = DateTime(2026, 10, 5);

  Future<int> account(String name, int initial) => db.addAccount(
    AccountsCompanion.insert(
      name: name,
      type: AccountType.cash,
      colorValue: 0,
      iconKey: 'wallet',
      initialBalance: Value(initial),
    ),
  );

  Future<int> move(
    MovementType type,
    int amount, {
    required int from,
    int? to,
    int? category,
    String? note,
    DateTime? date,
  }) => db.addMovement(
    MovementsCompanion.insert(
      type: type,
      amount: amount,
      accountId: from,
      toAccountId: Value(to),
      categoryId: Value(category),
      note: Value(note),
      date: date ?? oct,
    ),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    a = await account('Banco', 10000);
    b = await account('Ahorro', 0);
    food = (await db.watchCategories(CategoryKind.expense).first)
        .firstWhere((c) => c.name == 'Comida')
        .id;
    salary = (await db.watchCategories(CategoryKind.income).first)
        .firstWhere((c) => c.name == 'Salario')
        .id;
  });
  tearDown(() => db.close());

  test('el saldo incluye ingresos, gastos y transferencias', () async {
    await move(MovementType.income, 5000, from: a, category: salary);
    await move(MovementType.expense, 2000, from: a, category: food);
    await move(MovementType.transfer, 3000, from: a, to: b);

    final balances = {
      for (final x in await db.watchAccountsWithBalance().first)
        x.account.name: x.balance,
    };
    expect(balances['Banco'], 10000);
    expect(balances['Ahorro'], 3000);
  });

  test('filtra por mes, tipo y texto', () async {
    await move(
      MovementType.expense,
      100,
      from: a,
      category: food,
      note: 'pizza',
    );
    await move(MovementType.income, 900, from: a, category: salary);
    await move(
      MovementType.expense,
      50,
      from: a,
      category: food,
      date: DateTime(2026, 9, 30),
    );

    final month = MovementFilter.month(oct);
    expect(await db.watchMovements(month).first, hasLength(2));
    expect(
      await db
          .watchMovements(MovementFilter.month(oct, type: MovementType.expense))
          .first,
      hasLength(1),
    );
    final found = await db
        .watchMovements(MovementFilter.month(oct, query: 'pizz'))
        .first;
    expect(found.single.category?.name, 'Comida');
  });

  test('borrar y deshacer', () async {
    final id = await move(MovementType.expense, 700, from: a, category: food);
    final original =
        (await db.watchMovements(const MovementFilter()).first).single.movement;
    await db.deleteMovement(id);
    expect(await db.watchMovements(const MovementFilter()).first, isEmpty);
    await db.restoreMovement(original);
    expect(
      (await db.watchMovements(const MovementFilter()).first)
          .single
          .movement
          .id,
      id,
    );
  });

  test('resumen del mes', () async {
    await move(MovementType.income, 10000, from: a, category: salary);
    await move(MovementType.expense, 3000, from: a, category: food);
    await move(
      MovementType.expense,
      1000,
      from: a,
      category: food,
      date: DateTime(2026, 10, 7),
    );
    await move(MovementType.transfer, 500, from: a, to: b);

    final list = await db.watchMovements(MovementFilter.month(oct)).first;
    final s = MonthSummary.from(list, oct);
    expect(s.income, 10000);
    expect(s.expense, 4000);
    expect(s.net, 6000);
    expect(s.byCategory.single.total, 4000);
    expect(s.dailyExpense, hasLength(31));
    expect(s.dailyExpense[4], 3000);
    expect(s.dailyExpense[6], 1000);
  });
}
