import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

typedef _SeedCategory = (
  String name,
  CategoryKind kind,
  String icon,
  int color,
);

const _defaultCategories = <_SeedCategory>[
  ('Comida', CategoryKind.expense, 'restaurant', 0xFFFF922B),
  ('Transporte', CategoryKind.expense, 'bus', 0xFF4DABF7),
  ('Hogar', CategoryKind.expense, 'home', 0xFF845EF7),
  ('Salud', CategoryKind.expense, 'health', 0xFFFF6B6B),
  ('Ocio', CategoryKind.expense, 'games', 0xFFFF8FAB),
  ('Compras', CategoryKind.expense, 'shopping', 0xFFFFC233),
  ('Educación', CategoryKind.expense, 'school', 0xFF2EC4A0),
  ('Servicios', CategoryKind.expense, 'bill', 0xFF868E96),
  ('Otros gastos', CategoryKind.expense, 'other', 0xFF868E96),
  ('Salario', CategoryKind.income, 'payments', 0xFF2EC4A0),
  ('Freelance', CategoryKind.income, 'work', 0xFF4DABF7),
  ('Regalos', CategoryKind.income, 'gift', 0xFFFF8FAB),
  ('Inversiones', CategoryKind.income, 'trending', 0xFF51CF66),
  ('Otros ingresos', CategoryKind.income, 'other', 0xFF868E96),
];

@DriftDatabase(tables: [Accounts, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'alcancia'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
  );

  Future<void> _seedCategories() => batch((b) {
    b.insertAll(categories, [
      for (final (i, c) in _defaultCategories.indexed)
        CategoriesCompanion.insert(
          name: c.$1,
          kind: c.$2,
          iconKey: c.$3,
          colorValue: c.$4,
          sortOrder: Value(i),
        ),
    ]);
  });

  // --- Cuentas ---

  Stream<List<Account>> watchAccounts() =>
      (select(accounts)
            ..where((a) => a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .watch();

  Future<int> addAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<bool> updateAccount(Account account) =>
      update(accounts).replace(account);

  Future<void> archiveAccount(int id) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(archived: Value(true)),
      );

  // --- Categorías ---

  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      (select(categories)
            ..where((c) => c.archived.equals(false) & c.kind.equalsValue(kind))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<int> addCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  Future<void> archiveCategory(int id) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        const CategoriesCompanion(archived: Value(true)),
      );
}
