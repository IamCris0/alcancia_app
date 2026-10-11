import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'mascot_view.dart';

class MascotPrefs {
  const MascotPrefs(this.species, this.name, this.accessory);

  final MascotSpecies species;
  final String name;
  final MascotAccessory accessory;
}

const _kSpecies = 'mascot_species';
const _kName = 'mascot_name';
const _kAccessory = 'mascot_accessory';

/// Especie, nombre y accesorio puesto de la mascota.
class MascotNotifier extends Notifier<MascotPrefs> {
  @override
  MascotPrefs build() {
    final prefs = ref.read(sharedPrefsProvider);
    final species = MascotSpecies.values.firstWhere(
      (s) => s.name == prefs.getString(_kSpecies),
      orElse: () => MascotSpecies.pig,
    );
    final accessory = MascotAccessory.values.firstWhere(
      (a) => a.name == prefs.getString(_kAccessory),
      orElse: () => MascotAccessory.none,
    );
    return MascotPrefs(
      species,
      prefs.getString(_kName) ?? species.style.defaultName,
      accessory,
    );
  }

  Future<void> set(MascotSpecies species, String name) async {
    final clean = name.trim().isEmpty ? species.style.defaultName : name.trim();
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_kSpecies, species.name);
    await prefs.setString(_kName, clean);
    state = MascotPrefs(species, clean, state.accessory);
  }

  Future<void> wear(MascotAccessory accessory) async {
    await ref.read(sharedPrefsProvider).setString(_kAccessory, accessory.name);
    state = MascotPrefs(state.species, state.name, accessory);
  }
}

final mascotProvider = NotifierProvider<MascotNotifier, MascotPrefs>(
  MascotNotifier.new,
);

/// Sube cada vez que el usuario registra algo; las mascotas visibles lo
/// escuchan (vía `reactKey`) y saltan.
class MascotEventNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final mascotEventProvider = NotifierProvider<MascotEventNotifier, int>(
  MascotEventNotifier.new,
);

/// La mascota del usuario: toma especie y accesorio de las preferencias.
class MyMascot extends ConsumerWidget {
  const MyMascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.interactive = true,
    this.reactToEvents = false,
  });

  final MascotMood mood;
  final double size;
  final bool interactive;

  /// Si salta cada vez que se registra algo.
  final bool reactToEvents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascot = ref.watch(mascotProvider);
    return MascotView(
      species: mascot.species,
      accessory: mascot.accessory,
      mood: mood,
      size: size,
      interactive: interactive,
      reactKey: reactToEvents ? ref.watch(mascotEventProvider) : 0,
    );
  }
}
