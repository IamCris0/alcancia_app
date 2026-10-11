import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/gamification_queries.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import '../gamification/celebration_dialog.dart';
import '../gamification/gamification_providers.dart';

/// Crear o editar un presupuesto. Si [existing] es nulo se elige la
/// categoría (o "General").
Future<void> showBudgetForm(
  BuildContext context, {
  BudgetStatus? existing,
  required Set<int?> taken,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BudgetForm(existing: existing, taken: taken),
  );
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({this.existing, required this.taken});

  final BudgetStatus? existing;

  /// Categorías que ya tienen presupuesto (null = el general).
  final Set<int?> taken;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.limit / 100).toStringAsFixed(2),
  );
  late int? _categoryId = widget.existing?.categoryId;
  late bool _general =
      widget.existing?.isGeneral ?? !widget.taken.contains(null);
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cents = parseMoneyToCents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Escribe un monto mayor a cero');
      return;
    }
    if (!_general && _categoryId == null) {
      setState(() => _error = 'Elige una categoría');
      return;
    }
    final db = ref.read(databaseProvider);
    await db.upsertBudget(_general ? null : _categoryId, cents);
    final result = await ref.read(gamificationServiceProvider).onBudgetSaved();
    if (!mounted) return;
    final nav = Navigator.of(context);
    final rootContext = nav.context;
    nav.pop();
    if (result.hasCelebrations && rootContext.mounted) {
      await showCelebrations(rootContext, result);
    }
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteBudget(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.existing != null;
    final categories =
        ref.watch(categoriesProvider(CategoryKind.expense)).value ??
        const <Category>[];
    final available = [
      for (final c in categories)
        if (!widget.taken.contains(c.id) || c.id == widget.existing?.categoryId)
          c,
    ];
    final symbol = currencyByCode(ref.watch(currencyProvider)).symbol;

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
              editing ? 'Editar presupuesto' : 'Nuevo presupuesto',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!editing) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!widget.taken.contains(null))
                    ChoiceChip(
                      avatar: const Icon(Icons.public_rounded, size: 18),
                      label: const Text('General del mes'),
                      selected: _general,
                      onSelected: (_) => setState(() => _general = true),
                    ),
                  for (final c in available)
                    ChoiceChip(
                      avatar: IconBadge(
                        iconKey: c.iconKey,
                        color: Color(c.colorValue),
                        size: 24,
                      ),
                      label: Text(c.name),
                      selected: !_general && _categoryId == c.id,
                      onSelected: (_) => setState(() {
                        _general = false;
                        _categoryId = c.id;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _amount,
              autofocus: editing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Límite mensual',
                prefixText: '$symbol ',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (editing)
              TextButton(
                onPressed: _delete,
                child: const Text('Eliminar presupuesto'),
              ),
          ],
        ),
      ),
    );
  }
}
