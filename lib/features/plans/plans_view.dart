import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/ui/pressable.dart';
import '../budgets/budgets_view.dart';
import '../debts/debts_view.dart';
import '../goals/goals_view.dart';

/// Pestaña Metas: presupuestos, ahorros y deudas, con un selector de
/// píldora deslizante y transición lateral entre secciones.
class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  int _section = 0;
  int _direction = 1;

  static const _labels = ['Presupuestos', 'Ahorros', 'Deudas'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const pages = [BudgetsView(), GoalsView(), DebtsView()];
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Metas', style: theme.textTheme.headlineMedium),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionSwitch(
              labels: _labels,
              selected: _section,
              onChanged: (i) => setState(() {
                _direction = i > _section ? 1 : -1;
                _section = i;
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(_section);
                final dx = (incoming ? 0.12 : -0.12) * _direction;
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
              child: KeyedSubtree(
                key: ValueKey(_section),
                child: pages[_section],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow(context),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            alignment: Alignment(-1 + selected * 2 / (labels.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.fabGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, l) in labels.indexed)
                Expanded(
                  child: Pressable(
                    semanticLabel: l,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: i == selected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        child: Text(l),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
