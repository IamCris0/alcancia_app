import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/icons.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui/pressable.dart';
import '../../core/widgets/pickers.dart';
import '../mascot/mascot_providers.dart';
import 'amount_input.dart';
import 'keypad.dart';
import 'movement_type_ui.dart';
import 'success_overlay.dart';

/// Crear o editar un movimiento. Pantalla completa con teclado propio.
class AddMovementPage extends ConsumerStatefulWidget {
  const AddMovementPage({super.key, this.existing});

  final MovementDetails? existing;

  @override
  ConsumerState<AddMovementPage> createState() => _AddMovementPageState();
}

class _AddMovementPageState extends ConsumerState<AddMovementPage> {
  late MovementType _type;
  late final ValueNotifier<AmountInput> _amount;
  int? _categoryId;
  int? _accountId;
  int? _toAccountId;
  late DateTime _date;
  late final TextEditingController _note;
  String? _error;
  int _shakes = 0;
  bool _saved = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing?.movement;
    _type = m?.type ?? MovementType.expense;
    _amount = ValueNotifier(AmountInput.fromCents(m?.amount ?? 0));
    _categoryId = m?.categoryId;
    _accountId = m?.accountId;
    _toAccountId = m?.toAccountId;
    _date = m?.date ?? DateTime.now();
    _note = TextEditingController(text: m?.note);
  }

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _setType(MovementType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      _error = null;
    });
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _error = message;
      _shakes++;
    });
  }

  Future<void> _save() async {
    final cents = _amount.value.cents;
    if (cents <= 0) return _fail('Escribe un monto');
    if (_accountId == null) return _fail('Elige una cuenta');
    if (_type == MovementType.transfer) {
      if (_toAccountId == null) return _fail('Elige la cuenta destino');
      if (_toAccountId == _accountId) {
        return _fail('Las cuentas deben ser distintas');
      }
    } else if (_categoryId == null) {
      return _fail('Elige una categoría');
    }

    final note = _note.text.trim();
    final transfer = _type == MovementType.transfer;
    final changes = MovementsCompanion(
      type: Value(_type),
      amount: Value(cents),
      accountId: Value(_accountId!),
      toAccountId: Value(transfer ? _toAccountId : null),
      categoryId: Value(transfer ? null : _categoryId),
      note: Value(note.isEmpty ? null : note),
      date: Value(_date),
    );
    final db = ref.read(databaseProvider);
    if (_editing) {
      await db.updateMovement(widget.existing!.movement.id, changes);
    } else {
      await db.addMovement(changes);
    }

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    // La mascota del inicio también reaccionará al volver.
    ref.read(mascotEventProvider.notifier).bump();
    setState(() => _saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(databaseProvider)
        .deleteMovement(widget.existing!.movement.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _type.color;
    final accounts = [
      for (final a
          in ref.watch(accountsWithBalanceProvider).value ??
              const <AccountWithBalance>[])
        a.account,
    ];
    final kind = _type.categoryKind;
    final categories = kind == null
        ? const <Category>[]
        : ref.watch(categoriesProvider(kind)).value ?? const <Category>[];

    // Valores por defecto en cuanto llegan los datos.
    _accountId ??= accounts.isEmpty ? null : accounts.first.id;
    if (_type == MovementType.transfer && _toAccountId == null) {
      final other = accounts.where((a) => a.id != _accountId);
      _toAccountId = other.isEmpty ? null : other.first.id;
    }
    if (kind != null && _categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }

    final symbol = currencyByCode(ref.watch(currencyProvider)).symbol;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con un halo del color del tipo, que cambia suavemente.
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.9),
                radius: 1.3,
                colors: [
                  color.withValues(alpha: 0.22),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                const SizedBox(height: 8),
                _TypeSwitch(selected: _type, onChanged: _setType),
                _amountDisplay(context, symbol, color),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (_type == MovementType.transfer) ...[
                        _label(context, 'Desde'),
                        _AccountChips(
                          accounts: accounts,
                          selected: _accountId,
                          color: color,
                          onSelected: (id) => setState(() => _accountId = id),
                        ),
                        _label(context, 'Hacia'),
                        _AccountChips(
                          accounts: accounts,
                          selected: _toAccountId,
                          color: color,
                          onSelected: (id) => setState(() => _toAccountId = id),
                        ),
                      ] else ...[
                        _label(context, 'Categoría'),
                        _CategoryGrid(
                          categories: categories,
                          selected: _categoryId,
                          onSelected: (id) => setState(() => _categoryId = id),
                        ),
                        _label(context, 'Cuenta'),
                        _AccountChips(
                          accounts: accounts,
                          selected: _accountId,
                          color: color,
                          onSelected: (id) => setState(() => _accountId = id),
                        ),
                      ],
                      _label(context, 'Fecha y nota'),
                      _DateChips(
                        date: _date,
                        color: color,
                        onChanged: (d) => setState(() => _date = d),
                        onPick: _pickDate,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _note,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Nota (opcional)',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      // El monto vive en un ValueNotifier: teclear solo
                      // reconstruye el número, no toda la pantalla.
                      Keypad(
                        onKey: (k) {
                          _amount.value = _amount.value.press(k);
                          if (_error != null) setState(() => _error = null);
                        },
                        onBackspace: () =>
                            _amount.value = _amount.value.backspace(),
                        onClear: () => _amount.value = const AmountInput(),
                      ),
                      const SizedBox(height: 8),
                      _SaveButton(
                        color: color,
                        label: _editing ? 'Guardar cambios' : 'Guardar',
                        onPressed: _saved ? null : _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_saved) SuccessOverlay(type: _type, color: color),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              _editing ? 'Editar movimiento' : 'Nuevo movimiento',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_editing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _amountDisplay(BuildContext context, String symbol, Color color) {
    final theme = Theme.of(context);
    Widget display = SizedBox(
      height: 72,
      child: ValueListenableBuilder<AmountInput>(
        valueListenable: _amount,
        builder: (context, amount, _) => FittedBox(
          fit: BoxFit.scaleDown,
          child:
              Text(
                    amount.display(symbol),
                    maxLines: 1,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: amount.isEmpty
                          ? theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            )
                          : color,
                    ),
                  )
                  .animate(key: ValueKey(amount.text))
                  .scaleXY(
                    begin: 0.94,
                    end: 1,
                    duration: 160.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
      ),
    );
    if (_shakes > 0) {
      display = display
          .animate(key: ValueKey('shake$_shakes'))
          .shakeX(hz: 5, amount: 6, duration: 400.ms);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          display,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _error ?? ' ',
              key: ValueKey(_error),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// Selector de tipo con una "píldora" que se desliza bajo la opción activa.
class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({required this.selected, required this.onChanged});

  final MovementType selected;
  final ValueChanged<MovementType> onChanged;

  static const _order = [
    MovementType.expense,
    MovementType.income,
    MovementType.transfer,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = _order.indexOf(selected);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(23),
          boxShadow: softShadow(context),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              alignment: Alignment(-1 + index * 1.0, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  decoration: BoxDecoration(
                    color: selected.color,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                        color: selected.color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final t in _order)
                  Expanded(
                    child: Pressable(
                      onTap: () => onChanged(t),
                      semanticLabel: t.label,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: t == selected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          child: Text(t.label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, c) in categories.indexed)
          Pressable(
                onTap: () => onSelected(c.id),
                semanticLabel: c.name,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                  decoration: BoxDecoration(
                    color: c.id == selected
                        ? Color(c.colorValue)
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: c.id == selected
                        ? [
                            BoxShadow(
                              color: Color(c.colorValue)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      c.id == selected
                          ? Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconFor(c.iconKey),
                                size: 17,
                                color: Colors.white,
                              ),
                            )
                          : IconBadge(
                              iconKey: c.iconKey,
                              color: Color(c.colorValue),
                              size: 30,
                            ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: c.id == selected ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: (25 * i).ms)
              .fadeIn(duration: 220.ms)
              .scaleXY(begin: 0.9, curve: Curves.easeOutBack),
      ],
    );
  }
}

class _AccountChips extends StatelessWidget {
  const _AccountChips({
    required this.accounts,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final List<Account> accounts;
  final int? selected;
  final Color color;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (accounts.isEmpty) {
      return Text('Crea una cuenta primero', style: theme.textTheme.bodyMedium);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in accounts)
          Pressable(
            onTap: () => onSelected(a.id),
            semanticLabel: a.name,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: a.id == selected
                    ? color.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: a.id == selected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconFor(a.iconKey),
                    size: 18,
                    color: Color(a.colorValue),
                  ),
                  const SizedBox(width: 8),
                  Text(a.name, style: theme.textTheme.labelLarge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DateChips extends StatelessWidget {
  const _DateChips({
    required this.date,
    required this.color,
    required this.onChanged,
    required this.onPick,
  });

  final DateTime date;
  final Color color;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isToday = day == today;
    final isYesterday = day == yesterday;

    DateTime withTime(DateTime d) =>
        DateTime(d.year, d.month, d.day, date.hour, date.minute);

    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Hoy'),
          selected: isToday,
          selectedColor: color.withValues(alpha: 0.18),
          onSelected: (_) => onChanged(withTime(today)),
        ),
        ChoiceChip(
          label: const Text('Ayer'),
          selected: isYesterday,
          selectedColor: color.withValues(alpha: 0.18),
          onSelected: (_) => onChanged(withTime(yesterday)),
        ),
        ChoiceChip(
          avatar: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(
            isToday || isYesterday
                ? 'Otra fecha'
                : DateFormat('d MMM yyyy', 'es').format(date),
          ),
          selected: !isToday && !isYesterday,
          selectedColor: color.withValues(alpha: 0.18),
          onSelected: (_) => onPick(),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
