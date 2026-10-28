import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/gamification_queries.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/month_switcher.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import '../reports/report_service.dart';
import '../security/app_lock.dart';
import '../security/lock_screen.dart';
import 'backup_service.dart';

const _kLastBackup = 'last_backup';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    ref.watch(sharedPrefsProvider),
  ),
);

class DataPage extends ConsumerStatefulWidget {
  const DataPage({super.key});

  @override
  ConsumerState<DataPage> createState() => _DataPageState();
}

class _DataPageState extends ConsumerState<DataPage> {
  bool _busy = false;

  String get _stamp => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Algo salió mal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<File> _temp(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$name')..writeAsBytesSync(bytes);
  }

  Future<void> _share(String name, List<int> bytes, String mime) async {
    final file = await _temp(name, bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: name,
      ),
    );
  }

  /// Marca el respaldo (fecha + logro "Precavido").
  Future<void> _afterBackup() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_kLastBackup, DateTime.now().toIso8601String());
    await ref.read(databaseProvider).awardXp('backup:$_stamp', 0);
    final r = await ref.read(gamificationServiceProvider).evaluate();
    if (mounted) setState(() {});
    if (r.hasCelebrations && mounted) await showCelebrations(context, r);
  }

  Future<void> _exportShare() => _run(() async {
    final json = await ref.read(backupServiceProvider).exportJson();
    await _share(
      'platapets-respaldo-$_stamp.json',
      utf8.encode(json),
      'application/json',
    );
    await _afterBackup();
  });

  Future<void> _exportSave() => _run(() async {
    final json = await ref.read(backupServiceProvider).exportJson();
    final uri = await FilePicker.saveFile(
      fileName: 'platapets-respaldo-$_stamp.json',
      bytes: Uint8List.fromList(utf8.encode(json)),
      mimeType: 'application/json',
      dialogTitle: 'Guardar respaldo',
    );
    if (uri == null) return;
    _toast('Respaldo guardado');
    await _afterBackup();
  });

  Future<void> _restore() => _run(() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Elige tu respaldo',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;
    final raw = utf8.decode(await file.readAsBytes());
    final service = ref.read(backupServiceProvider);
    final summary = service.inspect(raw);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restaurar este respaldo?'),
        content: Text(
          '${summary.exportedAt == null ? '' : 'Del ${DateFormat("d 'de' MMMM yyyy, HH:mm", 'es').format(summary.exportedAt!)}.\n'}'
          '${summary.accounts} cuentas · ${summary.movements} movimientos · '
          '${summary.goals} metas.\n\n'
          'Reemplazará TODOS los datos actuales de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.restore(raw);
    // Las preferencias restauradas se releen.
    ref.invalidate(userNameProvider);
    ref.invalidate(currencyProvider);
    ref.invalidate(mascotProvider);
    _toast('Respaldo restaurado ✓');
  });

  Future<void> _csv() => _run(() async {
    final csv = await movementsCsv(ref.read(databaseProvider));
    // BOM para que Excel reconozca los acentos.
    await _share('platapets-movimientos-$_stamp.csv', [
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(csv),
    ], 'text/csv');
  });

  Future<void> _pdf() => _run(() async {
    final month = ref.read(selectedMonthProvider);
    final bytes = await buildMonthReport(
      db: ref.read(databaseProvider),
      month: month,
      currency: ref.read(currencyProvider),
      userName: ref.read(userNameProvider) ?? '',
    );
    await _share(
      'platapets-reporte-${DateFormat('yyyy-MM').format(month)}.pdf',
      bytes,
      'application/pdf',
    );
  });

  Future<String?> _askPin(String title, {String? subtitle}) {
    String? result;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        child: PinPad(
          title: title,
          subtitle: subtitle,
          onComplete: (pin) async {
            result = pin;
            Navigator.pop(context, result);
            return true;
          },
        ),
      ),
    );
  }

  Future<void> _togglePin(bool on) async {
    final lock = ref.read(lockSettingsProvider.notifier);
    if (!on) {
      final pin = await _askPin('Ingresa tu PIN actual');
      if (pin == null) return;
      if (!await lock.verify(pin)) return _toast('PIN incorrecto');
      await lock.removePin();
      return _toast('Bloqueo desactivado');
    }
    final first = await _askPin(
      'Crea un PIN de $pinLength dígitos',
      subtitle:
          'Si lo olvidas no podrás entrar: activa la huella como respaldo.',
    );
    if (first == null || !mounted) return;
    final second = await _askPin('Repite tu PIN');
    if (second == null) return;
    if (first != second) return _toast('Los PIN no coinciden');
    await lock.setPin(first);
    _toast('Bloqueo activado 🔒');
  }

  Future<void> _toggleBiometric(bool on) async {
    if (on && !await ref.read(biometricsProvider).available()) {
      return _toast('Este teléfono no tiene huella o rostro configurados');
    }
    if (on && !await ref.read(biometricsProvider).authenticate()) return;
    await ref.read(lockSettingsProvider.notifier).setBiometric(on);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lock = ref.watch(lockSettingsProvider);
    final last = DateTime.tryParse(
      ref.watch(sharedPrefsProvider).getString(_kLastBackup) ?? '',
    );
    final stale = last == null || DateTime.now().difference(last).inDays > 30;

    Widget action(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      enabled: !_busy,
      onTap: onTap,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        'Datos y seguridad',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  gradient: stale ? AppColors.heroGradient : null,
                  child: Row(
                    children: [
                      MyMascot(
                        mood: stale ? MascotMood.worried : MascotMood.happy,
                        size: 72,
                        interactive: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          last == null
                              ? 'Aún no tienes respaldo. Todo vive solo en este '
                                    'teléfono: guárdalo en Drive o tu correo.'
                              : 'Último respaldo: '
                                    '${DateFormat("d 'de' MMMM yyyy", 'es').format(last)}'
                                    '${stale ? '. ¡Ya toca otro!' : ' ✓'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: stale ? Colors.white : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.06),
                _Section('Respaldo'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      action(
                        Icons.ios_share_rounded,
                        'Compartir respaldo',
                        'Envíalo a Drive, correo o WhatsApp',
                        _exportShare,
                      ),
                      action(
                        Icons.save_alt_rounded,
                        'Guardar en el teléfono',
                        'Elige una carpeta',
                        _exportSave,
                      ),
                      action(
                        Icons.settings_backup_restore_rounded,
                        'Restaurar respaldo',
                        'Reemplaza los datos actuales',
                        _restore,
                      ),
                    ],
                  ),
                ),
                _Section('Exportar'),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                  child: Column(
                    children: [
                      action(
                        Icons.table_chart_rounded,
                        'Movimientos en CSV',
                        'Para Excel o Google Sheets',
                        _csv,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: MonthSwitcher(),
                      ),
                      action(
                        Icons.picture_as_pdf_rounded,
                        'Reporte PDF del mes',
                        'Resumen, categorías, presupuestos y movimientos',
                        _pdf,
                      ),
                    ],
                  ),
                ),
                _Section('Seguridad'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.lock_rounded),
                        title: const Text('Bloqueo con PIN'),
                        subtitle: const Text(
                          'Al abrir y al volver tras 30 s fuera',
                        ),
                        value: lock.hasPin,
                        onChanged: _busy ? null : _togglePin,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: const Text('Desbloquear con huella o rostro'),
                        value: lock.biometric,
                        onChanged: !lock.hasPin || _busy
                            ? null
                            : _toggleBiometric,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_busy)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
