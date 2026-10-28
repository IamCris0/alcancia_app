import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/aurora.dart';
import '../../core/theme.dart';
import '../../core/ui/pressable.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import 'app_lock.dart';

const pinLength = 4;

/// Pantalla de PIN reutilizable: desbloquear, o crear/confirmar un PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.subtitle,
    this.onBiometric,
  });

  final String title;
  final String? subtitle;

  /// Devuelve true si el PIN es correcto/aceptado; false lo sacude y limpia.
  final Future<bool> Function(String pin) onComplete;
  final VoidCallback? onBiometric;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  int _shakes = 0;
  bool _busy = false;
  int _fails = 0;
  DateTime? _blockedUntil;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _blocked =>
      _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  Future<void> _press(String d) async {
    if (_busy || _blocked || _pin.length >= pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (_pin.length < pinLength) return;
    setState(() => _busy = true);
    final ok = await widget.onComplete(_pin);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      setState(() => _busy = false);
      return;
    }
    HapticFeedback.heavyImpact();
    _fails++;
    setState(() {
      _pin = '';
      _shakes++;
      _busy = false;
      // Tras 5 intentos fallidos, espera de 30 s.
      if (_fails % 5 == 0) {
        _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
        _tick = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted || !_blocked) t.cancel();
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget dots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < pinLength; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: i < _pin.length ? 18 : 14,
            height: i < _pin.length ? 18 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? AppColors.brand : Colors.transparent,
              border: Border.all(color: AppColors.brand, width: 2),
            ),
          ),
      ],
    );
    if (_shakes > 0) {
      dots = dots
          .animate(key: ValueKey(_shakes))
          .shakeX(hz: 6, amount: 8, duration: 450.ms);
    }
    final remaining = _blocked
        ? _blockedUntil!.difference(DateTime.now()).inSeconds + 1
        : 0;

    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Pressable(
          onTap: onTap,
          semanticLabel: label,
          scale: 0.88,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null
                  ? Colors.transparent
                  : theme.colorScheme.surfaceContainerLow,
            ),
            child: child ?? Text(label, style: theme.textTheme.headlineSmall),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        dots,
        SizedBox(
          height: 28,
          child: Center(
            child: Text(
              _blocked
                  ? 'Demasiados intentos. Espera $remaining s'
                  : _shakes > 0
                  ? 'PIN incorrecto'
                  : '',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) key(d, onTap: () => _press(d))]),
        Row(
          children: [
            widget.onBiometric == null
                ? key('')
                : key(
                    'Huella',
                    onTap: widget.onBiometric,
                    child: const Icon(Icons.fingerprint_rounded, size: 32),
                  ),
            key('0', onTap: () => _press('0')),
            key(
              'Borrar',
              onTap: _pin.isEmpty
                  ? null
                  : () => setState(
                      () => _pin = _pin.substring(0, _pin.length - 1),
                    ),
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pantalla de bloqueo: tapa la app hasta ingresar el PIN o la huella.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    // Si la huella está activa, se pide sola al aparecer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(lockSettingsProvider).biometric) _biometric();
    });
  }

  Future<void> _biometric() async {
    if (await ref.read(biometricsProvider).authenticate()) _unlock();
  }

  Future<void> _unlock() async {
    setState(() => _unlocking = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    ref.read(lockedProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(lockSettingsProvider);
    final petName = ref.watch(mascotProvider).name;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AuroraBackground(
              colors: const [
                AppColors.brand,
                AppColors.pink,
                Color(0xFF4DABF7),
              ],
              opacity: dark ? 0.22 : 0.15,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    MyMascot(
                          mood: _unlocking
                              ? MascotMood.celebrating
                              : MascotMood.sleeping,
                          size: 130,
                          interactive: false,
                        )
                        .animate(target: _unlocking ? 1 : 0)
                        .scaleXY(end: 1.15, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    PinPad(
                      title: _unlocking ? '¡Hola de nuevo!' : 'PlataPets',
                      subtitle: '$petName cuida tus datos. Ingresa tu PIN.',
                      onBiometric: settings.biometric ? _biometric : null,
                      onComplete: (pin) async {
                        final ok = await ref
                            .read(lockSettingsProvider.notifier)
                            .verify(pin);
                        if (ok) await _unlock();
                        return ok;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Envuelve la app: muestra el candado al abrir (si hay PIN) y al volver
/// tras más de 30 s en segundo plano.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed && _pausedAt != null) {
      if (DateTime.now().difference(_pausedAt!).inSeconds > 30) {
        ref.read(lockedProvider.notifier).lock();
      }
      _pausedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockedProvider);
    return Stack(
      children: [
        // La app sigue montada debajo (no se pierde el estado).
        ExcludeSemantics(excluding: locked, child: widget.child),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 1.06, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: locked
              ? const LockScreen(key: ValueKey('lock'))
              : const SizedBox.shrink(key: ValueKey('open')),
        ),
      ],
    );
  }
}
