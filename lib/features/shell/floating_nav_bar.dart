import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme.dart';
import '../../core/ui/pressable.dart';

class NavItem {
  const NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barra inferior flotante con efecto vidrio. Una sola píldora se desliza
/// (con rebote) hasta la pestaña activa, el icono elegido "salta", y el
/// botón central "+" informa su posición para la transición circular.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.onAdd,
  });

  /// Deben ser 4: dos a cada lado del botón central.
  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Recibe el centro global del botón "+".
  final ValueChanged<Offset> onAdd;

  static const _addWidth = 66.0;
  static const _height = 68.0;
  static const _hPad = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow.withValues(
                  alpha: 0.82,
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final itemW = (c.maxWidth - _addWidth) / 4;
                  double left(int i) =>
                      i < 2 ? i * itemW : _addWidth + i * itemW;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        left: left(selected) + 4,
                        width: itemW - 8,
                        top: 9,
                        bottom: 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final i in [0, 1]) _item(i, itemW),
                          _AddButton(onAdd: onAdd),
                          for (final i in [2, 3]) _item(i, itemW),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, double width) => SizedBox(
    width: width,
    child: _NavButton(
      item: items[i],
      selected: i == selected,
      onTap: () => onSelected(i),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.brand
        : theme.colorScheme.onSurfaceVariant;
    Widget icon = Icon(
      selected ? item.selectedIcon : item.icon,
      color: color,
      size: 24,
    );
    if (selected) {
      // Pequeño salto del icono al quedar seleccionado.
      icon = icon
          .animate(key: ValueKey(item.label))
          .scaleXY(
            begin: 0.6,
            end: 1,
            duration: 420.ms,
            curve: Curves.elasticOut,
          )
          .moveY(begin: 4, end: 0, duration: 300.ms, curve: Curves.easeOut);
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: item.label,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onAdd});

  final ValueChanged<Offset> onAdd;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  int _turns = 0;

  void _tap() {
    final box = context.findRenderObject()! as RenderBox;
    setState(() => _turns++);
    widget.onAdd(box.localToGlobal(box.size.center(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FloatingNavBar._addWidth,
      child: Center(
        child: Pressable(
          onTap: _tap,
          scale: 0.86,
          semanticLabel: 'Nuevo movimiento',
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.fabGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _turns * 0.25,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
