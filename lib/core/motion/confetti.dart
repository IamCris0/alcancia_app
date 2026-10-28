import 'dart:math';

import 'package:flutter/material.dart';

const confettiColors = [
  Color(0xFFFFC233),
  Color(0xFF7C5CFF),
  Color(0xFFFF7EB3),
  Color(0xFF12B886),
  Color(0xFF4DABF7),
];

/// Explosión de confeti con física simple (velocidad inicial + gravedad +
/// giro). Se reproduce una vez al montarse.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.count = 46,
    this.origin = const Alignment(0, -0.1),
    this.colors = confettiColors,
    this.duration = const Duration(milliseconds: 1800),
  });

  final int count;
  final Alignment origin;
  final List<Color> colors;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _pieces = List.generate(widget.count, (i) {
      final angle = -pi / 2 + (rng.nextDouble() - 0.5) * 2.4;
      final speed = 380 + rng.nextDouble() * 520;
      return _Piece(
        velocity: Offset(cos(angle), sin(angle)) * speed,
        spin: (rng.nextDouble() - 0.5) * 14,
        size: 6 + rng.nextDouble() * 6,
        color: widget.colors[i % widget.colors.length],
        round: rng.nextDouble() < 0.3,
        wobble: rng.nextDouble() * 2 * pi,
      );
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_c, _pieces, widget.origin, widget.duration),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.velocity,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
    required this.wobble,
  });

  final Offset velocity;
  final double spin;
  final double size;
  final Color color;
  final bool round;
  final double wobble;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.pieces, this.origin, this.duration)
    : super(repaint: anim);

  final Animation<double> anim;
  final List<_Piece> pieces;
  final Alignment origin;
  final Duration duration;

  static const _gravity = 1100.0;
  static const _drag = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * duration.inMilliseconds / 1000;
    final start = origin.alongSize(size);
    final alpha = (1 - Curves.easeIn.transform(anim.value)).clamp(0.0, 1.0);
    for (final p in pieces) {
      // Arrastre del aire: la velocidad horizontal decae con el tiempo.
      final damp = (1 - exp(-_drag * t * 3)) / (_drag * 3);
      final pos =
          start +
          Offset(p.velocity.dx * damp, p.velocity.dy * damp) +
          Offset(sin(t * 6 + p.wobble) * 8, 0.5 * _gravity * t * t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        // Escala en X simula el giro 3D del papel.
        canvas.scale(cos(t * 9 + p.wobble).abs() * 0.8 + 0.2, 1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
