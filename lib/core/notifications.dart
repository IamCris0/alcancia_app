import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorios locales (sin servidor). Todo se programa en el teléfono;
/// cualquier fallo de la plataforma se ignora para no romper la app.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _streakId = 1;
  static const _recurringBase = 1000;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Pagos recurrentes y racha diaria',
      icon: 'ic_stat_coin',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> _init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_coin'),
      ),
    );
    _ready = true;
  }

  /// Pide permiso (Android 13+). Devuelve si quedó concedido.
  Future<bool> requestPermission() async {
    try {
      await _init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (e) {
      debugPrint('Notificaciones no disponibles: $e');
      return false;
    }
  }

  /// Recordatorio de racha a las 20:00 si hoy aún no se registró nada (o
  /// mañana si ya se registró o ya pasó la hora).
  Future<void> scheduleStreakReminder({
    required bool loggedToday,
    required int streak,
    required String petName,
  }) => _safe(() async {
    await _plugin.cancel(id: _streakId);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (loggedToday || !at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _streakId,
      title: streak > 0
          ? '🔥 ¡No pierdas tu racha de $streak días!'
          : '🐷 $petName te espera',
      body: 'Registra un movimiento hoy para mantener tu racha.',
      scheduledDate: at,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });

  /// Un aviso a las 9:00 del día de cada recurrente activo.
  Future<void> scheduleRecurring(
    List<({int id, String name, DateTime date, String amount})> items,
  ) => _safe(() async {
    final now = tz.TZDateTime.now(tz.local);
    for (final i in items) {
      await _plugin.cancel(id: _recurringBase + i.id);
      final at = tz.TZDateTime(
        tz.local,
        i.date.year,
        i.date.month,
        i.date.day,
        9,
      );
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: _recurringBase + i.id,
        title: 'Hoy toca: ${i.name}',
        body: '${i.amount} · Ábrela para registrarlo.',
        scheduledDate: at,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  });

  Future<void> cancelAll() => _safe(_plugin.cancelAll);

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await _init();
      if (_ready) await action();
    } catch (e) {
      debugPrint('No se pudo programar el recordatorio: $e');
    }
  }
}
