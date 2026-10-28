import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/pressable.dart';
import '../accounts/accounts_view.dart';
import '../categories/categories_view.dart';
import '../gamification/achievements.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/levels.dart';
import '../gamification/streak.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import 'profile_settings.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unlocked = ref.watch(unlockedAchievementsProvider).value ?? const {};

    var i = 0;
    Widget enter(Widget w) => w
        .animate(delay: (70 * i++).ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('Perfil', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          enter(const _MascotCard()),
          const SizedBox(height: 12),
          enter(const _StreakCard()),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Logros', style: theme.textTheme.titleMedium),
              ),
              Text(
                '${unlocked.length}/${achievementDefs.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          enter(_AchievementsGrid(unlocked: unlocked)),
          const SizedBox(height: 24),
          Text('Ajustes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          enter(const _SettingsList()),
        ],
      ),
    );
  }
}

class _MascotCard extends ConsumerWidget {
  const _MascotCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mascot = ref.watch(mascotProvider);
    final level = ref.watch(levelProvider);
    final userName = ref.watch(userNameProvider) ?? '';
    const white = Colors.white;

    return AppCard(
      gradient: AppColors.heroGradient,
      padding: const EdgeInsets.fromLTRB(16, 18, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              const MyMascot(size: 120, reactToEvents: true),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascot.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: white,
                      ),
                    ),
                    Text(
                      'Compañero de $userName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nivel ${level.level} · ${level.title}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${level.xpIntoLevel} / ${level.xpNeeded} XP',
                style: theme.textTheme.labelMedium?.copyWith(color: white),
              ),
              const Spacer(),
              Text(
                'Nivel ${level.level + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _XpBar(progress: level.progress),
          const SizedBox(height: 16),
          _AccessoryPicker(level: level.level, wearing: mascot.accessory),
        ],
      ),
    );
  }
}

/// Barra de XP que se llena con brillo recorriéndola.
class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE066), AppColors.savings],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessoryPicker extends ConsumerWidget {
  const _AccessoryPicker({required this.level, required this.wearing});

  final int level;
  final MascotAccessory wearing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final species = ref.watch(mascotProvider).species;
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final a in MascotAccessory.values)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Pressable(
                semanticLabel: accessoryLabel(a),
                onTap: isAccessoryUnlocked(a, level)
                    ? () => ref.read(mascotProvider.notifier).wear(a)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: a == wearing ? 0.3 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: a == wearing ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: isAccessoryUnlocked(a, level) ? 1 : 0.35,
                            child: MascotView(
                              species: species,
                              accessory: a,
                              size: 48,
                              interactive: false,
                            ),
                          ),
                          Text(
                            isAccessoryUnlocked(a, level)
                                ? accessoryLabel(a)
                                : 'Nivel ${accessoryUnlockLevel[a]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (!isAccessoryUnlocked(a, level))
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
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

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(streakProvider);
    final active = streak.current > 0;
    final today = dayOf(DateTime.now());
    final week = [for (var d = 6; d >= 0; d--) addDays(today, -d)];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              StreakFlame(active: active, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.current} ${streak.current == 1 ? 'día' : 'días'} '
                      'de racha',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      streak.atRisk
                          ? '¡Registra algo hoy para no perderla!'
                          : 'Mejor racha: ${streak.best} días',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: streak.atRisk
                            ? AppColors.expense
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message:
                    'Congeladores: salvan tu racha si faltas un día. '
                    'Ganas uno cada 7 días registrados.',
                child: Row(
                  children: [
                    for (var i = 0; i < maxFreezes; i++)
                      Icon(
                        Icons.ac_unit_rounded,
                        size: 20,
                        color: i < streak.freezesAvailable
                            ? const Color(0xFF4DABF7)
                            : theme.colorScheme.outlineVariant,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (i, d) in week.indexed)
                _DayDot(
                      label: DateFormat('E', 'es').format(d)[0].toUpperCase(),
                      active: streak.activeDays.contains(d),
                      today: d == today,
                    )
                    .animate(delay: (50 * i).ms)
                    .scaleXY(begin: 0.5, curve: Curves.easeOutBack),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.active,
    required this.today,
  });

  final String label;
  final bool active;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC233), Color(0xFFFF6B3D)],
                  )
                : null,
            color: active ? null : theme.colorScheme.surfaceContainerHighest,
            border: today ? Border.all(color: AppColors.brand, width: 2) : null,
          ),
          child: active
              ? const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Llama que "parpadea" cuando la racha está viva; gris si no.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.active, this.size = 32});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: active
            ? const [Color(0xFFFF4D2E), Color(0xFFFFC233)]
            : [Colors.grey.shade500, Colors.grey.shade400],
      ).createShader(rect),
      child: Icon(
        Icons.local_fire_department_rounded,
        size: size,
        color: Colors.white,
      ),
    );
    if (!active) return icon;
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.92,
          end: 1.06,
          duration: 650.ms,
          curve: Curves.easeInOut,
        )
        .rotate(begin: -0.02, end: 0.02, duration: 420.ms);
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.unlocked});

  final Map<String, DateTime> unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Primero los desbloqueados.
    final defs = [...achievementDefs]
      ..sort(
        (a, b) => (unlocked.containsKey(b.key) ? 1 : 0).compareTo(
          unlocked.containsKey(a.key) ? 1 : 0,
        ),
      );
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: defs.length,
      itemBuilder: (context, i) {
        final def = defs[i];
        final on = unlocked.containsKey(def.key);
        return AppCard(
          padding: const EdgeInsets.all(10),
          onTap: () => _showDetail(context, def, unlocked[def.key]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AchievementBadge(def: def, unlocked: on, size: 54),
              const SizedBox(height: 8),
              Text(
                def.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: on ? null : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, AchievementDef def, DateTime? at) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementBadge(
              def: def,
              unlocked: at != null,
              size: 88,
            ).animate().scaleXY(
              begin: 0.5,
              curve: Curves.elasticOut,
              duration: 700.ms,
            ),
            const SizedBox(height: 12),
            Text(def.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(def.description, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              at != null
                  ? 'Desbloqueado el ${DateFormat("d 'de' MMMM yyyy", 'es').format(at)}'
                  : def.xp > 0
                  ? 'Recompensa: ${def.xp} XP'
                  : 'Bloqueado',
              style: theme.textTheme.labelLarge?.copyWith(
                color: at != null ? AppColors.income : AppColors.savings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    Widget tile(IconData icon, String title, String? sub, VoidCallback onTap) =>
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: sub == null ? null : Text(sub),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          tile(
            Icons.account_balance_wallet_rounded,
            'Cuentas',
            null,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: AccountsView(standalone: true)),
              ),
            ),
          ),
          tile(
            Icons.category_rounded,
            'Categorías',
            null,
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: CategoriesView(standalone: true)),
              ),
            ),
          ),
          tile(
            Icons.pets_rounded,
            'Cambiar mascota',
            null,
            () => showMascotSettings(context),
          ),
          tile(
            Icons.payments_rounded,
            'Moneda',
            currency,
            () => showCurrencySettings(context),
          ),
          tile(
            Icons.badge_rounded,
            'Tu nombre',
            ref.watch(userNameProvider),
            () => showNameSettings(context),
          ),
        ],
      ),
    );
  }
}
