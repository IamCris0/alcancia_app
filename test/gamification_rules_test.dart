import 'package:flutter_test/flutter_test.dart';
import 'package:platapets/features/gamification/levels.dart';
import 'package:platapets/features/gamification/streak.dart';
import 'package:platapets/features/mascot/mascot_view.dart';

void main() {
  final today = DateTime(2026, 10, 11, 15);
  DateTime d(int offset) => addDays(dayOf(today), offset);

  group('rachas', () {
    test('cuenta días seguidos hasta hoy', () {
      final s = computeStreak(
        loggedDays: {d(0), d(-1), d(-2), d(-5)},
        frozenDays: {},
        today: today,
      );
      expect(s.current, 3);
      expect(s.loggedToday, isTrue);
      expect(s.atRisk, isFalse);
    });

    test('si hoy no hay registro sigue viva pero en riesgo', () {
      final s = computeStreak(
        loggedDays: {d(-1), d(-2)},
        frozenDays: {},
        today: today,
      );
      expect(s.current, 2);
      expect(s.atRisk, isTrue);
    });

    test('se rompe si falta ayer y hoy', () {
      final s = computeStreak(
        loggedDays: {d(-2), d(-3)},
        frozenDays: {},
        today: today,
      );
      expect(s.current, 0);
      expect(s.best, 2);
    });

    test('los días congelados cuentan', () {
      final s = computeStreak(
        loggedDays: {d(0), d(-2)},
        frozenDays: {d(-1)},
        today: today,
      );
      expect(s.current, 3);
    });

    test('un congelador por cada 7 días registrados, máximo 2', () {
      expect(freezesAvailable(loggedDays: 6, usedFreezes: 0), 0);
      expect(freezesAvailable(loggedDays: 14, usedFreezes: 1), 1);
      expect(freezesAvailable(loggedDays: 70, usedFreezes: 0), maxFreezes);
    });

    test('congela solo un hueco de un día', () {
      expect(
        dayToFreeze(
          activeDaysBeforeToday: {d(-2), d(-3)},
          today: today,
          available: 1,
        ),
        d(-1),
      );
      expect(
        dayToFreeze(activeDaysBeforeToday: {d(-3)}, today: today, available: 1),
        isNull,
      );
      expect(
        dayToFreeze(activeDaysBeforeToday: {d(-2)}, today: today, available: 0),
        isNull,
      );
    });
  });

  group('niveles', () {
    test('umbrales de XP', () {
      expect(LevelInfo.fromXp(0).level, 1);
      expect(LevelInfo.fromXp(99).level, 1);
      expect(LevelInfo.fromXp(100).level, 2);
      expect(LevelInfo.fromXp(300).level, 3);
      expect(LevelInfo.fromXp(1000).level, 5);
    });

    test('progreso dentro del nivel', () {
      final l = LevelInfo.fromXp(200);
      expect(l.level, 2);
      expect(l.xpIntoLevel, 100);
      expect(l.xpNeeded, 200);
      expect(l.progress, 0.5);
    });

    test('accesorios por nivel', () {
      expect(isAccessoryUnlocked(MascotAccessory.bow, 1), isFalse);
      expect(isAccessoryUnlocked(MascotAccessory.bow, 2), isTrue);
      expect(isAccessoryUnlocked(MascotAccessory.crown, 11), isFalse);
      expect(accessoryUnlockedAt(4), MascotAccessory.glasses);
      expect(accessoryUnlockedAt(3), MascotAccessory.flower);
      expect(accessoryUnlockedAt(5), isNull);
      expect(isAccessoryUnlocked(MascotAccessory.halo, 19), isFalse);
    });
  });

  test('rangos y etapas por nivel', () {
    expect(tierFor(1), LevelTier.bronze);
    expect(tierFor(5), LevelTier.silver);
    expect(tierFor(12), LevelTier.gold);
    expect(tierFor(20), LevelTier.diamond);
    expect(stageForLevel(4), 1);
    expect(stageForLevel(5), 2);
    expect(stageForLevel(10), 3);
    expect(levelTitles, hasLength(20));
    expect(MascotSpecies.spark.style.formName(3), 'Tormentix');
    expect(MascotSpecies.pig.style.isCreature, isFalse);
  });
}
