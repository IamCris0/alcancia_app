import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/motion/confetti.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../gamification/gamification_service.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';

/// Confirmación al guardar: la mascota celebra (o se preocupa si te pasaste
/// del presupuesto), un sello con check rebota, sube la XP ganada y cae
/// confeti del color del movimiento.
class SuccessOverlay extends ConsumerWidget {
  const SuccessOverlay({
    super.key,
    required this.type,
    required this.color,
    this.result = GamificationResult.none,
  });

  final MovementType type;
  final Color color;
  final GamificationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mascot = ref.watch(mascotProvider);
    final currency = ref.watch(currencyProvider);
    final alert = result.alert;
    final exceeded = alert?.level == BudgetAlertLevel.exceeded;
    final message = switch (type) {
      MovementType.income => '¡${mascot.name} está feliz!',
      MovementType.expense => 'Gasto registrado',
      MovementType.transfer => 'Transferencia lista',
    };

    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        child: Stack(
          children: [
            if (!exceeded)
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                          MyMascot(
                            mood: exceeded
                                ? MascotMood.worried
                                : MascotMood.celebrating,
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
                            child: _CheckSeal(color: color),
                          ),
                          if (result.xpGained > 0)
                            Positioned(
                              left: 0,
                              top: 6,
                              child: _XpChip(xp: result.xpGained),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: theme.textTheme.titleLarge,
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.5),
                    if (result.streak > 1 || result.freezeUsed) ...[
                      const SizedBox(height: 8),
                      Text(
                        result.freezeUsed
                            ? '❄️ Usaste un congelador: tu racha de '
                                  '${result.streak} días sigue viva'
                            : '🔥 Racha de ${result.streak} días',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ).animate(delay: 350.ms).fadeIn(),
                    ],
                    if (alert != null) ...[
                      const SizedBox(height: 14),
                      _AlertBanner(alert: alert, currency: currency),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 160.ms),
    );
  }
}

class _CheckSeal extends StatelessWidget {
  const _CheckSeal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
        )
        .animate(delay: 250.ms)
        .scaleXY(begin: 0, duration: 500.ms, curve: Curves.elasticOut)
        .rotate(begin: -0.25, duration: 400.ms);
  }
}

/// "+15 XP" que aparece, sube y se queda flotando.
class _XpChip extends StatelessWidget {
  const _XpChip({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.savings,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.savings.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            '+$xp XP',
            style: const TextStyle(
              color: Color(0xFF3D2C3E),
              fontWeight: FontWeight.w800,
            ),
          ),
        )
        .animate(delay: 450.ms)
        .fadeIn(duration: 200.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
        .then()
        .shimmer(duration: 900.ms);
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.currency});

  final BudgetAlert alert;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final exceeded = alert.level == BudgetAlertLevel.exceeded;
    final color = exceeded ? AppColors.expense : AppColors.savings;
    final where = alert.name == 'general'
        ? 'tu presupuesto del mes'
        : 'el presupuesto de ${alert.name}';
    final text = exceeded
        ? 'Te pasaste de $where por '
              '${formatMoney(-alert.remaining, currency)}'
        : 'Ojo: te quedan ${formatMoney(alert.remaining, currency)} en $where';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exceeded
                ? Icons.error_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().shakeX(hz: 4, amount: exceeded ? 4 : 0);
  }
}
