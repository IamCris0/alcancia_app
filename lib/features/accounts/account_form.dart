import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/widgets/pickers.dart';
import 'account_type_ui.dart';

Future<void> showAccountForm(BuildContext context, {Account? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AccountForm(existing: existing),
  );
}

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.existing});

  final Account? existing;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _balance = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.initialBalance / 100).toStringAsFixed(2),
  );
  late AccountType _type = widget.existing?.type ?? AccountType.cash;
  late Color _color = widget.existing == null
      ? colorPalette.first
      : Color(widget.existing!.colorValue);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre');
      return;
    }
    final raw = _balance.text.trim();
    final cents = raw.isEmpty ? 0 : parseMoneyToCents(raw);
    if (cents == null) {
      setState(() => _error = 'Saldo inválido');
      return;
    }
    final db = ref.read(databaseProvider);
    final existing = widget.existing;
    if (existing == null) {
      await db.addAccount(
        AccountsCompanion.insert(
          name: name,
          type: _type,
          colorValue: _color.toARGB32(),
          iconKey: _type.iconKey,
          initialBalance: Value(cents),
        ),
      );
    } else {
      await db.updateAccount(
        existing.copyWith(
          name: name,
          type: _type,
          colorValue: _color.toARGB32(),
          iconKey: _type.iconKey,
          initialBalance: cents,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive() async {
    await ref.read(databaseProvider).archiveAccount(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              editing ? 'Editar cuenta' : 'Nueva cuenta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in AccountType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: t == _type,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Saldo inicial'),
            ),
            const SizedBox(height: 16),
            ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
            if (editing)
              TextButton(
                onPressed: _archive,
                child: const Text('Archivar cuenta'),
              ),
          ],
        ),
      ),
    );
  }
}
