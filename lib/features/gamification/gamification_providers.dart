import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/gamification_queries.dart';
import '../../core/providers.dart';
import 'gamification_service.dart';
import 'levels.dart';
import 'streak.dart';

final gamificationServiceProvider = Provider<GamificationService>(
  (ref) => GamificationService(ref.watch(databaseProvider)),
);

final xpProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).watchXpTotal(),
);

final levelProvider = Provider<LevelInfo>(
  (ref) => LevelInfo.fromXp(ref.watch(xpProvider).value ?? 0),
);

final _logTimesProvider = StreamProvider<List<DateTime>>(
  (ref) => ref.watch(databaseProvider).watchLogTimes(),
);

final _frozenDaysProvider = StreamProvider<Set<DateTime>>(
  (ref) => ref.watch(databaseProvider).watchFrozenDays(),
);

final streakProvider = Provider<StreakInfo>((ref) {
  final logs = ref.watch(_logTimesProvider).value;
  final frozen = ref.watch(_frozenDaysProvider).value;
  if (logs == null || frozen == null) return StreakInfo.empty;
  return computeStreak(
    loggedDays: logs.toSet(),
    frozenDays: frozen,
    today: DateTime.now(),
  );
});

final unlockedAchievementsProvider = StreamProvider<Map<String, DateTime>>(
  (ref) => ref.watch(databaseProvider).watchUnlocked(),
);

final budgetsProvider = StreamProvider.autoDispose
    .family<List<BudgetStatus>, DateTime>(
      (ref, month) => ref.watch(databaseProvider).watchBudgets(month),
    );
