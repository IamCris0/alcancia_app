import 'package:drift/drift.dart';

enum AccountType { cash, bank, card, savings }

enum CategoryKind { income, expense }

/// El orden importa: se guarda como entero y se usa en SQL (0, 1, 2).
enum MovementType { income, expense, transfer }

/// Los montos se guardan en centavos (enteros) para evitar errores de
/// punto flotante.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get type => intEnum<AccountType>()();
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get kind => intEnum<CategoryKind>()();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Ingresos, gastos y transferencias. `amount` siempre es positivo (centavos);
/// el signo lo da `type`.
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<MovementType>()();
  IntColumn get amount => integer()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Límite de gasto mensual. `categoryId` nulo = presupuesto general del mes
/// (solo debe existir uno; lo garantiza `upsertBudget`).
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().nullable().unique().references(Categories, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Libro de XP ganada. `key` es única para no premiar dos veces lo mismo
/// (p. ej. `mov:12`, `day:2026-10-11`, `ach:racha_7`). Borrar un movimiento
/// no quita la XP ya ganada.
class XpEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('UnlockedAchievement')
class Achievements extends Table {
  TextColumn get key => text()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Días "congelados": cuentan para la racha aunque no se registró nada.
class StreakFreezes extends Table {
  DateTimeColumn get day => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}
