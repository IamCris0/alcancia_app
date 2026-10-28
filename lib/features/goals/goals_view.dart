import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/planning_queries.dart';
import '../../core/money.dart';
import '../../core/motion/confetti.dart';
import '../../core/motion/liquid_progress.dart';
import '../../core/motion/skeleton.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/amount_sheet.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/animated_money.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import '../plans/plans_providers.dart';
import 'goal_form.dart';

class GoalsView extends ConsumerWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goals = ref.watch(goalsProvider);
    return goals.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final saved = list
            .where((g) => !g.completed)
            .fold<int>(0, (s, g) => s + g.saved);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apartado en metas',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AnimatedMoney(
                        saved,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => showGoalForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const _GoalsEmpty()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) =>
                    _GoalCard(status: list[i])
                        .animate(delay: (40 * i).ms)
                        .fadeIn()
                        .scaleXY(begin: 0.92, curve: Curves.easeOutBack),
              ),
          ],
        );
      },
    );
  }
}

class _GoalsEmpty extends StatelessWidget {
  const _GoalsEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      gradient: AppColors.heroGradient,
      onTap: () => showGoalForm(context),
      child: Row(
        children: [
          const MyMascot(size: 84, interactive: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crea tu primera meta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Un viaje, un celular o un fondo de emergencia: '
                  'llenemos el frasco juntos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.status});

  final GoalStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final g = status.goal;
    final color = Color(g.colorValue);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => showGoalDetail(context, g.id),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(iconKey: g.iconKey, color: color, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  g.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              if (status.completed)
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.savings,
                  size: 20,
                ),
            ],
          ),
          const Spacer(),
          LiquidProgress(
            progress: status.progress,
            color: color,
            size: 96,
            child: Text(
              '${(status.progress * 100).clamp(0, 999).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 6)],
              ),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatMoney(status.saved, currency)} / '
              '${formatMoney(g.target, currency)}',
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showGoalDetail(BuildContext context, int goalId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GoalDetail(goalId: goalId),
    );

class _GoalDetail extends ConsumerWidget {
  const _GoalDetail({required this.goalId});

  final int goalId;

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    GoalStatus s, {
    required bool withdraw,
  }) async {
    final cents = await showAmountSheet(
      context,
      title: withdraw ? 'Retirar de la meta' : 'Aportar a "${s.goal.name}"',
      action: withdraw ? 'Retirar' : 'Aportar',
      color: withdraw ? AppColors.expense : Color(s.goal.colorValue),
      max: withdraw ? s.saved : null,
    );
    if (cents == null) return;
    final db = ref.read(databaseProvider);
    final completed = await db.contribute(
      goalId,
      withdraw ? -cents : cents,
      DateTime.now(),
    );
    ref.read(mascotEventProvider.notifier).bump();
    final result = await ref
        .read(gamificationServiceProvider)
        .onContribution(
          goalId: goalId,
          amount: withdraw ? -cents : cents,
          completedGoalName: completed ? s.goal.name : null,
        );
    if (result.hasCelebrations && context.mounted) {
      await showCelebrations(context, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final status = (ref.watch(goalsProvider).value ?? const <GoalStatus>[])
        .where((g) => g.goal.id == goalId)
        .firstOrNull;
    if (status == null) return const SizedBox(height: 200);
    final g = status.goal;
    final color = Color(g.colorValue);
    final contributions =
        ref.watch(_contributionsProvider(goalId)).value ?? const [];

    String? pace;
    if (g.deadline != null && !status.completed && status.remaining > 0) {
      final months =
          (g.deadline!.year - DateTime.now().year) * 12 +
          g.deadline!.month -
          DateTime.now().month;
      pace = months <= 0
          ? 'La fecha límite es este mes'
          : 'Aparta ${formatMoney(status.remaining ~/ months, currency)} al mes '
                'para llegar a tiempo';
    }

    return SafeArea(
      child: Stack(
        children: [
          if (status.completed) const Positioned.fill(child: ConfettiBurst()),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(g.name, style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => showGoalForm(context, existing: g),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    LiquidProgress(
                      progress: status.progress,
                      color: color,
                      size: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedMoney(
                            status.saved,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                          ),
                          Text(
                            'de ${formatMoney(g.target, currency)}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: MyMascot(
                        mood: status.completed
                            ? MascotMood.celebrating
                            : MascotMood.happy,
                        size: 70,
                        reactToEvents: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  status.completed
                      ? '¡Meta cumplida! 🎉'
                      : 'Te faltan ${formatMoney(status.remaining, currency)}',
                  style: theme.textTheme.titleMedium,
                ),
                if (pace != null)
                  Text(
                    pace,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: status.saved > 0
                            ? () => _contribute(
                                context,
                                ref,
                                status,
                                withdraw: true,
                              )
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('Retirar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: color),
                        onPressed: () =>
                            _contribute(context, ref, status, withdraw: false),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Aportar'),
                      ),
                    ),
                  ],
                ),
                if (contributions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Historial', style: theme.textTheme.titleSmall),
                  ),
                  for (final c in contributions.take(20))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        c.amount >= 0
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: c.amount >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                      title: Text(formatSigned(c.amount, currency)),
                      trailing: Text(
                        DateFormat('d MMM yyyy', 'es').format(c.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _contributionsProvider = StreamProvider.autoDispose.family(
  (ref, int goalId) => ref.watch(databaseProvider).watchContributions(goalId),
);
