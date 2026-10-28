import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'mascot_view.dart';

class MascotPrefs {
  const MascotPrefs(this.species, this.name);

  final MascotSpecies species;
  final String name;
}

const _kSpecies = 'mascot_species';
const _kName = 'mascot_name';

/// Especie y nombre de la mascota elegida en el onboarding.
class MascotNotifier extends Notifier<MascotPrefs> {
  @override
  MascotPrefs build() {
    final prefs = ref.read(sharedPrefsProvider);
    final species = MascotSpecies.values.firstWhere(
      (s) => s.name == prefs.getString(_kSpecies),
      orElse: () => MascotSpecies.pig,
    );
    return MascotPrefs(
      species,
      prefs.getString(_kName) ?? species.style.defaultName,
    );
  }

  Future<void> set(MascotSpecies species, String name) async {
    final clean = name.trim().isEmpty ? species.style.defaultName : name.trim();
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_kSpecies, species.name);
    await prefs.setString(_kName, clean);
    state = MascotPrefs(species, clean);
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
