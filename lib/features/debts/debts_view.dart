import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/planning_queries.dart';
import '../../core/money.dart';
import '../../core/motion/skeleton.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/amount_sheet.dart';
import '../../core/ui/animated_money.dart';
import '../../core/ui/app_card.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../plans/plans_providers.dart';

Color debtColor(DebtKind k) =>
    k == DebtKind.theyOwe ? AppColors.income : AppColors.expense;

class DebtsView extends ConsumerWidget {
  const DebtsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);
    return debts.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        int pending(DebtKind k) => list
            .where((d) => d.debt.kind == k && !d.settled)
            .fold(0, (s, d) => s + d.remaining);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: _Total(
                    label: 'Te deben',
                    cents: pending(DebtKind.theyOwe),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Total(
                    label: 'Debes',
                    cents: pending(DebtKind.iOwe),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => showDebtForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva deuda'),
              ),
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Anota lo que prestaste o lo que debes, y ve marcando '
                  'los abonos hasta saldarlo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final (i, d) in list.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DebtCard(status: d),
              ).animate(delay: (60 * i).ms).fadeIn().slideX(begin: 0.06),
          ],
        );
      },
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.cents, required this.color});

  final String label;
  final int cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoney(
              cents,
              style: theme.textTheme.titleLarge?.copyWith(
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

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.status});

  final DebtStatus status;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final cents = await showAmountSheet(
      context,
      title: 'Abono de ${status.debt.person}',
      action: 'Registrar abono',
      color: debtColor(status.debt.kind),
      max: status.remaining,
    );
    if (cents == null) return;
    final settled = await ref
        .read(databaseProvider)
        .payDebt(status.debt.id, cents, DateTime.now());
    final result = await ref
        .read(gamificationServiceProvider)
        .evaluate(
          milestone: settled
              ? '¡Deuda con ${status.debt.person} saldada!'
              : null,
        );
    if (result.hasCelebrations && context.mounted) {
      await showCelebrations(context, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final d = status.debt;
    final color = debtColor(d.kind);
    final overdue =
        !status.settled &&
        d.dueDate != null &&
        d.dueDate!.isBefore(DateTime.now());

    return Opacity(
      opacity: status.settled ? 0.6 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => showDebtForm(context, existing: d),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Text(
                    d.person.characters.first.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.person, style: theme.textTheme.titleSmall),
                      Text(
                        status.settled
                            ? 'Saldada ✓'
                            : d.kind == DebtKind.theyOwe
                            ? 'Te debe'
                            : 'Le debes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(status.remaining, currency),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (d.dueDate != null)
                      Text(
                        '${overdue ? 'Venció' : 'Vence'} '
                        '${DateFormat('d MMM', 'es').format(d.dueDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: overdue ? AppColors.expense : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: status.progress.clamp(0, 1)),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
                if (!status.settled) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _pay(context, ref),
                    child: const Text('Abonar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDebtForm(BuildContext context, {Debt? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DebtForm(existing: existing),
    );

class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({this.existing});

  final Debt? existing;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  late final _person = TextEditingController(text: widget.existing?.person);
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.amount / 100).toStringAsFixed(2),
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late DebtKind _kind = widget.existing?.kind ?? DebtKind.theyOwe;
  late DateTime? _due = widget.existing?.dueDate;
  String? _error;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final person = _person.text.trim();
    final cents = parseMoneyToCents(_amount.text);
    if (person.isEmpty) return setState(() => _error = 'Escribe un nombre');
    if (cents == null || cents <= 0) {
      return setState(() => _error = 'Escribe un monto mayor a cero');
    }
    final note = _note.text.trim();
    await ref
        .read(databaseProvider)
        .saveDebt(
          DebtsCompanion(
            id: widget.existing == null
                ? const Value.absent()
                : Value(widget.existing!.id),
            person: Value(person),
            kind: Value(_kind),
            amount: Value(cents),
            note: Value(note.isEmpty ? null : note),
            dueDate: Value(_due),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteDebt(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = currencyByCode(ref.watch(currencyProvider)).symbol;
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar deuda' : 'Nueva deuda',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<DebtKind>(
              segments: const [
                ButtonSegment(
                  value: DebtKind.theyOwe,
                  label: Text('Me deben'),
                  icon: Icon(Icons.call_received_rounded),
                ),
                ButtonSegment(
                  value: DebtKind.iOwe,
                  label: Text('Yo debo'),
                  icon: Icon(Icons.call_made_rounded),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _person,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: '¿Quién?'),
            ),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '$symbol ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  _due == null
                      ? 'Fecha de pago (opcional)'
                      : 'Para el ${DateFormat('d MMM yyyy', 'es').format(_due!)}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _due ?? now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) setState(() => _due = picked);
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (editing)
              TextButton(onPressed: _delete, child: const Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
