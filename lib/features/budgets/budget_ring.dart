import 'dart:math';

import 'package:flutter/material.dart';

/// Color según cuánto del presupuesto se ha usado.
Color budgetColor(double ratio) {
  if (ratio >= 1) return const Color(0xFFFA5252);
  if (ratio >= 0.75) return const Color(0xFFFFA94D);
  return const Color(0xFF12B886);
}

/// Anillo de progreso que se llena con animación; el color pasa de verde a
/// naranja y rojo según el porcentaje usado.
class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.ratio,
    this.size = 150,
    this.thickness = 14,
    this.child,
  });

  final double ratio;
  final double size;
  final double thickness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(v, track, thickness),
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.track, this.thickness);

  final double value;
  final Color track;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - thickness / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = track,
    );
    final sweep = 2 * pi * value.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    final color = budgetColor(value);
    canvas.drawArc(
      rect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect),
    );
    // Punto brillante en la punta del arco.
    final tip =
        center + Offset(cos(-pi / 2 + sweep), sin(-pi / 2 + sweep)) * radius;
    canvas.drawCircle(tip, thickness * 0.28, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track;
}
