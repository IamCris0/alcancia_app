import 'package:flutter/material.dart';

import '../theme.dart';
import 'pressable.dart';

/// Tarjeta con esquinas amplias y sombra suave. Si tiene [onTap] se vuelve
/// presionable.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.gradient,
    this.color,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surfaceContainerLow) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softShadow(context),
        border: dark && gradient == null
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: child,
    );
    return onTap == null
        ? card
        : Pressable(onTap: onTap, scale: 0.98, child: card);
  }
}
