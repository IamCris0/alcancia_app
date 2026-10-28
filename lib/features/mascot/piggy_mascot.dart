import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MascotMood { happy, neutral, worried, sleeping }

/// La mascota de Alcancía: un cerdito dibujado en vectores (sin assets), que
/// respira, parpadea y, al tocarlo, salta y se traga una moneda.
class PiggyMascot extends StatefulWidget {
  const PiggyMascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.onTap,
  });

  final MascotMood mood;
  final double size;
  final VoidCallback? onTap;

  @override
  State<PiggyMascot> createState() => _PiggyMascotState();
}

class _PiggyMascotState extends State<PiggyMascot>
    with TickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  late final _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  final _rng = Random();
  Timer? _blinkTimer;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2200 + _rng.nextInt(2800)),
      () async {
        if (!mounted) return;
        if (widget.mood != MascotMood.sleeping && !_reduceMotion) {
          await _blink.forward();
          if (!mounted) return;
          await _blink.reverse();
        }
        if (mounted) _scheduleBlink();
      },
    );
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (!_reduceMotion) _tap.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mascota Alcancía',
      button: true,
      child: GestureDetector(
        onTap: _onTap,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _blink, _tap]),
            builder: (context, _) => CustomPaint(
              painter: _PiggyPainter(
                mood: widget.mood,
                breath: Curves.easeInOut.transform(_breath.value),
                blink: _blink.value,
                tap: _tap.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PiggyPainter extends CustomPainter {
  _PiggyPainter({
    required this.mood,
    required this.breath,
    required this.blink,
    required this.tap,
  });

  final MascotMood mood;
  final double breath;
  final double blink;
  final double tap;

  static const _ink = Color(0xFF3D2C3E);
  static const _skin = Color(0xFFFFB3C7);
  static const _skinDark = Color(0xFFFF8FAB);
  static const _skinDeep = Color(0xFFE0708F);
  static const _snout = Color(0xFFFFA5BE);
  static const _nostril = Color(0xFFB84D6E);
  static const _gold = Color(0xFFFFC233);
  static const _goldDark = Color(0xFFE09B00);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);

    // Salto al tocar: sube en la primera mitad y aterriza con rebote.
    final jumpT = (tap / 0.45).clamp(0.0, 1.0);
    final jump = tap == 0 ? 0.0 : -sin(jumpT * pi) * 9;
    final landing = tap > 0.45 && tap < 0.6
        ? sin((tap - 0.45) / 0.15 * pi)
        : 0.0;

    // Sombra: se encoge cuando la mascota está en el aire.
    final shadowW = 54 * (1 + jump / 30);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 94), width: shadowW, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Moneda que cae a la ranura (se dibuja antes del cuerpo: queda "dentro").
    if (tap > 0.3 && tap < 0.8) {
      final t = Curves.easeIn.transform((tap - 0.3) / 0.5);
      _drawCoin(canvas, Offset(50, -2 + t * 34));
    }

    canvas.save();
    canvas.translate(50, 90 + jump);
    canvas.scale(
      1 - breath * 0.012 + landing * 0.06,
      1 + breath * 0.028 - landing * 0.07,
    );
    canvas.translate(-50, -90);

    _drawTail(canvas);
    _drawLegs(canvas);
    _drawEars(canvas);
    _drawBody(canvas);
    _drawFace(canvas);

    canvas.restore();

    if (mood == MascotMood.sleeping) _drawZzz(canvas);
    if (tap > 0.75) _drawSparkles(canvas, (tap - 0.75) / 0.25);
  }

  void _drawCoin(Canvas canvas, Offset c) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 15, height: 15),
      Paint()..color = _goldDark,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, -0.6), width: 12.5, height: 12.5),
      Paint()..color = _gold,
    );
    canvas.drawLine(
      c.translate(0, -3.5),
      c.translate(0, 3),
      Paint()
        ..color = _goldDark
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTail(Canvas canvas) {
    canvas.save();
    canvas.translate(85, 56);
    canvas.rotate(sin(breath * pi) * 0.25);
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(9, -6, 11, 6, 4, 6)
      ..cubicTo(-1, 6, 2, -2, 8, -1);
    canvas.drawPath(
      path,
      Paint()
        ..color = _skinDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawLegs(Canvas canvas) {
    for (final (x, back) in [
      (31.0, false),
      (43.0, true),
      (57.0, true),
      (69.0, false),
    ]) {
      final rect = RRect.fromLTRBR(
        x - 5,
        76,
        x + 5,
        back ? 89 : 91,
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = back ? _skinDark : _skin);
      canvas.drawRRect(
        RRect.fromLTRBR(
          x - 5,
          back ? 86 : 88,
          x + 5,
          back ? 89 : 91,
          const Radius.circular(3),
        ),
        Paint()..color = _skinDeep,
      );
    }
  }

  void _drawEars(Canvas canvas) {
    Path ear(bool right) {
      double x(double v) => right ? 100 - v : v;
      return Path()
        ..moveTo(x(25), 37)
        ..quadraticBezierTo(x(20), 15, x(33), 19)
        ..quadraticBezierTo(x(40), 23, x(43), 30)
        ..close();
    }

    Path inner(bool right) {
      double x(double v) => right ? 100 - v : v;
      return Path()
        ..moveTo(x(28), 33)
        ..quadraticBezierTo(x(25), 20, x(33), 23)
        ..quadraticBezierTo(x(37), 26, x(39), 30)
        ..close();
    }

    final outer = Paint()..color = _skinDark;
    final innerPaint = Paint()..color = _skin;
    for (final right in [false, true]) {
      canvas.drawPath(ear(right), outer);
      canvas.drawPath(inner(right), innerPaint);
    }
  }

  void _drawBody(Canvas canvas) {
    const body = Rect.fromLTWH(13, 25, 74, 62);
    canvas.drawOval(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC9D8), _skinDark],
        ).createShader(body),
    );
    // Brillo superior para dar volumen.
    canvas.drawOval(
      const Rect.fromLTWH(26, 31, 30, 13),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    // Ranura de la alcancía.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(50, 29.5), width: 15, height: 3.4),
        const Radius.circular(1.7),
      ),
      Paint()..color = _nostril,
    );
  }

  void _drawFace(Canvas canvas) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    // Mejillas.
    final blush = Paint()
      ..color = const Color(0xFFFF6B8B).withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(30, 61), 5, blush);
    canvas.drawCircle(const Offset(70, 61), 5, blush);

    // Ojos.
    for (final ex in [39.0, 61.0]) {
      final c = Offset(ex, 50);
      if (mood == MascotMood.sleeping) {
        final p = Path()
          ..moveTo(ex - 4, 50)
          ..quadraticBezierTo(ex, 53.5, ex + 4, 50);
        canvas.drawPath(p, ink);
        continue;
      }
      final open = 1 - blink;
      if (open < 0.15) {
        canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), ink);
        continue;
      }
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 8.4, height: 9.6 * open),
        Paint()..color = _ink,
      );
      if (open > 0.5) {
        canvas.drawCircle(
          c.translate(1.4, -1.8),
          1.5,
          Paint()..color = Colors.white,
        );
      }
    }

    // Cejas preocupadas.
    if (mood == MascotMood.worried) {
      canvas.drawLine(const Offset(34, 43.5), const Offset(43, 40.5), ink);
      canvas.drawLine(const Offset(57, 40.5), const Offset(66, 43.5), ink);
    }

    // Hocico.
    const snout = Rect.fromLTWH(39.5, 55, 21, 15);
    canvas.drawOval(snout, Paint()..color = _snout);
    canvas.drawOval(
      snout,
      Paint()
        ..color = _skinDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final nostril = Paint()..color = _nostril;
    for (final nx in [46.5, 53.5]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(nx, 62.5), width: 3.2, height: 4.6),
        nostril,
      );
    }

    // Boca.
    switch (mood) {
      case MascotMood.happy:
        canvas.drawPath(
          Path()
            ..moveTo(44, 73)
            ..quadraticBezierTo(50, 78.5, 56, 73),
          ink,
        );
      case MascotMood.neutral:
        canvas.drawLine(const Offset(46, 74), const Offset(54, 74), ink);
      case MascotMood.worried:
        canvas.drawPath(
          Path()
            ..moveTo(45, 76)
            ..quadraticBezierTo(50, 72, 55, 76),
          ink,
        );
      case MascotMood.sleeping:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 74), width: 3.6, height: 4),
          Paint()..color = _ink,
        );
    }
  }

  void _drawZzz(Canvas canvas) {
    for (final (i, size) in [(0, 9.0), (1, 12.0)]) {
      final t = (breath + i * 0.5) % 1;
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: _nostril.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(76 + i * 7 + t * 4, 22 - i * 8 - t * 8));
    }
  }

  void _drawSparkles(Canvas canvas, double t) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 1 - t)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.45;
      final from = Offset(
        50 + cos(a) * (10 + t * 10),
        22 + sin(a) * (10 + t * 10),
      );
      final to = Offset(
        50 + cos(a) * (14 + t * 14),
        22 + sin(a) * (14 + t * 14),
      );
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_PiggyPainter old) =>
      old.mood != mood ||
      old.breath != breath ||
      old.blink != blink ||
      old.tap != tap;
}
