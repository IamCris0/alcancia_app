import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/theme.dart';
import '../../core/ui/animated_money.dart';
import '../../core/ui/app_card.dart';
import '../../core/widgets/pickers.dart';
import '../accounts/account_form.dart';
import '../accounts/accounts_view.dart';
import '../gamification/gamification_providers.dart';
import '../profile/profile_view.dart';

/// Racha y nivel de un vistazo; tocar lleva al perfil.
class ProgressChips extends ConsumerWidget {
  const ProgressChips({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(streakProvider);
    final level = ref.watch(levelProvider);

    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: onTap,
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                StreakFlame(active: streak.current > 0, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.current} '
                        '${streak.current == 1 ? 'día' : 'días'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        streak.atRisk ? '¡Registra hoy!' : 'de racha',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: streak.atRisk
                              ? AppColors.expense
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            onTap: onTap,
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.fabGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${level.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel ${level.level}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: level.progress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            color: AppColors.savings,
                            backgroundColor: AppColors.savings.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tira horizontal con las cuentas y su saldo.
class AccountsStrip extends StatelessWidget {
  const AccountsStrip({super.key, required this.accounts});

  final List<AccountWithBalance> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final (i, a) in accounts.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 150,
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  radius: 20,
                  onTap: () => showAccountForm(context, existing: a.account),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBadge(
                            iconKey: a.account.iconKey,
                            color: Color(a.account.colorValue),
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedMoney(
                          a.balance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: a.balance < 0 ? AppColors.expense : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(delay: (60 * i).ms).fadeIn().slideX(begin: 0.2),
          SizedBox(
            width: 104,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              radius: 20,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const Scaffold(body: AccountsView(standalone: true)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ver todas',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
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
