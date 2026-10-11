import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/animated_money.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/month_switcher.dart';
import '../../core/ui/routes.dart';
import '../mascot/piggy_mascot.dart';
import 'add_movement_page.dart';
import 'movement_tile.dart';

String dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  if (d == today) return 'Hoy';
  if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
  final s = DateFormat("EEEE d 'de' MMMM", 'es').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

Future<void> openMovement(BuildContext context, [MovementDetails? existing]) =>
    Navigator.of(context)
        .push(slideUpRoute(AddMovementPage(existing: existing)));

/// Historial del mes: resumen, filtros, búsqueda y lista agrupada por día.
class MovementsView extends ConsumerStatefulWidget {
  const MovementsView({super.key});

  @override
  ConsumerState<MovementsView> createState() => _MovementsViewState();
}

class _MovementsViewState extends ConsumerState<MovementsView> {
  MovementType? _type;
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(MovementDetails d) async {
    final db = ref.read(databaseProvider);
    await db.deleteMovement(d.movement.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Movimiento eliminado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => db.restoreMovement(d.movement),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final query = _search.text;
    final all = ref.watch(movementsProvider(MovementFilter.month(month)));
    final filtered = ref.watch(
      movementsProvider(MovementFilter.month(month, type: _type, query: query)),
    );

    final monthList = all.value ?? const <MovementDetails>[];
    final income = monthList
        .where((d) => d.movement.type == MovementType.income)
        .fold<int>(0, (s, d) => s + d.movement.amount);
    final expense = monthList
        .where((d) => d.movement.type == MovementType.expense)
        .fold<int>(0, (s, d) => s + d.movement.amount);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Movimientos',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: _searching ? 'Cerrar búsqueda' : 'Buscar',
                      onPressed: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) _search.clear();
                      }),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) =>
                            RotationTransition(turns: a, child: c),
                        child: Icon(
                          _searching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          key: ValueKey(_searching),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _searching
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nota, categoría o cuenta',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),
                const MonthSwitcher(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Ingresos',
                        cents: income,
                        color: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Gastos',
                        cents: expense,
                        color: AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Neto',
                        cents: income - expense,
                        color: theme.colorScheme.onSurface,
                        signed: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (label, type) in [
                        ('Todos', null),
                        ('Gastos', MovementType.expense),
                        ('Ingresos', MovementType.income),
                        ('Transferencias', MovementType.transfer),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ...filtered.when(
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ],
            data: (list) => list.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: _EmptyState(
                        filtering: _type != null || query.isNotEmpty,
                      ),
                    ),
                  ]
                : _groupedSlivers(context, list),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  List<Widget> _groupedSlivers(
    BuildContext context,
    List<MovementDetails> list,
  ) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final groups = <DateTime, List<MovementDetails>>{};
    for (final d in list) {
      final date = d.movement.date;
      groups
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(d);
    }

    var index = 0;
    return [
      for (final entry in groups.entries)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child:
                AppCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dayLabel(entry.key),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                formatSigned(
                                  entry.value.fold(
                                    0,
                                    (s, d) => s + d.signedAmount,
                                  ),
                                  currency,
                                ),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          for (final d in entry.value)
                            Dismissible(
                              key: ValueKey(d.movement.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _delete(d),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.expense,
                                ),
                              ),
                              child: MovementTile(
                                d,
                                onTap: () => openMovement(context, d),
                              ),
                            ),
                        ],
                      ),
                    )
                    .animate(delay: (40 * index++).clamp(0, 400).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.06, curve: Curves.easeOutCubic),
          ),
        ),
    ];
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.cents,
    required this.color,
    this.signed = false,
  });

  final String label;
  final int cents;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              cents,
              signed: signed,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtering});

  final bool filtering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          PiggyMascot(
            mood: filtering ? MascotMood.neutral : MascotMood.sleeping,
            size: 120,
          ),
          const SizedBox(height: 12),
          Text(
            filtering
                ? 'Nada coincide con tu búsqueda'
                : 'Sin movimientos este mes',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            filtering
                ? 'Prueba con otro filtro.'
                : 'Toca el botón + para registrar uno.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
