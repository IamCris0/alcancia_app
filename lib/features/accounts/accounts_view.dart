import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/animated_money.dart';
import '../../core/ui/app_card.dart';
import '../../core/widgets/pickers.dart';
import 'account_form.dart';
import 'account_type_ui.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsWithBalanceProvider);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final total = list.fold<int>(0, (sum, a) => sum + a.balance);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cuentas',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => showAccountForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nueva'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                gradient: AppColors.heroGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patrimonio total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedMoney(
                      total,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${list.length} ${list.length == 1 ? 'cuenta' : 'cuentas'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.08),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Aún no tienes cuentas. ¡Crea la primera!'),
                  ),
                ),
              for (final (i, a) in list.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => showAccountForm(context, existing: a.account),
                    child: Row(
                      children: [
                        IconBadge(
                          iconKey: a.account.iconKey,
                          color: Color(a.account.colorValue),
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.account.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                a.account.type.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedMoney(
                          a.balance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: a.balance < 0 ? AppColors.expense : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (70 * i).ms).fadeIn().slideX(begin: 0.06),
            ],
          );
        },
      ),
    );
  }
}
