import 'dart:math';

import 'package:flutter/material.dart';

/// Círculo que se llena de "líquido" con dos olas en movimiento. El nivel
/// sube animado hasta [progress] y las burbujas suben cuando hay líquido.
class LiquidProgress extends StatefulWidget {
  const LiquidProgress({
    super.key,
    required this.progress,
    required this.color,
    this.size = 120,
    this.child,
  });

  final double progress;
  final Color color;
  final double size;
  final Widget? child;

  @override
  State<LiquidProgress> createState() => _LiquidProgressState();
}

class _LiquidProgressState extends State<LiquidProgress>
    with TickerProviderStateMixin {
  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final _level = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late Animation<double> _levelAnim;

  @override
  void initState() {
    super.initState();
    _levelAnim = Tween(
      begin: 0.0,
      end: _clamped,
    ).animate(CurvedAnimation(parent: _level, curve: Curves.easeOutCubic));
    _level.forward();
  }

  double get _clamped => widget.progress.clamp(0.0, 1.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
      _level.value = 1;
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void didUpdateWidget(LiquidProgress old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _levelAnim = Tween(
        begin: _levelAnim.value,
        end: _clamped,
      ).animate(CurvedAnimation(parent: _level, curve: Curves.easeOutBack));
      _level.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _LiquidPainter(
            wave: _wave,
            level: _level,
            levelValue: () => _levelAnim.value,
            color: widget.color,
            track: track,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.wave,
    required Animation<double> level,
    required this.levelValue,
    required this.color,
    required this.track,
  }) : super(repaint: Listenable.merge([wave, level]));

  final Animation<double> wave;
  final double Function() levelValue;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final circle = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    canvas.drawPath(circle, Paint()..color = track);

    canvas.save();
    canvas.clipPath(circle);
    final level = levelValue();
    final t = wave.value * 2 * pi;
    final baseY = size.height * (1 - level);
    // A 0 % o 100 % la ola se aplana.
    final amp = size.height * 0.045 * sin(level * pi).clamp(0.25, 1.0);

    Path wavePath(double phase, double ampScale) {
      final p = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y =
            baseY + sin(x / size.width * 2 * pi + t + phase) * amp * ampScale;
        p.lineTo(x, y);
      }
      return p
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(
      wavePath(pi, 0.8),
      Paint()..color = color.withValues(alpha: 0.45),
    );
    canvas.drawPath(
      wavePath(0, 1),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ).createShader(Rect.fromLTWH(0, baseY, size.width, size.height)),
    );

    // Burbujas que suben dentro del líquido.
    if (level > 0.08) {
      final bubble = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (var i = 0; i < 5; i++) {
        final p = (wave.value + i / 5) % 1;
        final x = size.width * (0.2 + 0.15 * i) + sin(t * 2 + i) * 3;
        final y = size.height - p * (size.height - baseY);
        canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), bubble);
      }
    }
    canvas.restore();

    // Brillo de vidrio.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.78),
      -pi * 0.85,
      pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.color != color || old.track != track;
}
