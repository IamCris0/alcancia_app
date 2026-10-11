import 'package:flutter/material.dart';

import '../icons.dart';

const colorPalette = <Color>[
  Color(0xFF2EC4A0),
  Color(0xFFFF6B6B),
  Color(0xFFFFC233),
  Color(0xFF7C5CFF),
  Color(0xFF4DABF7),
  Color(0xFFFF8FAB),
  Color(0xFF51CF66),
  Color(0xFFFF922B),
  Color(0xFF845EF7),
  Color(0xFF868E96),
];

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colorPalette)
          Semantics(
            button: true,
            selected: c.toARGB32() == selected.toARGB32(),
            label: 'Color',
            child: GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.toARGB32() == selected.toARGB32()
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in appIcons.entries)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(entry.key),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.key == selected
                    ? color.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.key == selected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                entry.value,
                color: entry.key == selected ? color : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Círculo con el icono sobre un fondo suave del mismo color.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 44,
  });

  final String iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(iconFor(iconKey), color: color, size: size * 0.55),
    );
  }
}
