import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';
import 'pressable.dart';

String monthLabel(DateTime month) {
  final s = DateFormat('MMMM yyyy', 'es').format(month);
  return s[0].toUpperCase() + s.substring(1);
}

/// "‹ Octubre 2026 ›" con el texto deslizándose en la dirección del cambio.
class MonthSwitcher extends ConsumerStatefulWidget {
  const MonthSwitcher({super.key});

  @override
  ConsumerState<MonthSwitcher> createState() => _MonthSwitcherState();
}

class _MonthSwitcherState extends ConsumerState<MonthSwitcher> {
  int _direction = 1;

  void _shift(int delta) {
    setState(() => _direction = delta);
    ref.read(selectedMonthProvider.notifier).shift(delta);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final theme = Theme.of(context);

    Widget arrow(IconData icon, int delta, bool enabled) => Pressable(
      onTap: enabled ? () => _shift(delta) : null,
      semanticLabel: delta < 0 ? 'Mes anterior' : 'Mes siguiente',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: enabled ? null : theme.disabledColor),
      ),
    );

    return Row(
      children: [
        arrow(Icons.chevron_left_rounded, -1, true),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey(month);
              final dx = (incoming ? 0.4 : -0.4) * _direction;
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              monthLabel(month),
              key: ValueKey(month),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        arrow(Icons.chevron_right_rounded, 1, !isCurrent),
      ],
    );
  }
}
