import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/database/planning_queries.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';

Future<void> showGoalForm(BuildContext context, {Goal? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GoalForm(existing: existing),
    );

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _target = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.target / 100).toStringAsFixed(2),
  );
  late Color _color = widget.existing == null
      ? colorPalette[4]
      : Color(widget.existing!.colorValue);
  late String _icon = widget.existing?.iconKey ?? 'travel';
  late DateTime? _deadline = widget.existing?.deadline;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = parseMoneyToCents(_target.text);
    if (name.isEmpty) return setState(() => _error = 'Ponle un nombre');
    if (target == null || target <= 0) {
      return setState(() => _error = 'Escribe cuánto quieres ahorrar');
    }
    final db = ref.read(databaseProvider);
    await db.saveGoal(
      GoalsCompanion(
        id: widget.existing == null
            ? const Value.absent()
            : Value(widget.existing!.id),
        name: Value(name),
        target: Value(target),
        iconKey: Value(_icon),
        colorValue: Value(_color.toARGB32()),
        deadline: Value(_deadline),
      ),
    );
    final result = await ref.read(gamificationServiceProvider).evaluate();
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    if (result.hasCelebrations && nav.context.mounted) {
      await showCelebrations(nav.context, result);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar meta?'),
        content: const Text('Se borrarán también sus aportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteGoal(widget.existing!.id);
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
              editing ? 'Editar meta' : 'Nueva meta de ahorro',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: '¿Para qué ahorras?',
                hintText: 'Viaje, celular, fondo de emergencia…',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monto objetivo',
                prefixText: '$symbol ',
              ),
            ),
            const SizedBox(height: 12),
            ActionChip(
              avatar: const Icon(Icons.event_rounded, size: 18),
              label: Text(
                _deadline == null
                    ? 'Fecha límite (opcional)'
                    : 'Para el ${DateFormat('d MMM yyyy', 'es').format(_deadline!)}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime(now.year, now.month + 3),
                  firstDate: now,
                  lastDate: DateTime(now.year + 20),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 16),
            ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 16),
            IconPicker(
              selected: _icon,
              color: _color,
              onChanged: (k) => setState(() => _icon = k),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (editing)
              TextButton(
                onPressed: _delete,
                child: const Text('Eliminar meta'),
              ),
          ],
        ),
      ),
    );
  }
}
