import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/planning_queries.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/app_card.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/streak.dart';
import '../mascot/mascot_providers.dart';
import '../plans/plans_providers.dart';
import 'recurring_page.dart';

/// En el inicio: recurrentes por confirmar hoy y los de los próximos 7 días.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    RecurringDetails d,
  ) async {
    final movement = await ref
        .read(recurringServiceProvider)
        .confirm(d.recurring);
    ref.read(mascotEventProvider.notifier).bump();
    final result = await ref
        .read(gamificationServiceProvider)
        .onMovementSaved(movement);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${d.recurring.name} registrado'
          '${result.xpGained > 0 ? ' · +${result.xpGained} XP' : ''}',
        ),
      ),
    );
    if (result.hasCelebrations) await showCelebrations(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final all = ref.watch(recurringsProvider).value ?? const [];
    final service = ref.watch(recurringServiceProvider);
    final today = dayOf(DateTime.now());
    final pending = [
      for (final d in all)
        if (d.recurring.active &&
            !d.recurring.autoRegister &&
            service.isDue(d.recurring))
          d,
    ];
    final soon = [
      for (final d in all)
        if (d.recurring.active &&
            !service.isDue(d.recurring) &&
            !d.recurring.nextDate.isAfter(addDays(today, 7)))
          d,
    ];
    if (pending.isEmpty && soon.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pending.isNotEmpty ? 'Por confirmar' : 'Próximos pagos',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecurringPage(),
                    ),
                  ),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            for (final d in pending)
              _Row(
                details: d,
                subtitle: 'Hoy · ${formatMoney(d.recurring.amount, currency)}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Omitir',
                      onPressed: () =>
                          ref.read(recurringServiceProvider).skip(d.recurring),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton.filled(
                      tooltip: 'Registrar',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.income,
                      ),
                      onPressed: () => _confirm(context, ref, d),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
              ).animate().fadeIn().shimmer(delay: 400.ms, duration: 1200.ms),
            for (final d in soon.take(3))
              _Row(
                details: d,
                subtitle: DateFormat(
                  "EEEE d",
                  'es',
                ).format(d.recurring.nextDate),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    formatMoney(d.recurring.amount, currency),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.details,
    required this.subtitle,
    required this.trailing,
  });

  final RecurringDetails details;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = details.recurring;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconBadge(
            iconKey: details.category?.iconKey ?? 'other',
            color: Color(details.category?.colorValue ?? 0xFF868E96),
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.type == MovementType.income ? '💰 ${r.name}' : r.name,
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
