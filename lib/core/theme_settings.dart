import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';

class ThemeSettings {
  const ThemeSettings(this.palette, this.mode);

  final AppPalette palette;
  final ThemeMode mode;
}

const _kPalette = 'theme_palette';
const _kMode = 'theme_mode';

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    return ThemeSettings(
      AppPalette.values.firstWhere(
        (p) => p.name == prefs.getString(_kPalette),
        orElse: () => AppPalette.violeta,
      ),
      ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kMode),
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> setPalette(AppPalette p) async {
    await ref.read(sharedPrefsProvider).setString(_kPalette, p.name);
    state = ThemeSettings(p, state.mode);
  }

  Future<void> setMode(ThemeMode m) async {
    await ref.read(sharedPrefsProvider).setString(_kMode, m.name);
    state = ThemeSettings(state.palette, m);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );

/// Marca todo el árbol para reconstruir (sin perder estado): necesario
/// porque los colores de marca se leen de [AppColors] al construir.
void rebuildAllChildren(BuildContext context) {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
