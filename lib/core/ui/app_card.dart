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
    this.radius = 26,
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
    final r = BorderRadius.circular(radius);
    final base = color ?? scheme.surfaceContainerLow;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        // Superficie con un leve degradado tintado por la marca: da volumen
        // sin verse "plana".
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base,
                Color.alphaBlend(
                  AppColors.brand.withValues(alpha: dark ? 0.06 : 0.035),
                  base,
                ),
              ],
            ),
        borderRadius: r,
        boxShadow: softShadow(context),
        border: Border.all(
          color: gradient != null
              ? Colors.white.withValues(alpha: 0.22)
              : dark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      // Brillo superior (efecto vidrio) en las tarjetas de color.
      foregroundDecoration: gradient == null
          ? null
          : BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: const Alignment(0.2, 0.4),
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
      child: child,
    );
    return onTap == null
        ? card
        : Pressable(onTap: onTap, scale: 0.97, child: card);
  }
}
