import 'package:flutter/material.dart';

/// Animales clásicos + criaturas elementales originales (diseños propios de
/// PlataPets, no basados en franquicias existentes).
enum MascotSpecies { pig, cat, bunny, panda, spark, sprout, ember, aqua }

enum MascotMood { happy, neutral, worried, sleeping, celebrating }

/// Accesorios que se desbloquean subiendo de nivel.
enum MascotAccessory {
  none,
  bow,
  flower,
  glasses,
  scarf,
  partyHat,
  sunglasses,
  crown,
  wizardHat,
  halo,
}

/// Etapa evolutiva según el nivel: 1 (nv. 1–4), 2 (nv. 5–9), 3 (nv. 10+).
int stageForLevel(int level) => level >= 10 ? 3 : (level >= 5 ? 2 : 1);

class SpeciesStyle {
  const SpeciesStyle({
    required this.label,
    required this.defaultName,
    required this.bodyLight,
    required this.bodyDark,
    required this.limb,
    required this.limbDark,
    required this.earOuter,
    required this.earInner,
    required this.muzzle,
    required this.nose,
    required this.blush,
    this.element,
    this.stageNames = const [],
  });

  final String label;
  final String defaultName;
  final Color bodyLight;
  final Color bodyDark;
  final Color limb;
  final Color limbDark;
  final Color earOuter;
  final Color earInner;
  final Color muzzle;
  final Color nose;
  final Color blush;

  /// Tipo elemental (solo criaturas).
  final String? element;

  /// Nombre de la forma en cada etapa (solo criaturas).
  final List<String> stageNames;

  bool get isCreature => element != null;

  String formName(int stage) =>
      stageNames.isEmpty ? label : stageNames[(stage - 1).clamp(0, 2)];
}

extension MascotSpeciesStyle on MascotSpecies {
  SpeciesStyle get style => switch (this) {
    MascotSpecies.pig => const SpeciesStyle(
      label: 'Cerdito',
      defaultName: 'Chanchi',
      bodyLight: Color(0xFFFFC9D8),
      bodyDark: Color(0xFFFF8FAB),
      limb: Color(0xFFFFB3C7),
      limbDark: Color(0xFFFF8FAB),
      earOuter: Color(0xFFFF8FAB),
      earInner: Color(0xFFFFB3C7),
      muzzle: Color(0xFFFFA5BE),
      nose: Color(0xFFB84D6E),
      blush: Color(0xFFFF6B8B),
    ),
    MascotSpecies.cat => const SpeciesStyle(
      label: 'Gatito',
      defaultName: 'Michi',
      bodyLight: Color(0xFFFFE0B8),
      bodyDark: Color(0xFFFFA94D),
      limb: Color(0xFFFFC078),
      limbDark: Color(0xFFFFA94D),
      earOuter: Color(0xFFFFA94D),
      earInner: Color(0xFFFFC9D8),
      muzzle: Color(0xFFFFF4E6),
      nose: Color(0xFFFF8FAB),
      blush: Color(0xFFFF8787),
    ),
    MascotSpecies.bunny => const SpeciesStyle(
      label: 'Conejito',
      defaultName: 'Coco',
      bodyLight: Color(0xFFFFFFFF),
      bodyDark: Color(0xFFE5DBFF),
      limb: Color(0xFFF3F0FF),
      limbDark: Color(0xFFD0BFFF),
      earOuter: Color(0xFFEDE7FF),
      earInner: Color(0xFFFFC9DE),
      muzzle: Color(0xFFFFFFFF),
      nose: Color(0xFFFF8FAB),
      blush: Color(0xFFFFA8C5),
    ),
    MascotSpecies.panda => const SpeciesStyle(
      label: 'Panda',
      defaultName: 'Bambú',
      bodyLight: Color(0xFFFFFFFF),
      bodyDark: Color(0xFFDEE2E6),
      limb: Color(0xFF343A40),
      limbDark: Color(0xFF212529),
      earOuter: Color(0xFF343A40),
      earInner: Color(0xFF495057),
      muzzle: Color(0xFFFFFFFF),
      nose: Color(0xFF212529),
      blush: Color(0xFFFFA8A8),
    ),
    MascotSpecies.spark => const SpeciesStyle(
      label: 'Chispín',
      defaultName: 'Volti',
      bodyLight: Color(0xFFA5D8FF),
      bodyDark: Color(0xFF339AF0),
      limb: Color(0xFF74C0FC),
      limbDark: Color(0xFF1C7ED6),
      earOuter: Color(0xFF1C7ED6),
      earInner: Color(0xFFFFE066),
      muzzle: Color(0xFFE7F5FF),
      nose: Color(0xFF1864AB),
      blush: Color(0xFFFFD43B),
      element: 'Eléctrico',
      stageNames: ['Chispín', 'Voltio', 'Tormentix'],
    ),
    MascotSpecies.sprout => const SpeciesStyle(
      label: 'Brotín',
      defaultName: 'Hojita',
      bodyLight: Color(0xFFC3FAE8),
      bodyDark: Color(0xFF51CF66),
      limb: Color(0xFF8CE99A),
      limbDark: Color(0xFF40C057),
      earOuter: Color(0xFF40C057),
      earInner: Color(0xFFD8F5A2),
      muzzle: Color(0xFFEBFBEE),
      nose: Color(0xFF2B8A3E),
      blush: Color(0xFFFFA8A8),
      element: 'Planta',
      stageNames: ['Brotín', 'Floral', 'Arbolón'],
    ),
    MascotSpecies.ember => const SpeciesStyle(
      label: 'Brasita',
      defaultName: 'Chispa',
      bodyLight: Color(0xFFFFD8A8),
      bodyDark: Color(0xFFFF6B3D),
      limb: Color(0xFFFFA94D),
      limbDark: Color(0xFFE8590C),
      earOuter: Color(0xFFC92A2A),
      earInner: Color(0xFFFFD43B),
      muzzle: Color(0xFFFFF4E6),
      nose: Color(0xFFC92A2A),
      blush: Color(0xFFFFC078),
      element: 'Fuego',
      stageNames: ['Brasita', 'Flamo', 'Ignis'],
    ),
    MascotSpecies.aqua => const SpeciesStyle(
      label: 'Gotita',
      defaultName: 'Ola',
      bodyLight: Color(0xFFC5F6FA),
      bodyDark: Color(0xFF22B8CF),
      limb: Color(0xFF66D9E8),
      limbDark: Color(0xFF1098AD),
      earOuter: Color(0xFF15AABF),
      earInner: Color(0xFFE3FAFC),
      muzzle: Color(0xFFE3FAFC),
      nose: Color(0xFF0B7285),
      blush: Color(0xFFFFA8C5),
      element: 'Agua',
      stageNames: ['Gotita', 'Oleaje', 'Marejada'],
    ),
  };
}
