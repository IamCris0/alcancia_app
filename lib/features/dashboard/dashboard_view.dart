import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/animated_money.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/month_switcher.dart';
import '../mascot/mascot_mood.dart';
import 'hero_card.dart';
import '../movements/movement_tile.dart';
import '../movements/movements_view.dart';
import 'charts.dart';
import 'month_summary.dart';
import 'progress_strip.dart';
import '../recurring/upcoming_card.dart';

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

class DashboardView extends ConsumerWidget {
  const DashboardView({
    super.key,
    required this.onSeeAll,
    required this.onOpenProfile,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider) ?? '';
    final month = ref.watch(selectedMonthProvider);
    final accounts = ref.watch(accountsWithBalanceProvider).value ?? const [];
    final total = accounts.fold<int>(0, (s, a) => s + a.balance);
    final monthList =
        ref.watch(movementsProvider(MovementFilter.month(month))).value ??
        const <MovementDetails>[];
    final recent =
        ref.watch(movementsProvider(const MovementFilter(limit: 5))).value ??
        const <MovementDetails>[];
    final summary = MonthSummary.from(monthList, month);
    final mood = moodFor(income: summary.income, expense: summary.expense);

    Widget section(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?trailing,
        ],
      ),
    );

    var i = 0;
    Widget enter(Widget w) => w
        .animate(delay: (70 * i++).ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutCubic);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          enter(
            HeroCard(
              greeting: '${greeting()}, $name',
              total: total,
              mood: mood,
            ),
          ),
          const SizedBox(height: 12),
          enter(ProgressChips(onTap: onOpenProfile)),
          const UpcomingCard(),
          section('Mis cuentas'),
          enter(AccountsStrip(accounts: accounts)),
          const SizedBox(height: 20),
          enter(const MonthSwitcher()),
          const SizedBox(height: 12),
          enter(
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Ingresos',
                    cents: summary.income,
                    color: AppColors.income,
                    icon: Icons.north_east_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Gastos',
                    cents: summary.expense,
                    color: AppColors.expense,
                    icon: Icons.south_east_rounded,
                  ),
                ),
              ],
            ),
          ),
          section('Gastos por categoría'),
          enter(
            AppCard(
              child: summary.expense == 0
                  ? const _ChartEmpty(text: 'Aún no hay gastos este mes')
                  : ExpenseDonut(summary: summary),
            ),
          ),
          section('Gasto diario'),
          enter(
            AppCard(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 8),
              child: summary.expense == 0
                  ? const _ChartEmpty(
                      text: 'La gráfica aparecerá con tus gastos',
                    )
                  : DailyExpenseChart(
                      daily: summary.dailyExpense,
                      month: month,
                    ),
            ),
          ),
          section(
            'Recientes',
            trailing: recent.isEmpty
                ? null
                : TextButton(
                    onPressed: onSeeAll,
                    child: const Text('Ver todo'),
                  ),
          ),
          enter(
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: recent.isEmpty
                  ? const _ChartEmpty(
                      text: 'Toca + para registrar tu primer movimiento',
                    )
                  : Column(
                      children: [
                        for (final d in recent)
                          MovementTile(
                            d,
                            onTap: () => openMovement(context, existing: d),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.cents,
    required this.color,
    required this.icon,
  });

  final String label;
  final int cents;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              cents,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
