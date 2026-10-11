import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Se sobreescribe en `main()` con la instancia ya cargada.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider no inicializado'),
);

const _kUserName = 'user_name';

/// Nombre del usuario (null = onboarding pendiente).
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
