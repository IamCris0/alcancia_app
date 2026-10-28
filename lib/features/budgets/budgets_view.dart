import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/gamification_queries.dart';
import '../../core/money.dart';
import '../../core/motion/skeleton.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/month_switcher.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/gamification_providers.dart';
import '../mascot/mascot_providers.dart';
import '../mascot/mascot_view.dart';
import 'budget_form.dart';
import 'budget_ring.dart';

class BudgetsView extends ConsumerWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final budgets = ref.watch(budgetsProvider(month));

    return SafeArea(
      bottom: false,
      child: budgets.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final general = list.where((b) => b.isGeneral).firstOrNull;
          final byCategory = list.where((b) => !b.isGeneral).toList();
          final taken = {for (final b in list) b.categoryId};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Presupuestos',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => showBudgetForm(context, taken: taken),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const MonthSwitcher(),
              const SizedBox(height: 16),
              if (general != null)
                _GeneralCard(
                  budget: general,
                  month: month,
                  onTap: () =>
                      showBudgetForm(context, existing: general, taken: taken),
                ).animate().fadeIn().slideY(begin: 0.06)
              else
                _GeneralEmpty(
                  onTap: () => showBudgetForm(context, taken: taken),
                ).animate().fadeIn(),
              const SizedBox(height: 24),
              Text('Por categoría', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              if (byCategory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Pon un límite a las categorías donde más gastas: '
                    'Comida, Ocio, Compras…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final (i, b) in byCategory.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryBudgetCard(
                    budget: b,
                    onTap: () =>
                        showBudgetForm(context, existing: b, taken: taken),
                  ),
                ).animate(delay: (60 * i).ms).fadeIn().slideX(begin: 0.06),
            ],
          );
        },
      ),
    );
  }
}

class _GeneralCard extends ConsumerWidget {
  const _GeneralCard({
    required this.budget,
    required this.month,
    required this.onTap,
  });

  final BudgetStatus budget;
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();
    final isCurrent = now.year == month.year && now.month == month.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysLeft = isCurrent ? daysInMonth - now.day + 1 : 0;
    final perDay = daysLeft > 0 && budget.remaining > 0
        ? budget.remaining ~/ daysLeft
        : 0;
    final pct = (budget.ratio * 100).round();

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          BudgetRing(
            ratio: budget.ratio,
            size: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: budgetColor(budget.ratio),
                  ),
                ),
                Text('usado', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto general',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(budget.spent, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'de ${formatMoney(budget.limit, currency)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  budget.remaining >= 0
                      ? 'Te quedan ${formatMoney(budget.remaining, currency)}'
                      : 'Excedido por ${formatMoney(-budget.remaining, currency)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: budgetColor(budget.ratio),
                  ),
                ),
                if (perDay > 0)
                  Text(
                    '≈ ${formatMoney(perDay, currency)} por día '
                    '($daysLeft días)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _GeneralEmpty extends StatelessWidget {
  const _GeneralEmpty({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      gradient: AppColors.heroGradient,
      child: Row(
        children: [
          const MyMascot(
            mood: MascotMood.neutral,
            size: 84,
            interactive: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define tu presupuesto del mes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Te avisaré cuando te acerques al límite.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends ConsumerWidget {
  const _CategoryBudgetCard({required this.budget, required this.onTap});

  final BudgetStatus budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final color = budgetColor(budget.ratio);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(
                iconKey: budget.iconKey ?? 'other',
                color: Color(budget.colorValue ?? 0xFF868E96),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName ?? 'Categoría',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${formatMoney(budget.spent, currency)} de '
                      '${formatMoney(budget.limit, currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                budget.remaining >= 0
                    ? formatMoney(budget.remaining, currency)
                    : '−${formatMoney(-budget.remaining, currency)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: budget.ratio.clamp(0, 1)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
