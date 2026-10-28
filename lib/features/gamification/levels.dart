import '../mascot/mascot_view.dart';

/// XP acumulada necesaria para llegar al nivel [level] (nivel 1 = 0 XP).
/// Crece cuadráticamente: 100, 300, 600, 1000, 1500…
int xpForLevel(int level) => 50 * level * (level - 1);

const levelTitles = [
  'Semillita',
  'Ahorrador novato',
  'Cazamonedas',
  'Guardián del bolsillo',
  'Estratega',
  'Maestro del presupuesto',
  'Leyenda de la plata',
];

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.levelStartXp,
    required this.nextLevelXp,
  });

  factory LevelInfo.fromXp(int xp) {
    var level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return LevelInfo(
      level: level,
      totalXp: xp,
      levelStartXp: xpForLevel(level),
      nextLevelXp: xpForLevel(level + 1),
    );
  }

  final int level;
  final int totalXp;
  final int levelStartXp;
  final int nextLevelXp;

  String get title => levelTitles[(level - 1).clamp(0, levelTitles.length - 1)];

  int get xpIntoLevel => totalXp - levelStartXp;
  int get xpNeeded => nextLevelXp - levelStartXp;

  /// Progreso dentro del nivel actual, de 0 a 1.
  double get progress => xpNeeded == 0 ? 0 : xpIntoLevel / xpNeeded;
}

/// Accesorios que la mascota desbloquea al subir de nivel.
const accessoryUnlockLevel = {
  MascotAccessory.bow: 2,
  MascotAccessory.glasses: 4,
  MascotAccessory.partyHat: 6,
  MascotAccessory.crown: 8,
};

String accessoryLabel(MascotAccessory a) => switch (a) {
  MascotAccessory.none => 'Sin accesorio',
  MascotAccessory.bow => 'Moño',
  MascotAccessory.glasses => 'Gafas',
  MascotAccessory.partyHat => 'Gorro de fiesta',
  MascotAccessory.crown => 'Corona',
};

bool isAccessoryUnlocked(MascotAccessory a, int level) =>
    a == MascotAccessory.none || level >= (accessoryUnlockLevel[a] ?? 99);

/// Accesorio que se desbloquea exactamente al llegar a [level], si hay.
MascotAccessory? accessoryUnlockedAt(int level) {
  for (final e in accessoryUnlockLevel.entries) {
    if (e.value == level) return e.key;
  }
  return null;
}
