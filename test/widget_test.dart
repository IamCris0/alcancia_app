import 'package:platapets/app.dart';
import 'package:platapets/core/database/app_database.dart';
import 'package:platapets/core/providers.dart';
import 'package:platapets/features/movements/keypad.dart';
import 'package:platapets/features/splash/splash_page.dart';
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

/// Avanza en pasos cortos (I/O real + reloj falso) hasta que aparezca
/// [finder], con un tope para no colgar el test.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<(AppDatabase, SharedPreferences)> _launch(
  WidgetTester tester,
  Map<String, Object> initial, {
  bool splash = false,
}) async {
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
        showSplashProvider.overrideWithValue(splash),
      ],
      child: const PlataPetsApp(),
    ),
  );
  if (!splash) await _settle(tester);
  return (db, prefs);
}

Future<void> _shutdown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  // flutter_animate programa sus retrasos con timers no cancelables:
  // se deja correr el reloj para que terminen.
  await tester.pump(const Duration(seconds: 1));
  // Deja terminar consultas que quedaron en curso (arranque de la app).
  await _settle(tester);
  await tester.runAsync(db.close);
}

Finder _key(String k) =>
    find.descendant(of: find.byType(Keypad), matching: find.text(k));

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('la intro animada da paso al onboarding', (tester) async {
    final (db, _) = await _launch(tester, {}, splash: true);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Tu dinero, con compañía'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    expect(find.text('Tu dinero, con compañía'), findsNothing);

    await _shutdown(tester, db);
  });

  testWidgets('onboarding: nombre, mascota, primera cuenta y llegada', (
    tester,
  ) async {
    final (db, prefs) = await _launch(tester, {});

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cris');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await _settle(tester);

    // Carrusel de mascotas: deslizar elige al gatito y sugiere su nombre.
    expect(find.text('Elige tu compañero'), findsOneWidget);
    expect(find.text('Chanchi'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await _settle(tester);
    expect(find.text('Michi'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await _settle(tester);

    expect(find.text('Nombre de la cuenta'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.tap(find.text('Empezar'));
    await _settle(tester);
    expect(find.text('¡Todo listo, Cris!'), findsOneWidget);
    await _settle(tester);

    expect(find.textContaining('Cris'), findsOneWidget);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.bySemanticsLabel(r'$100.00'), findsOneWidget);
    expect(prefs.getString('mascot_species'), 'cat');
    expect(prefs.getString('mascot_name'), 'Michi');

    await _shutdown(tester, db);
  });

  testWidgets('registrar un gasto actualiza el saldo', (tester) async {
    final (db, _) = await _launch(tester, {'user_name': 'Ana'});
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
    expect(find.bySemanticsLabel(r'$50.00'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Nuevo movimiento'));
    await _settle(tester);
    expect(find.text('Nuevo movimiento'), findsOneWidget);

    await tester.tap(_key('1'));
    await tester.tap(_key('2'));
    await tester.pump();
    expect(find.text(r'$12'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    // Guardar + XP/logros encadenan muchas consultas con I/O real.
    await _pumpUntil(tester, find.text('Gasto registrado'));
    expect(find.text('Gasto registrado'), findsOneWidget);
    // La XP exacta depende de la hora (logros "Búho"/"Madrugador").
    expect(find.textContaining(' XP'), findsWidgets);
    // Confirmación + cierre de la pantalla + animación del saldo.
    await _settle(tester);
    await _settle(tester);

    // Primer movimiento: se desbloquea el logro "Primer paso".
    expect(find.text('LOGRO DESBLOQUEADO'), findsOneWidget);
    expect(find.text('Primer paso'), findsOneWidget);
    // Puede haber más de una celebración seguida: se cierran todas.
    for (var i = 0; i < 5 && find.text('¡Genial!').evaluate().isNotEmpty; i++) {
      await tester.tap(find.text('¡Genial!'));
      await _settle(tester);
    }

    expect(find.text('Nuevo movimiento'), findsNothing);
    expect(find.bySemanticsLabel(r'$38.00'), findsOneWidget);
    // Racha de 1 día y XP ganada.
    expect(find.text('1 día'), findsOneWidget);
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
    final (db, _) = await _launch(tester, {'user_name': 'Ana'});
    await tester.tap(find.bySemanticsLabel('Nuevo movimiento'));
    await _settle(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Escribe un monto'), findsOneWidget);

    await _shutdown(tester, db);
  });

  testWidgets('cambiar de pestaña muestra cada sección', (tester) async {
    final (db, _) = await _launch(tester, {'user_name': 'Ana'});
    for (final (label, title) in [
      ('Movimientos', 'Movimientos'),
      ('Metas', 'Ahorros'),
      ('Perfil', 'Logros'),
    ]) {
      await tester.tap(find.bySemanticsLabel(label).first);
      await _settle(tester);
      expect(find.text(title), findsWidgets);
    }
    await _shutdown(tester, db);
  });
}
