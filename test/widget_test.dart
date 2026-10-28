import 'package:alcancia_app/app.dart';
import 'package:alcancia_app/core/database/app_database.dart';
import 'package:alcancia_app/core/providers.dart';
import 'package:alcancia_app/features/movements/keypad.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La base de datos usa I/O real, que no avanza dentro del reloj falso de
/// `testWidgets`; por eso se deja correr con `runAsync` entre frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
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
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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

Finder _key(String k) =>
    find.descendant(of: find.byType(Keypad), matching: find.text(k));

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('onboarding: nombre, primera cuenta y llegada al inicio', (
    tester,
  ) async {
    final db = await _launch(tester, {});

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cris');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await _settle(tester);

    expect(find.text('Nombre de la cuenta'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.tap(find.text('Empezar'));
    await _settle(tester);

    expect(find.textContaining('Cris'), findsOneWidget);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);

    await _shutdown(tester, db);
  });

  testWidgets('registrar un gasto actualiza el saldo', (tester) async {
    final db = await _launch(tester, {'user_name': 'Ana'});
    await tester.runAsync(
      () => db.addAccount(
        AccountsCompanion.insert(
          name: 'Efectivo',
          type: AccountType.cash,
          colorValue: 0xFF12B886,
          iconKey: 'wallet',
          initialBalance: const Value(5000),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text(r'$50.00'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Nuevo movimiento'));
    await _settle(tester);
    expect(find.text('Nuevo movimiento'), findsOneWidget);

    await tester.tap(_key('1'));
    await tester.tap(_key('2'));
    await tester.pump();
    expect(find.text(r'$12'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    // Confirmación (~1 s) + cierre de la pantalla + conteo del saldo.
    await _settle(tester);
    await _settle(tester);

    expect(find.text('Nuevo movimiento'), findsNothing);
    expect(find.text(r'$38.00'), findsOneWidget);
    // "Recientes" está al final del inicio: hay que desplazarse.
    await tester.scrollUntilVisible(
      find.text(r'−$12.00'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(r'−$12.00'), findsOneWidget);

    await _shutdown(tester, db);
  });

  testWidgets('guardar sin monto muestra un error', (tester) async {
    final db = await _launch(tester, {'user_name': 'Ana'});
    await tester.tap(find.bySemanticsLabel('Nuevo movimiento'));
    await _settle(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Escribe un monto'), findsOneWidget);

    await _shutdown(tester, db);
  });
}
