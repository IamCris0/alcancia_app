import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';

/// Error de respaldo con un mensaje apto para mostrar al usuario.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resumen de un respaldo, para confirmar antes de restaurar.
class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.accounts,
    required this.movements,
    required this.goals,
  });

  final DateTime? exportedAt;
  final int accounts;
  final int movements;
  final int goals;
}

/// Exporta e importa TODOS los datos (tablas + preferencias) a un JSON.
class BackupService {
  BackupService(this.db, this.prefs);

  final AppDatabase db;
  final SharedPreferences prefs;

  static const format = 'platapets-backup';
  static const formatVersion = 1;

  static const _prefKeys = [
    'user_name',
    'currency',
    'mascot_species',
    'mascot_name',
    'mascot_accessory',
  ];

  /// Tablas en orden de dependencias (padres antes que hijos).
  List<(String, TableInfo<Table, dynamic>)> get _tables => [
    ('accounts', db.accounts),
    ('categories', db.categories),
    ('movements', db.movements),
    ('budgets', db.budgets),
    ('xp_events', db.xpEvents),
    ('achievements', db.achievements),
    ('streak_freezes', db.streakFreezes),
    ('goals', db.goals),
    ('goal_contributions', db.goalContributions),
    ('recurrings', db.recurrings),
    ('debts', db.debts),
    ('debt_payments', db.debtPayments),
  ];

  Future<Map<String, Object?>> export() async {
    final tables = <String, Object?>{};
    for (final (name, table) in _tables) {
      final rows = await db.select(table).get();
      tables[name] = [for (final r in rows) (r as DataClass).toJson()];
    }
    return {
      'format': format,
      'version': formatVersion,
      'schema': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prefs': {for (final k in _prefKeys) k: prefs.getString(k)},
      'tables': tables,
    };
  }

  Future<String> exportJson() async =>
      const JsonEncoder.withIndent(' ').convert(await export());

  /// Valida el contenido y devuelve un resumen sin modificar nada.
  BackupSummary inspect(String raw) {
    final data = _parse(raw);
    final tables = data['tables'] as Map<String, Object?>;
    int count(String t) => (tables[t] as List?)?.length ?? 0;
    return BackupSummary(
      exportedAt: DateTime.tryParse('${data['exportedAt']}'),
      accounts: count('accounts'),
      movements: count('movements'),
      goals: count('goals'),
    );
  }

  /// Reemplaza todos los datos actuales por los del respaldo. Todo ocurre en
  /// una transacción: si algo falla, no se toca nada.
  Future<void> restore(String raw) async {
    final data = _parse(raw);
    final tables = data['tables'] as Map<String, Object?>;
    await db.transaction(() async {
      for (final (_, table) in _tables.reversed) {
        await db.delete(table).go();
      }
      for (final (name, table) in _tables) {
        for (final row in (tables[name] as List?) ?? const []) {
          final json = Map<String, dynamic>.from(row as Map);
          if (name == 'movements') json.putIfAbsent('isAuto', () => false);
          await db
              .into(table)
              .insert(_fromJson(table, json), mode: InsertMode.insertOrReplace);
        }
      }
    });
    final savedPrefs = (data['prefs'] as Map?) ?? const {};
    for (final k in _prefKeys) {
      final v = savedPrefs[k];
      if (v is String) await prefs.setString(k, v);
    }
  }

  Insertable<dynamic> _fromJson(TableInfo table, Map<String, dynamic> j) =>
      switch (table) {
        _ when table == db.accounts => Account.fromJson(j),
        _ when table == db.categories => Category.fromJson(j),
        _ when table == db.movements => Movement.fromJson(j),
        _ when table == db.budgets => Budget.fromJson(j),
        _ when table == db.xpEvents => XpEvent.fromJson(j),
        _ when table == db.achievements => UnlockedAchievement.fromJson(j),
        _ when table == db.streakFreezes => StreakFreeze.fromJson(j),
        _ when table == db.goals => Goal.fromJson(j),
        _ when table == db.goalContributions => GoalContribution.fromJson(j),
        _ when table == db.recurrings => Recurring.fromJson(j),
        _ when table == db.debts => Debt.fromJson(j),
        _ when table == db.debtPayments => DebtPayment.fromJson(j),
        _ => throw const BackupException('Tabla desconocida'),
      };

  Map<String, Object?> _parse(String raw) {
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      throw const BackupException('El archivo no es un respaldo válido.');
    }
    if (data is! Map<String, Object?> ||
        data['format'] != format ||
        data['tables'] is! Map) {
      throw const BackupException(
        'Este archivo no es un respaldo de PlataPets.',
      );
    }
    final schema = data['schema'];
    if (schema is int && schema > db.schemaVersion) {
      throw const BackupException(
        'El respaldo es de una versión más nueva de la app. Actualízala.',
      );
    }
    return data;
  }
}

/// Movimientos en CSV (para Excel / Sheets). Separador coma, UTF-8.
Future<String> movementsCsv(AppDatabase db) async {
  final rows = await db.watchMovements(const MovementFilter()).first;
  String cell(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final b = StringBuffer(
    'fecha,tipo,monto,categoria,cuenta,cuenta_destino,nota\n',
  );
  for (final d in rows.reversed) {
    final m = d.movement;
    final type = switch (m.type) {
      MovementType.income => 'ingreso',
      MovementType.expense => 'gasto',
      MovementType.transfer => 'transferencia',
    };
    b.writeln(
      [
        m.date.toIso8601String().substring(0, 10),
        type,
        (m.amount / 100).toStringAsFixed(2),
        d.category?.name,
        d.account.name,
        d.toAccount?.name,
        m.note,
      ].map(cell).join(','),
    );
  }
  return b.toString();
}
