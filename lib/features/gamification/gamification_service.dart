import '../../core/database/app_database.dart';
import '../../core/database/gamification_queries.dart';
import 'achievements.dart';
import 'levels.dart';
import 'streak.dart';

enum BudgetAlertLevel { warning, exceeded }

class BudgetAlert {
  const BudgetAlert({
    required this.level,
    required this.name,
    required this.remaining,
  });

  final BudgetAlertLevel level;

  /// Nombre de la categoría, o "general".
  final String name;
  final int remaining;
}

/// Lo que pasó al registrar algo: se muestra en la confirmación y en las
/// celebraciones posteriores.
class GamificationResult {
  const GamificationResult({
    this.xpGained = 0,
    this.levelBefore = 1,
    this.levelAfter = 1,
    this.unlocked = const [],
    this.alert,
    this.freezeUsed = false,
    this.streak = 0,
  });

  static const none = GamificationResult();

  final int xpGained;
  final int levelBefore;
  final int levelAfter;
  final List<AchievementDef> unlocked;
  final BudgetAlert? alert;
  final bool freezeUsed;
  final int streak;

  bool get leveledUp => levelAfter > levelBefore;
  bool get hasCelebrations => leveledUp || unlocked.isNotEmpty;
}

/// Reglas de XP, rachas, logros y alertas. Separado de la UI y con reloj
/// inyectable para poder probarlo.
class GamificationService {
  GamificationService(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  static const movementXp = 10;
  static const maxMovementXpPerDay = 5;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Future<StreakInfo> streak() async {
    final logs = await db.logTimes();
    final frozen = await db.watchFrozenDays().first;
    return computeStreak(
      loggedDays: logs.toSet(),
      frozenDays: frozen,
      today: _clock(),
    );
  }

  /// Llamar después de guardar un movimiento. [isNew] es falso al editar
  /// (no da XP, pero sí revisa presupuestos).
  Future<GamificationResult> onMovementSaved(
    Movement movement, {
    bool isNew = true,
    int previousAmount = 0,
  }) async {
    final alert = await _budgetAlert(movement, previousAmount);
    if (!isNew) return GamificationResult(alert: alert);

    final now = _clock();
    final today = dayOf(now);
    final levelBefore = LevelInfo.fromXp(await db.xpTotal()).level;
    var xp = 0;

    // 1. Congelar ayer si se rompió la racha por un solo día.
    final logs = await db.logTimes();
    final frozen = await db.watchFrozenDays().first;
    final before = computeStreak(
      loggedDays: logs.map(dayOf).where((d) => d != today).toSet(),
      frozenDays: frozen,
      today: now,
    );
    final freeze = dayToFreeze(
      activeDaysBeforeToday: before.activeDays,
      today: now,
      available: freezesAvailable(
        loggedDays: logs.map(dayOf).toSet().length,
        usedFreezes: frozen.length,
      ),
    );
    if (freeze != null) await db.freezeDay(freeze);

    // 2. XP por registrar (con tope diario).
    final todayCount = await db.countXpKeys('mov:', since: today);
    if (todayCount < maxMovementXpPerDay &&
        await db.awardXp('mov:${movement.id}', movementXp, at: now)) {
      xp += movementXp;
    }

    // 3. Bono diario según la racha.
    final s = await streak();
    final bonus = 5 + 5 * (s.current - 1).clamp(0, 9);
    if (await db.awardXp('day:${_ymd(today)}', bonus, at: now)) xp += bonus;

    // 4. Logros.
    final unlocked = await _evaluateAchievements(s);
    xp += unlocked.fold(0, (sum, a) => sum + a.xp);

    final levelAfter = LevelInfo.fromXp(await db.xpTotal()).level;
    final levelUnlocks = await _evaluateLevelAchievements(levelAfter);

    return GamificationResult(
      xpGained: xp,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      unlocked: [...unlocked, ...levelUnlocks],
      alert: alert,
      freezeUsed: freeze != null,
      streak: s.current,
    );
  }

  /// Al abrir la app: premia meses cerrados (presupuesto cumplido, mes en
  /// verde) y revisa logros pendientes.
  Future<GamificationResult> syncOnStart() async {
    final levelBefore = LevelInfo.fromXp(await db.xpTotal()).level;
    final current = DateTime(_clock().year, _clock().month);
    final general = await db.generalBudgetAmount();
    var xp = 0;
    for (final m in await db.monthTotals()) {
      if (!m.month.isBefore(current) || m.count == 0) continue;
      if (general != null &&
          m.expense <= general &&
          await db.awardXp('budgetmonth:${_ym(m.month)}', 100, at: _clock())) {
        xp += 100;
      }
      if (m.income > m.expense &&
          await db.awardXp('positivemonth:${_ym(m.month)}', 0, at: _clock())) {
        // Solo se registra para contar meses en verde; la XP llega con el logro.
      }
    }
    final unlocked = await _evaluateAchievements(await streak());
    xp += unlocked.fold(0, (sum, a) => sum + a.xp);
    final levelAfter = LevelInfo.fromXp(await db.xpTotal()).level;
    final levelUnlocks = await _evaluateLevelAchievements(levelAfter);
    return GamificationResult(
      xpGained: xp,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      unlocked: [...unlocked, ...levelUnlocks],
    );
  }

  /// Llamar al crear un presupuesto (puede desbloquear "Con un plan").
  Future<GamificationResult> onBudgetSaved() async {
    final levelBefore = LevelInfo.fromXp(await db.xpTotal()).level;
    final unlocked = await _evaluateAchievements(await streak());
    final levelAfter = LevelInfo.fromXp(await db.xpTotal()).level;
    return GamificationResult(
      xpGained: unlocked.fold(0, (sum, a) => sum + a.xp),
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      unlocked: unlocked,
    );
  }

  Future<GameStats> stats(StreakInfo s) async {
    final counts = await db.movementCounts();
    final logs = await db.logTimes();
    return GameStats(
      totalMovements: counts.total,
      hasIncome: counts.incomes > 0,
      hasTransfer: counts.transfers > 0,
      expenseCategoriesUsed: await db.expenseCategoriesUsed(),
      currentStreak: s.current,
      bestStreak: s.best,
      budgets: await db.countBudgets(),
      monthsUnderBudget: await db.countXpKeys('budgetmonth:'),
      positiveMonths: await db.countXpKeys('positivemonth:'),
      loggedLate: logs.any((t) => t.hour >= 23),
      loggedEarly: logs.any((t) => t.hour < 7),
      level: LevelInfo.fromXp(await db.xpTotal()).level,
    );
  }

  Future<List<AchievementDef>> _evaluateAchievements(StreakInfo s) async {
    final st = await stats(s);
    final unlocked = <AchievementDef>[];
    for (final a in achievementDefs) {
      if (a.key == 'nivel_5' || !a.test(st)) continue;
      if (await db.unlockAchievement(a.key)) {
        if (a.xp > 0) await db.awardXp('ach:${a.key}', a.xp, at: _clock());
        unlocked.add(a);
      }
    }
    return unlocked;
  }

  Future<List<AchievementDef>> _evaluateLevelAchievements(int level) async {
    final def = achievementByKey('nivel_5')!;
    if (def.test(GameStats(level: level)) &&
        await db.unlockAchievement(def.key)) {
      return [def];
    }
    return const [];
  }

  Future<BudgetAlert?> _budgetAlert(Movement m, int previousAmount) async {
    if (m.type != MovementType.expense) return null;
    final budgets = await db.watchBudgets(m.date).first;
    // Primero el de la categoría (más específico), luego el general.
    final relevant = [
      ...budgets.where((b) => b.categoryId == m.categoryId),
      ...budgets.where((b) => b.isGeneral),
    ];
    for (final b in relevant) {
      final after = b.spent;
      final before = after - m.amount + previousAmount;
      final name = b.categoryName ?? 'general';
      if (before < b.limit && after >= b.limit) {
        return BudgetAlert(
          level: BudgetAlertLevel.exceeded,
          name: name,
          remaining: b.remaining,
        );
      }
      if (before < b.limit * 0.8 && after >= b.limit * 0.8) {
        return BudgetAlert(
          level: BudgetAlertLevel.warning,
          name: name,
          remaining: b.remaining,
        );
      }
    }
    return null;
  }
}
