import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/planning_queries.dart';
import '../../core/money.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../gamification/gamification_providers.dart';
import '../mascot/mascot_providers.dart';
import '../recurring/recurring_service.dart';

final goalsProvider = StreamProvider<List<GoalStatus>>(
  (ref) => ref.watch(databaseProvider).watchGoals(),
);

final debtsProvider = StreamProvider<List<DebtStatus>>(
  (ref) => ref.watch(databaseProvider).watchDebts(),
);

final recurringsProvider = StreamProvider<List<RecurringDetails>>(
  (ref) => ref.watch(databaseProvider).watchRecurrings(),
);

final recurringServiceProvider = Provider<RecurringService>(
  (ref) => RecurringService(ref.watch(databaseProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

const _kReminders = 'reminders_on';

/// Recordatorios activados por el usuario (apagados por defecto).
class RemindersNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_kReminders) ?? false;

  /// Al activar pide permiso; si se niega, queda apagado.
  Future<bool> set(bool on) async {
    final notifications = ref.read(notificationServiceProvider);
    if (on && !await notifications.requestPermission()) on = false;
    await ref.read(sharedPrefsProvider).setBool(_kReminders, on);
    state = on;
    if (!on) await notifications.cancelAll();
    return on;
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, bool>(
  RemindersNotifier.new,
);

/// Reprograma los avisos (racha + recurrentes) según los datos actuales.
Future<void> syncReminders(ProviderContainer c) async {
  if (!c.read(remindersProvider)) return;
  final notifications = c.read(notificationServiceProvider);
  final db = c.read(databaseProvider);
  final streak = await c.read(gamificationServiceProvider).streak();
  await notifications.scheduleStreakReminder(
    loggedToday: streak.loggedToday,
    streak: streak.current,
    petName: c.read(mascotProvider).name,
  );
  final currency = c.read(currencyProvider);
  await notifications.scheduleRecurring([
    for (final d in await db.watchRecurrings().first)
      if (d.recurring.active)
        (
          id: d.recurring.id,
          name: d.recurring.name,
          date: d.recurring.nextDate,
          amount: formatMoney(d.recurring.amount, currency),
        ),
  ]);
}
