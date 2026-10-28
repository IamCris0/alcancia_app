import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../money.dart';
import '../providers.dart';

/// Hoja inferior para pedir un monto. Devuelve centavos o null si se cancela.
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  required String action,
  required Color color,
  int? max,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _AmountSheet(title: title, action: action, color: color, max: max),
  );
}

class _AmountSheet extends ConsumerStatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.action,
    required this.color,
    this.max,
  });

  final String title;
  final String action;
  final Color color;
  final int? max;

  @override
  ConsumerState<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends ConsumerState<_AmountSheet> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final cents = parseMoneyToCents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Escribe un monto mayor a cero');
      return;
    }
    if (widget.max != null && cents > widget.max!) {
      setState(
        () => _error =
            'Máximo ${formatMoney(widget.max!, ref.read(currencyProvider))}',
      );
      return;
    }
    Navigator.pop(context, cents);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = currencyByCode(ref.watch(currencyProvider)).symbol;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              prefixText: '$symbol ',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.color),
            onPressed: _submit,
            child: Text(widget.action),
          ),
        ],
      ),
    );
  }
}
