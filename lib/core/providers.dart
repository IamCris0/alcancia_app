import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/app_database.dart';

/// Se sobreescribe en `main()` con la instancia ya cargada.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider no inicializado'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(databaseProvider).watchAccounts(),
);

final categoriesProvider = StreamProvider.family<List<Category>, CategoryKind>(
  (ref, kind) => ref.watch(databaseProvider).watchCategories(kind),
);

const _kUserName = 'user_name';
const _kCurrency = 'currency';

/// Nombre del usuario (null = onboarding pendiente). Se guarda al final del
/// onboarding, así que su presencia indica que ya terminó.
class UserNameNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_kUserName);

  Future<void> set(String name) async {
    final clean = name.trim();
    await ref.read(sharedPrefsProvider).setString(_kUserName, clean);
    state = clean;
  }
}

final userNameProvider = NotifierProvider<UserNameNotifier, String?>(
  UserNameNotifier.new,
);

/// Código de la moneda principal (ISO 4217).
class CurrencyNotifier extends Notifier<String> {
  @override
  String build() =>
      ref.read(sharedPrefsProvider).getString(_kCurrency) ?? 'USD';

  Future<void> set(String code) async {
    await ref.read(sharedPrefsProvider).setString(_kCurrency, code);
    state = code;
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);
