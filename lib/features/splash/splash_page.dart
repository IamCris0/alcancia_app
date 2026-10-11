import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/aurora.dart';
import '../../core/motion/floating_coins.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

/// Se puede desactivar en tests para ir directo al contenido.
final showSplashProvider = Provider<bool>((ref) => true);

const splashBackground = Color(0xFF1E1446);

/// Intro animada: la mascota cae con rebote, atrapa dos monedas y el nombre
/// de la app aparece letra a letra sobre un fondo aurora.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final _timers = <Timer>[];
  int _react = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) {
        _timers.add(Timer(const Duration(milliseconds: 400), widget.onDone));
        return;
      }
      for (final ms in [850, 1350]) {
        _timers.add(
          Timer(Duration(milliseconds: ms), () {
            if (mounted) setState(() => _react++);
          }),
        );
      }
      _timers.add(Timer(const Duration(milliseconds: 2300), widget.onDone));
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mascot = ref.watch(mascotProvider);
    // "Plata" en blanco y "Pets" en dorado.
    const title = 'PlataPets';
    return Scaffold(
      backgroundColor: splashBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AuroraBackground(
              colors: [Color(0xFF7C5CFF), Color(0xFFFF7EB3), Color(0xFF4DABF7)],
              opacity: 0.45,
              duration: Duration(seconds: 8),
            ),
          ),
          const Positioned.fill(child: FloatingCoins(count: 16, opacity: 0.7)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MascotView(
                      species: mascot.species,
                      size: 170,
                      reactKey: _react,
                      interactive: false,
                    )
                    .animate()
                    .moveY(
                      begin: -420,
                      end: 0,
                      duration: 750.ms,
                      curve: Curves.bounceOut,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, ch) in title.split('').indexed)
                      Text(
                            ch,
                            style: TextStyle(
                              color: i < 5
                                  ? Colors.white
                                  : const Color(0xFFFFC233),
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          )
                          .animate(delay: (700 + i * 55).ms)
                          .fadeIn(duration: 250.ms)
                          .moveY(
                            begin: 24,
                            end: 0,
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                      'Tu dinero, con compañía',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate(delay: 1300.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
