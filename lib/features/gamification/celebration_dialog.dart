import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/confetti.dart';
import '../../core/theme.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import 'achievements.dart';
import 'gamification_service.dart';
import 'levels.dart';

/// Muestra, una tras otra, las celebraciones de un resultado: primero la
/// subida de nivel (con el accesorio desbloqueado) y luego cada logro.
Future<void> showCelebrations(
  BuildContext context,
  GamificationResult result,
) async {
  if (result.milestone != null) {
    await _show(context, _MilestoneCard(text: result.milestone!));
    if (!context.mounted) return;
  }
  if (result.leveledUp) {
    final accessory = accessoryUnlockedAt(result.levelAfter);
    // Se pone el accesorio nuevo automáticamente: es la sorpresa.
    if (accessory != null) {
      await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(mascotProvider.notifier).wear(accessory);
    }
    if (!context.mounted) return;
    await _show(
      context,
      _LevelUpCard(
        level: result.levelAfter,
        title:
            levelTitles[(result.levelAfter - 1).clamp(
              0,
              levelTitles.length - 1,
            )],
        accessory: accessory,
      ),
    );
  }
  for (final a in result.unlocked) {
    if (!context.mounted) return;
    await _show(context, _AchievementCard(def: a));
  }
}

Future<void> _show(BuildContext context, Widget card) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (_, _, _) => Stack(
      children: [
        const Positioned.fill(child: ConfettiBurst(count: 70)),
        Center(child: card),
      ],
    ),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.7,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.elasticOut)),
        child: child,
      ),
    ),
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...children,
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('¡Genial!'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelUpCard extends StatelessWidget {
  const _LevelUpCard({
    required this.level,
    required this.title,
    required this.accessory,
  });

  final int level;
  final String title;
  final MascotAccessory? accessory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      children: [
        Text(
          '¡SUBISTE DE NIVEL!',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.brand,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn().slideY(begin: -0.5),
        const SizedBox(height: 8),
        const MyMascot(
          mood: MascotMood.celebrating,
          size: 150,
          interactive: false,
        ),
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.fabGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Nivel $level',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            )
            .animate(delay: 250.ms)
            .scaleXY(begin: 0, curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 10),
        Text(title, style: theme.textTheme.titleMedium),
        if (accessory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.savings.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🎁 Nuevo accesorio: ${accessoryLabel(accessory!)}',
              style: theme.textTheme.labelLarge,
            ),
          ).animate(delay: 500.ms).fadeIn().shimmer(duration: 1200.ms),
        ],
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.def});

  final AchievementDef def;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      children: [
        Text(
          'LOGRO DESBLOQUEADO',
          style: theme.textTheme.labelLarge?.copyWith(
            color: def.color,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        AchievementBadge(def: def, unlocked: true, size: 104)
            .animate()
            .scaleXY(begin: 0.2, duration: 800.ms, curve: Curves.elasticOut)
            .rotate(begin: -0.15, duration: 600.ms, curve: Curves.easeOutBack)
            .then()
            .shimmer(duration: 1200.ms),
        const SizedBox(height: 16),
        Text(def.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          def.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (def.xp > 0) ...[
          const SizedBox(height: 12),
          Text(
            '+${def.xp} XP',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.savings,
              fontWeight: FontWeight.w800,
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.6),
        ],
      ],
    );
  }
}

/// Medalla circular de un logro (a color si está desbloqueado).
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.def,
    required this.unlocked,
    this.size = 64,
  });

  final AchievementDef def;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(def.color, Colors.white, 0.35)!, def.color],
              )
            : null,
        color: unlocked ? null : scheme.surfaceContainerHighest,
        border: Border.all(
          color: unlocked
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.transparent,
          width: size * 0.05,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: def.color.withValues(alpha: 0.4),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: Icon(
        unlocked ? def.icon : Icons.lock_rounded,
        size: size * 0.48,
        color: unlocked
            ? Colors.white
            : scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Hito especial: trofeo que gira y la mascota celebrando.
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                    Icons.emoji_events_rounded,
                    size: 150,
                    color: AppColors.savings,
                  )
                  .animate()
                  .scaleXY(
                    begin: 0.2,
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shimmer(duration: 1400.ms),
              const Positioned(
                bottom: 0,
                right: 10,
                child: MyMascot(
                  mood: MascotMood.celebrating,
                  size: 80,
                  interactive: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.4),
      ],
    );
  }
}
