import 'dart:math';

import 'package:flutter/material.dart';

/// La pantalla aparece desde un círculo que crece en el centro, con un
/// leve zoom hacia atrás: transición de apertura de la app.
class IrisReveal extends StatelessWidget {
  const IrisReveal({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final maxR =
            sqrt(size.width * size.width + size.height * size.height) / 2;
        return ClipPath(
          clipper: _Circle(maxR * curved.value),
          child: Transform.scale(
            scale: 1.08 - 0.08 * curved.value,
            child: child,
          ),
        );
      },
    );
  }
}

class _Circle extends CustomClipper<Path> {
  _Circle(this.radius);

  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
    );

  @override
  bool shouldReclip(_Circle old) => old.radius != radius;
}
