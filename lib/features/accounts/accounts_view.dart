import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import 'account_form.dart';
import 'account_type_ui.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final currency = ref.watch(currencyProvider);
    final name = ref.watch(userNameProvider) ?? '';
    final theme = Theme.of(context);

    return accounts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final total = list.fold<int>(0, (sum, a) => sum + a.initialBalance);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, $name! 👋',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Saldo total', style: theme.textTheme.labelLarge),
                    Text(
                      formatMoney(total, currency),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 16),
            Text('Mis cuentas', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Aún no tienes cuentas. ¡Crea la primera!'),
                ),
              ),
            for (final (i, a) in list.indexed)
              Card(
                child: ListTile(
                  leading: IconBadge(
                    iconKey: a.iconKey,
                    color: Color(a.colorValue),
                  ),
                  title: Text(a.name),
                  subtitle: Text(a.type.label),
                  trailing: Text(
                    formatMoney(a.initialBalance, currency),
                    style: theme.textTheme.titleMedium,
                  ),
                  onTap: () => showAccountForm(context, existing: a),
                ),
              ).animate(delay: (80 * i).ms).fadeIn().slideX(begin: 0.1),
          ],
        );
      },
    );
  }
}
