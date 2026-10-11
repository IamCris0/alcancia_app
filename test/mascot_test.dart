import 'package:alcancia_app/core/providers.dart';
import 'package:alcancia_app/features/mascot/mascot_mood.dart';
import 'package:alcancia_app/features/mascot/mascot_providers.dart';
import 'package:alcancia_app/features/mascot/mascot_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('todas las especies y ánimos se dibujan y animan sin errores', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final s in MascotSpecies.values)
                for (final m in MascotMood.values)
                  MascotView(species: s, mood: m, size: 60),
            ],
          ),
        ),
      ),
    );
    // Recorre respiración, parpadeos y acciones al azar.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    // Tocar dispara salto + moneda.
    await tester.tap(find.byType(MascotView).first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('ánimo según ingresos y gastos', () {
    expect(moodFor(income: 0, expense: 0), MascotMood.sleeping);
    expect(moodFor(income: 100, expense: 50), MascotMood.happy);
    expect(moodFor(income: 100, expense: 150), MascotMood.worried);
    expect(moodFor(income: 0, expense: 10), MascotMood.neutral);
  });

  test('preferencias de mascota: valores por defecto y guardado', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(mascotProvider).species, MascotSpecies.pig);
    expect(container.read(mascotProvider).name, 'Chanchi');

    await container
        .read(mascotProvider.notifier)
        .set(MascotSpecies.panda, '  ');
    expect(container.read(mascotProvider).name, 'Bambú');
    expect(prefs.getString('mascot_species'), 'panda');
  });
}
