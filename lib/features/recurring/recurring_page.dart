import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/planning_queries.dart';
import '../../core/icons.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/ui/app_card.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/streak.dart';
import '../movements/movement_type_ui.dart';
import '../plans/plans_providers.dart';
import 'recurrence.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(recurringsProvider).value ?? const [];
    final currency = ref.watch(currencyProvider);
    final monthly = list
        .where(
          (d) => d.recurring.active && d.recurring.type == MovementType.expense,
        )
        .fold<int>(0, (s, d) {
          final r = d.recurring;
          return s +
              switch (r.frequency) {
                Frequency.weekly => r.amount * 52 ~/ 12,
                Frequency.monthly => r.amount,
                Frequency.yearly => r.amount ~/ 12,
              };
        });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                const BackButton(),
                Expanded(
                  child: Text(
                    'Recurrentes',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => showRecurringForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gastos fijos ≈ ${formatMoney(monthly, currency)} al mes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Agrega tu salario, renta o suscripciones. Pueden '
                  'registrarse solos o recordarte confirmarlos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final (i, d) in list.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RecurringTile(details: d),
              ).animate(delay: (25 * i).ms).fadeIn().slideX(begin: 0.06),
          ],
        ),
      ),
    );
  }
}

class RecurringTile extends ConsumerWidget {
  const RecurringTile({super.key, required this.details});

  final RecurringDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final r = details.recurring;
    final color = r.type.color;
    return Opacity(
      opacity: r.active ? 1 : 0.5,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showRecurringForm(context, existing: r),
        child: Row(
          children: [
            IconBadge(
              iconKey: details.category?.iconKey ?? 'other',
              color: Color(details.category?.colorValue ?? 0xFF868E96),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: theme.textTheme.titleSmall),
                  Text(
                    '${frequencyLabel(r.frequency)} · '
                    '${r.active ? 'próximo ${DateFormat('d MMM', 'es').format(r.nextDate)}' : 'pausado'}',
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
                  formatMoney(r.amount, currency),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: r.type == MovementType.income ? color : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (r.autoRegister)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: color),
                      Text('Automático', style: theme.textTheme.labelSmall),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRecurringForm(BuildContext context, {Recurring? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringForm(existing: existing),
    );

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.existing});

  final Recurring? existing;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.amount / 100).toStringAsFixed(2),
  );
  late MovementType _type = widget.existing?.type ?? MovementType.expense;
  late Frequency _freq = widget.existing?.frequency ?? Frequency.monthly;
  late DateTime _start = widget.existing?.startDate ?? dayOf(DateTime.now());
  late bool _auto = widget.existing?.autoRegister ?? false;
  late bool _active = widget.existing?.active ?? true;
  late int? _accountId = widget.existing?.accountId;
  late int? _categoryId = widget.existing?.categoryId;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final cents = parseMoneyToCents(_amount.text);
    if (name.isEmpty) return setState(() => _error = 'Ponle un nombre');
    if (cents == null || cents <= 0) {
      return setState(() => _error = 'Escribe un monto mayor a cero');
    }
    if (_accountId == null) return setState(() => _error = 'Elige una cuenta');
    if (_categoryId == null) {
      return setState(() => _error = 'Elige una categoría');
    }
    final today = dayOf(DateTime.now());
    final existing = widget.existing;
    // Nuevo: empieza en la fecha elegida. Editado: si cambia el calendario,
    // la próxima es la primera ocurrencia desde hoy.
    final calendarChanged =
        existing == null ||
        existing.startDate != _start ||
        existing.frequency != _freq;
    final next = existing == null
        ? _start
        : calendarChanged
        ? nextAfter(_start, _freq, addDays(today, -1))
        : existing.nextDate;

    final db = ref.read(databaseProvider);
    await db.saveRecurring(
      RecurringsCompanion(
        id: existing == null ? const Value.absent() : Value(existing.id),
        name: Value(name),
        type: Value(_type),
        amount: Value(cents),
        accountId: Value(_accountId!),
        categoryId: Value(_categoryId),
        frequency: Value(_freq),
        startDate: Value(_start),
        nextDate: Value(next),
        autoRegister: Value(_auto),
        active: Value(_active),
      ),
    );
    await ref.read(recurringServiceProvider).processDue();
    final result = await ref.read(gamificationServiceProvider).evaluate();
    if (!mounted) return;
    await syncReminders(ProviderScope.containerOf(context, listen: false));
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    if (result.hasCelebrations && nav.context.mounted) {
      await showCelebrations(nav.context, result);
    }
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteRecurring(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = currencyByCode(ref.watch(currencyProvider)).symbol;
    final accounts = [
      for (final a
          in ref.watch(accountsWithBalanceProvider).value ??
              const <AccountWithBalance>[])
        a.account,
    ];
    _accountId ??= accounts.isEmpty ? null : accounts.first.id;
    final kind = _type == MovementType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final categories =
        ref.watch(categoriesProvider(kind)).value ?? const <Category>[];

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
              widget.existing == null
                  ? 'Nuevo recurrente'
                  : 'Editar recurrente',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.expense,
                  label: Text('Gasto'),
                ),
                ButtonSegment(
                  value: MovementType.income,
                  label: Text('Ingreso'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Netflix, renta, salario…',
              ),
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
            const SizedBox(height: 16),
            SegmentedButton<Frequency>(
              segments: const [
                ButtonSegment(value: Frequency.weekly, label: Text('Semanal')),
                ButtonSegment(value: Frequency.monthly, label: Text('Mensual')),
                ButtonSegment(value: Frequency.yearly, label: Text('Anual')),
              ],
              selected: {_freq},
              onSelectionChanged: (s) => setState(() => _freq = s.first),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  'Desde el ${DateFormat('d MMM yyyy', 'es').format(_start)}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) setState(() => _start = picked);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Cuenta', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in accounts)
                  ChoiceChip(
                    avatar: Icon(iconFor(a.iconKey), size: 18),
                    label: Text(a.name),
                    selected: a.id == _accountId,
                    onSelected: (_) => setState(() => _accountId = a.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Categoría', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    avatar: Icon(
                      iconFor(c.iconKey),
                      size: 18,
                      color: Color(c.colorValue),
                    ),
                    label: Text(c.name),
                    selected: c.id == _categoryId,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _auto,
              onChanged: (v) => setState(() => _auto = v),
              title: const Text('Registrar automáticamente'),
              subtitle: const Text(
                'Si está apagado, te pediré confirmarlo ese día.',
              ),
            ),
            if (widget.existing != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Activo'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (widget.existing != null)
              TextButton(onPressed: _delete, child: const Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
