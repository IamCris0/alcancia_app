import 'dart:math';

import 'package:flutter/material.dart';

/// Monedas y destellos que suben flotando y ondulando, como partículas de
/// fondo. Ligero: un solo `CustomPainter` con un controlador.
class FloatingCoins extends StatefulWidget {
  const FloatingCoins({
    super.key,
    this.count = 10,
    this.opacity = 0.5,
    this.seed = 3,
  });

  final int count;
  final double opacity;
  final int seed;

  @override
  State<FloatingCoins> createState() => _FloatingCoinsState();
}

class _FloatingCoinsState extends State<FloatingCoins>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    _particles = List.generate(
      widget.count,
      (_) => _Particle(
        x: rng.nextDouble(),
        phase: rng.nextDouble(),
        speed: 0.6 + rng.nextDouble() * 0.9,
        size: 3 + rng.nextDouble() * 5,
        sway: 4 + rng.nextDouble() * 10,
        coin: rng.nextDouble() < 0.55,
      ),
    );
  }

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
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CoinsPainter(_c, _particles, widget.opacity),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
    required this.coin,
  });

  final double x;
  final double phase;
  final double speed;
  final double size;
  final double sway;
  final bool coin;
}

class _CoinsPainter extends CustomPainter {
  _CoinsPainter(this.anim, this.particles, this.opacity) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Particle> particles;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1;
      final y = size.height + 10 - progress * (size.height + 20);
      final x = p.x * size.width + sin((t * 4 + p.phase) * 2 * pi) * p.sway;
      // Aparece al inicio y se desvanece al llegar arriba.
      final fade = sin(progress * pi);
      final alpha = (opacity * fade).clamp(0.0, 1.0);
      if (p.coin) {
        canvas.drawCircle(
          Offset(x, y),
          p.size,
          Paint()..color = const Color(0xFFFFC233).withValues(alpha: alpha),
        );
        canvas.drawCircle(
          Offset(x - p.size * 0.25, y - p.size * 0.25),
          p.size * 0.45,
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.6),
        );
      } else {
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        final r = p.size * 0.8;
        canvas.drawLine(Offset(x - r, y), Offset(x + r, y), paint);
        canvas.drawLine(Offset(x, y - r), Offset(x, y + r), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter old) => false;
}
