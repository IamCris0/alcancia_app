import 'package:flutter/material.dart';

/// Datos agregados con los que se evalúan los logros.
class GameStats {
  const GameStats({
    this.totalMovements = 0,
    this.hasIncome = false,
    this.hasTransfer = false,
    this.expenseCategoriesUsed = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.budgets = 0,
    this.monthsUnderBudget = 0,
    this.positiveMonths = 0,
    this.loggedLate = false,
    this.loggedEarly = false,
    this.level = 1,
    this.goals = 0,
    this.goalsDone = 0,
    this.debtsSettled = 0,
    this.recurrings = 0,
    this.backups = 0,
  });

  final int totalMovements;
  final bool hasIncome;
  final bool hasTransfer;
  final int expenseCategoriesUsed;
  final int currentStreak;
  final int bestStreak;
  final int budgets;
  final int monthsUnderBudget;
  final int positiveMonths;
  final bool loggedLate;
  final bool loggedEarly;
  final int level;
  final int goals;
  final int goalsDone;
  final int debtsSettled;
  final int recurrings;
  final int backups;
}

class AchievementDef {
  const AchievementDef({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xp,
    required this.test,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xp;
  final bool Function(GameStats s) test;
}

final achievementDefs = <AchievementDef>[
  AchievementDef(
    key: 'primer_paso',
    title: 'Primer paso',
    description: 'Registra tu primer movimiento.',
    icon: Icons.flag_rounded,
    color: const Color(0xFF7C5CFF),
    xp: 20,
    test: (s) => s.totalMovements >= 1,
  ),
  AchievementDef(
    key: 'primer_ingreso',
    title: '¡Cobraste!',
    description: 'Registra un ingreso.',
    icon: Icons.payments_rounded,
    color: const Color(0xFF12B886),
    xp: 20,
    test: (s) => s.hasIncome,
  ),
  AchievementDef(
    key: 'racha_3',
    title: 'En marcha',
    description: 'Mantén una racha de 3 días.',
    icon: Icons.local_fire_department_rounded,
    color: const Color(0xFFFF922B),
    xp: 30,
    test: (s) => s.bestStreak >= 3,
  ),
  AchievementDef(
    key: 'racha_7',
    title: 'Semana perfecta',
    description: 'Mantén una racha de 7 días.',
    icon: Icons.whatshot_rounded,
    color: const Color(0xFFFA5252),
    xp: 70,
    test: (s) => s.bestStreak >= 7,
  ),
  AchievementDef(
    key: 'racha_30',
    title: 'Imparable',
    description: 'Mantén una racha de 30 días.',
    icon: Icons.bolt_rounded,
    color: const Color(0xFFFFC233),
    xp: 300,
    test: (s) => s.bestStreak >= 30,
  ),
  AchievementDef(
    key: 'mov_25',
    title: 'Constante',
    description: 'Registra 25 movimientos.',
    icon: Icons.receipt_long_rounded,
    color: const Color(0xFF4DABF7),
    xp: 50,
    test: (s) => s.totalMovements >= 25,
  ),
  AchievementDef(
    key: 'mov_100',
    title: 'Contador experto',
    description: 'Registra 100 movimientos.',
    icon: Icons.workspace_premium_rounded,
    color: const Color(0xFF845EF7),
    xp: 150,
    test: (s) => s.totalMovements >= 100,
  ),
  AchievementDef(
    key: 'transferencia',
    title: 'Malabarista',
    description: 'Haz una transferencia entre cuentas.',
    icon: Icons.swap_horiz_rounded,
    color: const Color(0xFF7C5CFF),
    xp: 20,
    test: (s) => s.hasTransfer,
  ),
  AchievementDef(
    key: 'explorador',
    title: 'Explorador',
    description: 'Usa 5 categorías de gasto distintas.',
    icon: Icons.explore_rounded,
    color: const Color(0xFF2EC4A0),
    xp: 40,
    test: (s) => s.expenseCategoriesUsed >= 5,
  ),
  AchievementDef(
    key: 'presupuesto',
    title: 'Con un plan',
    description: 'Crea tu primer presupuesto.',
    icon: Icons.pie_chart_rounded,
    color: const Color(0xFFFF8FAB),
    xp: 30,
    test: (s) => s.budgets >= 1,
  ),
  AchievementDef(
    key: 'bajo_presupuesto',
    title: 'Bajo control',
    description: 'Termina un mes dentro de tu presupuesto general.',
    icon: Icons.verified_rounded,
    color: const Color(0xFF12B886),
    xp: 100,
    test: (s) => s.monthsUnderBudget >= 1,
  ),
  AchievementDef(
    key: 'mes_positivo',
    title: 'Mes en verde',
    description: 'Termina un mes con más ingresos que gastos.',
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF51CF66),
    xp: 80,
    test: (s) => s.positiveMonths >= 1,
  ),
  AchievementDef(
    key: 'buho',
    title: 'Búho',
    description: 'Registra algo después de las 11 de la noche.',
    icon: Icons.nightlight_round,
    color: const Color(0xFF5C7CFA),
    xp: 15,
    test: (s) => s.loggedLate,
  ),
  AchievementDef(
    key: 'madrugador',
    title: 'Madrugador',
    description: 'Registra algo antes de las 7 de la mañana.',
    icon: Icons.wb_twilight_rounded,
    color: const Color(0xFFFFA94D),
    xp: 15,
    test: (s) => s.loggedEarly,
  ),
  AchievementDef(
    key: 'primera_meta',
    title: 'Soñador',
    description: 'Crea tu primera meta de ahorro.',
    icon: Icons.savings_rounded,
    color: const Color(0xFF4DABF7),
    xp: 30,
    test: (s) => s.goals >= 1,
  ),
  AchievementDef(
    key: 'meta_cumplida',
    title: 'Meta cumplida',
    description: 'Completa una meta de ahorro.',
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFFC233),
    xp: 150,
    test: (s) => s.goalsDone >= 1,
  ),
  AchievementDef(
    key: 'deuda_saldada',
    title: 'Cuentas claras',
    description: 'Salda una deuda por completo.',
    icon: Icons.handshake_rounded,
    color: const Color(0xFF12B886),
    xp: 80,
    test: (s) => s.debtsSettled >= 1,
  ),
  AchievementDef(
    key: 'piloto_automatico',
    title: 'Piloto automático',
    description: 'Configura un movimiento recurrente.',
    icon: Icons.autorenew_rounded,
    color: const Color(0xFF845EF7),
    xp: 30,
    test: (s) => s.recurrings >= 1,
  ),
  AchievementDef(
    key: 'precavido',
    title: 'Precavido',
    description: 'Haz tu primer respaldo de datos.',
    icon: Icons.cloud_done_rounded,
    color: const Color(0xFF4DABF7),
    xp: 40,
    test: (s) => s.backups >= 1,
  ),
  AchievementDef(
    key: 'nivel_5',
    title: 'Estratega',
    description: 'Llega al nivel 5.',
    icon: Icons.military_tech_rounded,
    color: const Color(0xFFFFC233),
    // Sin XP: evita que un logro de nivel suba más el nivel en cadena.
    xp: 0,
    test: (s) => s.level >= 5,
  ),
];

AchievementDef? achievementByKey(String key) {
  for (final a in achievementDefs) {
    if (a.key == key) return a;
  }
  return null;
}
