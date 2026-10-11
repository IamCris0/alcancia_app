import 'package:alcancia_app/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('siembra categorías por defecto de gastos e ingresos', () async {
    final expenses = await db.watchCategories(CategoryKind.expense).first;
    final income = await db.watchCategories(CategoryKind.income).first;
    expect(expenses.map((c) => c.name), contains('Comida'));
    expect(income.map((c) => c.name), contains('Salario'));
  });

  test('crear, editar y archivar una cuenta', () async {
    final id = await db.addAccount(
      AccountsCompanion.insert(
        name: 'Efectivo',
        type: AccountType.cash,
        colorValue: 0xFF2EC4A0,
        iconKey: 'wallet',
        initialBalance: const Value(10000),
      ),
    );
    var list = await db.watchAccounts().first;
    expect(list.single.initialBalance, 10000);

    await db.updateAccount(list.single.copyWith(name: 'Cartera'));
    list = await db.watchAccounts().first;
    expect(list.single.name, 'Cartera');

    await db.archiveAccount(id);
    expect(await db.watchAccounts().first, isEmpty);
  });

  test('archivar una categoría la oculta', () async {
    final before = await db.watchCategories(CategoryKind.expense).first;
    await db.archiveCategory(before.first.id);
    final after = await db.watchCategories(CategoryKind.expense).first;
    expect(after.length, before.length - 1);
  });
}
