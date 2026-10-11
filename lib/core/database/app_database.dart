import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'models.dart';
import 'tables.dart';

export 'models.dart';
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

@DriftDatabase(tables: [Accounts, Categories, Movements])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'platapets'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(movements);
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
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

  /// Cuentas activas con su saldo actual calculado en SQL.
  Stream<List<AccountWithBalance>> watchAccountsWithBalance() {
    final income = MovementType.income.index;
    final transfer = MovementType.transfer.index;
    return customSelect(
      'SELECT a.*, a.initial_balance'
      ' + COALESCE((SELECT SUM(CASE m.type WHEN $income THEN m.amount'
      ' ELSE -m.amount END) FROM movements m WHERE m.account_id = a.id), 0)'
      ' + COALESCE((SELECT SUM(m.amount) FROM movements m'
      ' WHERE m.type = $transfer AND m.to_account_id = a.id), 0) AS balance'
      ' FROM accounts a WHERE a.archived = 0 ORDER BY a.id',
      readsFrom: {accounts, movements},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          AccountWithBalance(accounts.map(r.data), r.read<int>('balance')),
      ],
    );
  }

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

  // --- Movimientos ---

  Stream<List<MovementDetails>> watchMovements(MovementFilter f) {
    final toAcc = alias(accounts, 'to_acc');
    final query = select(movements).join([
      innerJoin(accounts, accounts.id.equalsExp(movements.accountId)),
      leftOuterJoin(toAcc, toAcc.id.equalsExp(movements.toAccountId)),
      leftOuterJoin(categories, categories.id.equalsExp(movements.categoryId)),
    ]);

    Expression<bool> where = const Constant(true);
    if (f.from != null) {
      where = where & movements.date.isBiggerOrEqualValue(f.from!);
    }
    if (f.to != null) where = where & movements.date.isSmallerThanValue(f.to!);
    if (f.type != null) where = where & movements.type.equalsValue(f.type);
    if (f.accountId != null) {
      where =
          where &
          (movements.accountId.equals(f.accountId!) |
              movements.toAccountId.equals(f.accountId!));
    }
    final text = f.query.trim();
    if (text.isNotEmpty) {
      final like = '%$text%';
      where =
          where &
          (movements.note.like(like) |
              categories.name.like(like) |
              accounts.name.like(like));
    }

    query
      ..where(where)
      ..orderBy([
        OrderingTerm.desc(movements.date),
        OrderingTerm.desc(movements.id),
      ]);
    if (f.limit != null) query.limit(f.limit!);

    return query.watch().map(
      (rows) => [
        for (final r in rows)
          MovementDetails(
            movement: r.readTable(movements),
            account: r.readTable(accounts),
            toAccount: r.readTableOrNull(toAcc),
            category: r.readTableOrNull(categories),
          ),
      ],
    );
  }

  Future<int> addMovement(MovementsCompanion movement) =>
      into(movements).insert(movement);

  Future<int> updateMovement(int id, MovementsCompanion changes) =>
      (update(movements)..where((m) => m.id.equals(id))).write(changes);

  Future<int> deleteMovement(int id) =>
      (delete(movements)..where((m) => m.id.equals(id))).go();

  /// Vuelve a insertar un movimiento borrado (para "Deshacer").
  Future<int> restoreMovement(Movement movement) =>
      into(movements).insert(movement);
}
