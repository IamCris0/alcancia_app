import 'package:flutter/material.dart';

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
  'Domador de gastos',
  'Maestro del presupuesto',
  'Mente financiera',
  'Héroe del ahorro',
  'Leyenda de la plata',
  'Arquitecto de metas',
  'Sabio del dinero',
  'Guardián dorado',
  'Titán del ahorro',
  'Visionario',
  'Maestro elemental',
  'Señor de las monedas',
  'Oráculo financiero',
  'Mito viviente',
  'Leyenda suprema',
];

/// Rango por tramos de nivel, con su color.
enum LevelTier { bronze, silver, gold, platinum, diamond }

LevelTier tierFor(int level) => switch (level) {
  < 5 => LevelTier.bronze,
  < 10 => LevelTier.silver,
  < 15 => LevelTier.gold,
  < 20 => LevelTier.platinum,
  _ => LevelTier.diamond,
};

extension LevelTierUi on LevelTier {
  String get label => switch (this) {
    LevelTier.bronze => 'Bronce',
    LevelTier.silver => 'Plata',
    LevelTier.gold => 'Oro',
    LevelTier.platinum => 'Platino',
    LevelTier.diamond => 'Diamante',
  };

  List<Color> get colors => switch (this) {
    LevelTier.bronze => const [Color(0xFFE0A370), Color(0xFFB0703C)],
    LevelTier.silver => const [Color(0xFFE9ECEF), Color(0xFFADB5BD)],
    LevelTier.gold => const [Color(0xFFFFE066), Color(0xFFF59F00)],
    LevelTier.platinum => const [Color(0xFFC5F6FA), Color(0xFF66D9E8)],
    LevelTier.diamond => const [Color(0xFFE5DBFF), Color(0xFF9775FA)],
  };
}

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
  MascotAccessory.flower: 3,
  MascotAccessory.glasses: 4,
  MascotAccessory.scarf: 6,
  MascotAccessory.partyHat: 7,
  MascotAccessory.sunglasses: 9,
  MascotAccessory.crown: 12,
  MascotAccessory.wizardHat: 15,
  MascotAccessory.halo: 20,
};

String accessoryLabel(MascotAccessory a) => switch (a) {
  MascotAccessory.none => 'Sin accesorio',
  MascotAccessory.bow => 'Moño',
  MascotAccessory.flower => 'Flor',
  MascotAccessory.glasses => 'Gafas',
  MascotAccessory.scarf => 'Bufanda',
  MascotAccessory.partyHat => 'Gorro de fiesta',
  MascotAccessory.sunglasses => 'Lentes de sol',
  MascotAccessory.crown => 'Corona',
  MascotAccessory.wizardHat => 'Sombrero de mago',
  MascotAccessory.halo => 'Aureola',
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
