import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/pressable.dart';
import '../../core/widgets/pickers.dart';
import 'movement_type_ui.dart';

class MovementTile extends ConsumerWidget {
  const MovementTile(this.details, {super.key, this.onTap});

  final MovementDetails details;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final m = details.movement;
    final category = details.category;

    final title = details.isTransfer
        ? 'Transferencia'
        : (category?.name ?? m.type.label);
    final where = details.isTransfer
        ? '${details.account.name} → ${details.toAccount?.name ?? '?'}'
        : details.account.name;
    final subtitle = (m.note == null || m.note!.isEmpty)
        ? where
        : '$where · ${m.note}';

    final amountText = details.isTransfer
        ? formatMoney(m.amount, currency)
        : formatSigned(details.signedAmount, currency);
    final amountColor = switch (m.type) {
      MovementType.income => AppColors.income,
      MovementType.expense => theme.colorScheme.onSurface,
      MovementType.transfer => AppColors.transfer,
    };

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            details.isTransfer
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.transfer.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.transfer,
                    ),
                  )
                : IconBadge(
                    iconKey: category?.iconKey ?? 'other',
                    color: Color(category?.colorValue ?? 0xFF868E96),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountText,
              style: theme.textTheme.titleSmall?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
