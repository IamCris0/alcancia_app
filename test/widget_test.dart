import 'package:alcancia_app/app.dart';
import 'package:alcancia_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const AlcanciaApp(),
  );
}

void main() {
  testWidgets('sin nombre guardado muestra el onboarding y luego el home', (
    tester,
  ) async {
    await tester.pumpWidget(await _app({}));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cris');
    await tester.pump();
    await tester.tap(find.text('Comenzar'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('¡Hola, Cris!'), findsOneWidget);
  });

  testWidgets('con nombre guardado salta el onboarding', (tester) async {
    await tester.pumpWidget(await _app({'user_name': 'Ana'}));
    await tester.pump();

    expect(find.textContaining('¡Hola, Ana!'), findsOneWidget);
  });
}
