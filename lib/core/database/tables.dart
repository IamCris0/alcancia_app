import 'package:drift/drift.dart';

enum AccountType { cash, bank, card, savings }

enum CategoryKind { income, expense }

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
