import 'package:alcancia_app/app.dart';
import 'package:alcancia_app/core/database/app_database.dart';
import 'package:alcancia_app/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La base de datos usa I/O real, que no avanza dentro del reloj falso de
/// `testWidgets`; por eso se deja correr con `runAsync` entre frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<AppDatabase> _launch(
  WidgetTester tester,
  Map<String, Object> initial,
) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const AlcanciaApp(),
    ),
  );
  await _settle(tester);
  return db;
}

Future<void> _shutdown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
  await tester.runAsync(db.close);
}

void main() {
  testWidgets('onboarding: nombre, primera cuenta y llegada al home', (
    tester,
  ) async {
    final db = await _launch(tester, {});

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cris');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await _settle(tester);

    expect(find.text('Nombre de la cuenta'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await _settle(tester);

    expect(find.textContaining('¡Hola, Cris!'), findsOneWidget);
    // Aparece como nombre de la cuenta y como su tipo.
    expect(find.text('Efectivo'), findsNWidgets(2));

    await _shutdown(tester, db);
  });

  testWidgets('con nombre guardado salta el onboarding', (tester) async {
    final db = await _launch(tester, {'user_name': 'Ana'});

    expect(find.textContaining('¡Hola, Ana!'), findsOneWidget);

    await _shutdown(tester, db);
  });
}
