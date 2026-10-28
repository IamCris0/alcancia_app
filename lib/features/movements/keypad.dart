import 'package:flutter/material.dart';

import '../../core/ui/pressable.dart';

/// Teclado numérico propio: teclas grandes con rebote y vibración.
/// Mantener presionado ⌫ borra todo.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Pressable(
                      scale: 0.9,
                      semanticLabel: key == '⌫' ? 'Borrar' : key,
                      onTap: () => key == '⌫' ? onBackspace() : onKey(key),
                      onLongPress: key == '⌫' ? onClear : null,
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow
                              .withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: key == '⌫'
                            ? const Icon(Icons.backspace_outlined, size: 22)
                            : Text(key, style: theme.textTheme.headlineSmall),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
