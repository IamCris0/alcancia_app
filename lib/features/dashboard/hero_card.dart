import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/aurora.dart';
import '../../core/motion/floating_coins.dart';
import '../../core/motion/rolling_money.dart';
import '../../core/motion/typewriter.dart';
import '../../core/theme.dart';
import '../mascot/mascot_mood.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

/// Tarjeta principal del inicio: fondo aurora en movimiento, monedas que
/// flotan, saldo con dígitos rodantes y la mascota "hablando".
class HeroCard extends ConsumerWidget {
  const HeroCard({
    super.key,
    required this.greeting,
    required this.total,
    required this.mood,
  });

  final String greeting;
  final int total;
  final MascotMood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mascot = ref.watch(mascotProvider);
    final reactKey = ref.watch(mascotEventProvider);
    const white = Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.38),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: AuroraBackground(
                colors: [
                  Color(0xFFFF7EB3),
                  Color(0xFF4DABF7),
                  Color(0xFFB197FC),
                ],
                opacity: 0.5,
              ),
            ),
            const Positioned.fill(
              child: FloatingCoins(count: 9, opacity: 0.55, seed: 11),
            ),
            // Brillo diagonal que cruza la tarjeta cada pocos segundos.
            Positioned.fill(
              child: IgnorePointer(
                child: const SizedBox.expand()
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      delay: 2500.ms,
                      duration: 1600.ms,
                      angle: 0.6,
                      color: white.withValues(alpha: 0.18),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: white.withValues(alpha: 0.92),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Saldo total',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RollingMoney(
                                total,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      MascotView(
                        species: mascot.species,
                        mood: mood,
                        size: 104,
                        reactKey: reactKey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SpeechBubble(name: mascot.name, message: moodMessage(mood)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Globo de diálogo con "colita" hacia la mascota y texto que se escribe.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.name, required this.message});

  final String name;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF8CE99A),
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.4, end: 1, duration: 900.ms),
          const SizedBox(width: 8),
          Expanded(
            child: TypewriterText(
              '$name: $message',
              delay: const Duration(milliseconds: 500),
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
