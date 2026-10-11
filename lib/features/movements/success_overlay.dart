import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/motion/confetti.dart';
import '../../core/theme.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

/// Confirmación al guardar: la mascota aparece celebrando, un sello con check
/// rebota a su lado y cae confeti del color del movimiento.
class SuccessOverlay extends ConsumerWidget {
  const SuccessOverlay({super.key, required this.type, required this.color});

  final MovementType type;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mascot = ref.watch(mascotProvider);
    final message = switch (type) {
      MovementType.income => '¡${mascot.name} está feliz!',
      MovementType.expense => 'Gasto registrado',
      MovementType.transfer => 'Transferencia lista',
    };

    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        child: Stack(
          children: [
            Positioned.fill(
              child: ConfettiBurst(
                count: type == MovementType.income ? 60 : 34,
                origin: const Alignment(0, -0.05),
                colors: [
                  color,
                  AppColors.savings,
                  AppColors.pink,
                  Colors.white,
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 210,
                    height: 180,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Anillo que se expande detrás de la mascota.
                        Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 3),
                              ),
                            )
                            .animate()
                            .scaleXY(begin: 0.5, end: 1.5, duration: 700.ms)
                            .fadeOut(duration: 700.ms),
                        MascotView(
                          species: mascot.species,
                          mood: MascotMood.celebrating,
                          size: 160,
                          interactive: false,
                        ).animate().scaleXY(
                          begin: 0.2,
                          duration: 650.ms,
                          curve: Curves.elasticOut,
                        ),
                        Positioned(
                          right: 6,
                          bottom: 10,
                          child:
                              Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  )
                                  .animate(delay: 250.ms)
                                  .scaleXY(
                                    begin: 0,
                                    duration: 500.ms,
                                    curve: Curves.elasticOut,
                                  )
                                  .rotate(begin: -0.25, duration: 400.ms),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.titleLarge,
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.5),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 160.ms),
    );
  }
}
