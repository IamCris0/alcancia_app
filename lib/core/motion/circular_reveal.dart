import 'dart:math';

import 'package:flutter/material.dart';

/// Transición donde la nueva pantalla se revela como un círculo que crece
/// desde [center] (p. ej. el botón "+"), con un leve zoom de profundidad.
Route<T> circularRevealRoute<T>(Widget page, {required Offset center}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      final size = MediaQuery.sizeOf(context);
      final maxRadius = [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ].map((c) => (c - center).distance).reduce(max);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => ClipPath(
          clipper: _CircleClipper(center, maxRadius * curved.value),
          child: Transform.scale(
            scale: 0.94 + 0.06 * curved.value,
            alignment: Alignment(
              center.dx / size.width * 2 - 1,
              center.dy / size.height * 2 - 1,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.radius != radius || old.center != center;
}
