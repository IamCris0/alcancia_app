import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platapets/core/database/app_database.dart';
import 'package:platapets/core/database/gamification_queries.dart';
import 'package:platapets/core/database/planning_queries.dart';
import 'package:platapets/features/gamification/gamification_service.dart';
import 'package:platapets/features/recurring/recurrence.dart';
import 'package:platapets/features/recurring/recurring_service.dart';

void main() {
  group('fechas de recurrencia', () {
    test('mensual ancla el día y respeta fin de mes', () {
      final start = DateTime(2026, 1, 31);
      expect(occurrence(start, Frequency.monthly, 1), DateTime(2026, 2, 28));
      expect(occurrence(start, Frequency.monthly, 2), DateTime(2026, 3, 31));
      expect(occurrence(start, Frequency.monthly, 12), DateTime(2027, 1, 31));
    });

    test('semanal y anual (29 de febrero)', () {
      expect(
        occurrence(DateTime(2026, 10, 1), Frequency.weekly, 2),
        DateTime(2026, 10, 15),
      );
      expect(
        occurrence(DateTime(2028, 2, 29), Frequency.yearly, 1),
        DateTime(2029, 2, 28),
      );
    });

    test('siguiente y vencidas', () {
      final start = DateTime(2026, 8, 5);
      expect(
        nextAfter(start, Frequency.monthly, DateTime(2026, 10, 5)),
        DateTime(2026, 11, 5),
      );
      expect(
        dueOccurrences(
          start,
          Frequency.monthly,
          DateTime(2026, 8, 5),
          DateTime(2026, 10, 27),
        ),
        [DateTime(2026, 8, 5), DateTime(2026, 9, 5), DateTime(2026, 10, 5)],
      );
    });
  });

  group('con base de datos', () {
    late AppDatabase db;
    late int account;
    late int food;
    final now = DateTime(2026, 10, 27, 10);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      account = await db.addAccount(
        AccountsCompanion.insert(
          name: 'Banco',
          type: AccountType.bank,
          colorValue: 0,
          iconKey: 'bank',
          initialBalance: const Value(100000),
        ),
      );
      food = (await db.watchCategories(CategoryKind.expense).first).first.id;
    });
    tearDown(() => db.close());

    Future<int> recurring({required bool auto, required DateTime start}) =>
        db.saveRecurring(
          RecurringsCompanion.insert(
            name: 'Netflix',
            type: MovementType.expense,
            amount: 1500,
            accountId: account,
            categoryId: Value(food),
            frequency: Frequency.monthly,
            startDate: start,
            nextDate: start,
            autoRegister: Value(auto),
          ),
        );

    test(
      'automático: registra las vencidas y no cuenta para la racha',
      () async {
        await recurring(auto: true, start: DateTime(2026, 8, 20));
        final service = RecurringService(db, clock: () => now);

        expect(await service.processDue(), 3); // ago, sep, oct
        expect(await service.processDue(), 0); // no duplica
        final movements = await db.watchMovements(const MovementFilter()).first;
        expect(movements, hasLength(3));
        expect(movements.every((m) => m.movement.isAuto), isTrue);
        expect(await db.logTimes(), isEmpty);
        final r = (await db.watchRecurrings().first).single.recurring;
        expect(r.nextDate, DateTime(2026, 11, 20));
        final balance = (await db.watchAccountsWithBalance().first).single;
        expect(balance.balance, 100000 - 4500);
      },
    );

    test('manual: queda pendiente, se confirma u omite', () async {
      await recurring(auto: false, start: DateTime(2026, 10, 20));
      final service = RecurringService(db, clock: () => now);
      expect(await service.processDue(), 0);

      var r = (await db.watchRecurrings().first).single.recurring;
      expect(service.isDue(r), isTrue);
      final m = await service.confirm(r);
      expect(m.isAuto, isFalse);
      expect(m.note, 'Netflix');

      r = (await db.watchRecurrings().first).single.recurring;
      expect(r.nextDate, DateTime(2026, 11, 20));
      expect(service.isDue(r), isFalse);
      await service.skip(r);
      r = (await db.watchRecurrings().first).single.recurring;
      expect(r.nextDate, DateTime(2026, 12, 20));
    });

    test('meta: aportes, retiro, cumplimiento y logros', () async {
      final goal = await db.saveGoal(
        GoalsCompanion.insert(
          name: 'Viaje',
          target: 10000,
          iconKey: 'travel',
          colorValue: 0,
        ),
      );
      final game = GamificationService(db, clock: () => now);
      expect(
        (await game.evaluate()).unlocked.map((a) => a.key),
        contains('primera_meta'),
      );

      expect(await db.contribute(goal, 6000, now), isFalse);
      expect(await db.contribute(goal, -1000, now), isFalse);
      expect(await db.contribute(goal, 5000, now), isTrue);
      expect(await db.contribute(goal, 100, now), isFalse); // solo una vez

      final status = await db.goalStatus(goal);
      expect(status.saved, 10100);
      expect(status.completed, isTrue);

      final r = await game.onContribution(
        goalId: goal,
        amount: 5000,
        completedGoalName: 'Viaje',
      );
      expect(r.milestone, contains('Viaje'));
      expect(r.unlocked.map((a) => a.key), contains('meta_cumplida'));
    });

    test('XP por aportar tiene tope diario', () async {
      final goal = await db.saveGoal(
        GoalsCompanion.insert(
          name: 'Fondo',
          target: 1000000,
          iconKey: 'savings',
          colorValue: 0,
        ),
      );
      var t = now;
      final game = GamificationService(db, clock: () => t);
      for (var i = 0; i < 5; i++) {
        t = t.add(const Duration(minutes: 1));
        await game.onContribution(goalId: goal, amount: 100);
      }
      expect(
        await db.countXpKeys('goal:'),
        GamificationService.maxGoalXpPerDay,
      );
    });

    test('deuda: abonos hasta saldarla', () async {
      final debt = await db.saveDebt(
        DebtsCompanion.insert(
          person: 'Ana',
          kind: DebtKind.theyOwe,
          amount: 3000,
        ),
      );
      expect(await db.payDebt(debt, 1000, now), isFalse);
      expect(await db.payDebt(debt, 2000, now), isTrue);
      final status = (await db.watchDebts().first).single;
      expect(status.remaining, 0);
      expect(status.settled, isTrue);
      final r = await GamificationService(db, clock: () => now).evaluate();
      expect(r.unlocked.map((a) => a.key), contains('deuda_saldada'));
    });
  });
}
