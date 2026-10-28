import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo "aurora": manchas de color difusas que se desplazan lentamente
/// siguiendo curvas de Lissajous. Se detiene si el sistema pide reducir
/// movimiento.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.colors,
    this.opacity = 0.55,
    this.duration = const Duration(seconds: 18),
  });

  final List<Color> colors;
  final double opacity;
  final Duration duration;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AuroraPainter(_c, widget.colors, widget.opacity),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.anim, this.colors, this.opacity) : super(repaint: anim);

  final Animation<double> anim;
  final List<Color> colors;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * 2 * pi;
    final r = max(size.width, size.height) * 0.65;
    for (final (i, color) in colors.indexed) {
      final center = Offset(
        size.width * (0.5 + 0.42 * sin(t + i * 2.1)),
        size.height * (0.5 + 0.45 * cos(t * 0.8 + i * 1.3)),
      );
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.colors != colors || old.opacity != opacity;
}
