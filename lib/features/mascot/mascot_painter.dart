import 'dart:math';

import 'package:flutter/material.dart';

import 'mascot_species.dart';

/// Estado animado que el widget le pasa al pintor en cada frame.
class MascotPose {
  const MascotPose({
    this.breath = 0,
    this.blink = 0,
    this.look = Offset.zero,
    this.twitch = 0,
    this.tap = 0,
    this.hop = 0,
    this.spin = 0,
    this.love = 0,
    this.pet = 0,
    this.yawn = 0,
    this.stretch = 0,
    this.coin = 0,
  });

  final double breath;
  final double blink;
  final Offset look;
  final double twitch;
  final double tap;
  final double hop;
  final double spin;
  final double love;
  final double pet;
  final double yawn;
  final double stretch;
  final double coin;
}

/// Dibuja la mascota en un lienzo de 100×100 que se escala al tamaño real.
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.species,
    required this.mood,
    required this.pose,
    this.stage = 1,
    this.accessory = MascotAccessory.none,
  }) : s = species.style;

  final MascotSpecies species;
  final MascotMood mood;
  final MascotPose pose;
  final int stage;
  final MascotAccessory accessory;
  final SpeciesStyle s;

  static const _ink = Color(0xFF3D2C3E);
  static const _gold = Color(0xFFFFC233);
  static const _goldDark = Color(0xFFE09B00);

  double get _twitchAngle =>
      sin(pose.twitch * pi * 3) * (1 - pose.twitch) * 0.35;

  bool get _happyEyes => mood == MascotMood.celebrating || pose.pet > 0.5;

  bool get _closedEyes =>
      mood == MascotMood.sleeping || (pose.yawn > 0.15 && pose.yawn < 0.85);

  Color get _elementColor => switch (species) {
    MascotSpecies.spark => const Color(0xFFFFE066),
    MascotSpecies.sprout => const Color(0xFF8CE99A),
    MascotSpecies.ember => const Color(0xFFFF922B),
    MascotSpecies.aqua => const Color(0xFF66D9E8),
    _ => _gold,
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);

    // Saltos: toque, celebración y giro.
    final t = pose.tap;
    final jumpT = (t / 0.45).clamp(0.0, 1.0);
    final jump = t == 0 ? 0.0 : -sin(jumpT * pi) * 9;
    final hopY = -sin(pose.hop * pi).abs() * 7;
    final spinJump = -sin(pose.spin * pi) * 12;
    final landing = t > 0.45 && t < 0.6 ? sin((t - 0.45) / 0.15 * pi) : 0.0;
    final lift = jump + hopY + spinJump;

    if (stage >= 3) _aura(canvas);

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 94),
        width: 54 * (1 + lift / 30),
        height: 6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    if (pose.coin > 0 && pose.coin < 0.7) {
      final c = Curves.easeIn.transform(pose.coin / 0.7);
      _coin(canvas, Offset(50, -2 + c * 34));
    }

    canvas.save();
    // Etapas: crece un poco al evolucionar.
    final grow = switch (stage) {
      1 => 0.9,
      2 => 0.96,
      _ => 1.0,
    };
    canvas.translate(50, 90 + lift);
    canvas.scale(grow, grow);
    // Respiración, aterrizaje y estiramiento (squash & stretch).
    final stretchY = sin(pose.stretch * pi) * 0.10;
    canvas.scale(
      1 - pose.breath * 0.012 + landing * 0.06 - stretchY * 0.4,
      1 + pose.breath * 0.028 - landing * 0.07 + stretchY,
    );
    // Giro completo (doble toque) y meneo al acariciar.
    final wiggle = pose.pet * sin(pose.breath * pi * 6) * 0.05;
    canvas.translate(0, -34);
    canvas.rotate(Curves.easeInOutBack.transform(pose.spin) * 2 * pi + wiggle);
    canvas.translate(-50, -56);

    _tail(canvas);
    _legs(canvas);
    _backFeatures(canvas);
    _ears(canvas);
    _body(canvas);
    _frontFeatures(canvas);
    _face(canvas);
    _accessory(canvas);

    canvas.restore();

    if (mood == MascotMood.sleeping || pose.yawn > 0.6) _zzz(canvas);
    if (mood == MascotMood.celebrating) _stars(canvas);
    if (pose.tap > 0.55) _sparkles(canvas, (pose.tap - 0.55) / 0.45);
    if (pose.love > 0) _hearts(canvas, pose.love);
    if (pose.pet > 0.3) _hearts(canvas, (pose.breath + 0.3) % 1, few: true);
  }

  // ---------- Efectos ----------

  void _aura(Canvas canvas) {
    final r = 46 + pose.breath * 3;
    const center = Offset(50, 56);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _elementColor.withValues(alpha: 0.45),
            _elementColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    // Partículas del elemento orbitando.
    final p = Paint()..color = _elementColor.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      final a = pose.breath * pi + i * 2 * pi / 3;
      canvas.drawCircle(center + Offset(cos(a) * 44, sin(a) * 20), 2.2, p);
    }
  }

  void _coin(Canvas canvas, Offset c) {
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

  Path _heart(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy + r * 0.9)
    ..cubicTo(
      c.dx - r * 1.6,
      c.dy - r * 0.2,
      c.dx - r * 0.6,
      c.dy - r * 1.4,
      c.dx,
      c.dy - r * 0.4,
    )
    ..cubicTo(
      c.dx + r * 0.6,
      c.dy - r * 1.4,
      c.dx + r * 1.6,
      c.dy - r * 0.2,
      c.dx,
      c.dy + r * 0.9,
    )
    ..close();

  void _hearts(Canvas canvas, double t, {bool few = false}) {
    final n = few ? 2 : 4;
    for (var i = 0; i < n; i++) {
      final p = ((t + i / n) % 1);
      final x = 50 + (i - (n - 1) / 2) * 14 + sin(p * pi * 3 + i) * 4;
      final y = 30 - p * 30;
      canvas.drawPath(
        _heart(Offset(x, y), 3.4 + (i % 2)),
        Paint()
          ..color = const Color(0xFFFF4D6D).withValues(alpha: (1 - p) * 0.95),
      );
    }
  }

  // ---------- Cuerpo ----------

  void _tail(Canvas canvas) {
    final wag = sin(pose.breath * pi) * 0.25 + _twitchAngle * 0.6;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (species) {
      case MascotSpecies.pig:
        canvas.save();
        canvas.translate(85, 56);
        canvas.rotate(wag);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..cubicTo(9, -6, 11, 6, 4, 6)
            ..cubicTo(-1, 6, 2, -2, 8, -1),
          stroke
            ..color = s.bodyDark
            ..strokeWidth = 2.6,
        );
        canvas.restore();
      case MascotSpecies.cat:
        canvas.save();
        canvas.translate(82, 74);
        canvas.rotate(wag * 0.8 - 0.1);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..cubicTo(16, -2, 18, -24, 9, -32),
          stroke
            ..color = s.bodyDark
            ..strokeWidth = 6,
        );
        canvas.restore();
      case MascotSpecies.bunny:
        canvas.drawCircle(
          Offset(86 + wag * 2, 68),
          7,
          Paint()..color = s.bodyLight,
        );
      case MascotSpecies.panda:
        canvas.drawCircle(Offset(86 + wag * 2, 67), 5, Paint()..color = s.limb);
      case MascotSpecies.spark:
        // Cola en forma de rayo.
        canvas.save();
        canvas.translate(82, 70);
        canvas.rotate(wag * 0.7 - 0.2);
        final bolt = Path()
          ..moveTo(0, 0)
          ..lineTo(10, -10)
          ..lineTo(6, -12)
          ..lineTo(16, -26)
          ..lineTo(9, -16)
          ..lineTo(13, -14)
          ..lineTo(3, -3)
          ..close();
        canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFD43B));
        canvas.drawPath(
          bolt,
          stroke
            ..color = const Color(0xFFF59F00)
            ..strokeWidth = 1,
        );
        canvas.restore();
      case MascotSpecies.sprout:
        canvas.save();
        canvas.translate(84, 70);
        canvas.rotate(wag - 0.6);
        _leaf(canvas, Offset.zero, 14, s.bodyDark);
        canvas.restore();
      case MascotSpecies.ember:
        canvas.save();
        canvas.translate(83, 72);
        canvas.rotate(wag * 0.6 - 0.5);
        canvas.drawLine(
          Offset.zero,
          const Offset(0, -12),
          stroke
            ..color = s.bodyDark
            ..strokeWidth = 5,
        );
        _flame(canvas, const Offset(0, -14), 7 + stage * 1.5);
        canvas.restore();
      case MascotSpecies.aqua:
        canvas.save();
        canvas.translate(84, 68);
        canvas.rotate(wag);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(12, -12, 14, -2)
            ..quadraticBezierTo(12, 8, 0, 6)
            ..close(),
          Paint()..color = s.earOuter,
        );
        canvas.restore();
    }
  }

  void _leaf(Canvas canvas, Offset base, double len, Color color) {
    final p = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + len * 0.5,
        base.dy - len * 0.6,
        base.dx,
        base.dy - len,
      )
      ..quadraticBezierTo(
        base.dx - len * 0.5,
        base.dy - len * 0.6,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawLine(
      base,
      base.translate(0, -len * 0.85),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 0.8,
    );
  }

  void _flame(Canvas canvas, Offset c, double h) {
    final flicker = sin(pose.breath * pi * 8) * 0.12;
    Path flame(double scale) => Path()
      ..moveTo(c.dx, c.dy + h * 0.35 * scale)
      ..quadraticBezierTo(
        c.dx - h * 0.55 * scale,
        c.dy,
        c.dx,
        c.dy - h * (1 + flicker) * scale,
      )
      ..quadraticBezierTo(
        c.dx + h * 0.55 * scale,
        c.dy,
        c.dx,
        c.dy + h * 0.35 * scale,
      )
      ..close();
    canvas.drawPath(flame(1), Paint()..color = const Color(0xFFFF6B3D));
    canvas.drawPath(flame(0.6), Paint()..color = const Color(0xFFFFD43B));
  }

  void _legs(Canvas canvas) {
    for (final (x, back) in [
      (31.0, false),
      (43.0, true),
      (57.0, true),
      (69.0, false),
    ]) {
      final bottom = back ? 89.0 : 91.0;
      canvas.drawRRect(
        RRect.fromLTRBR(x - 5, 76, x + 5, bottom, const Radius.circular(4)),
        Paint()..color = back ? s.limbDark : s.limb,
      );
      if (species == MascotSpecies.pig) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            x - 5,
            bottom - 3,
            x + 5,
            bottom,
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFE0708F),
        );
      }
    }
  }

  /// Rasgos detrás del cuerpo (crestas, branquias, alas de etapa 3).
  void _backFeatures(Canvas canvas) {
    if (stage >= 3 && species.style.isCreature) {
      // Alitas pequeñas en la etapa final.
      final flap = sin(pose.breath * pi * 2) * 0.15;
      for (final dir in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(50 + dir * 30, 50);
        canvas.rotate(dir * (0.5 + flap));
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(dir * 18, -14, dir * 22, 2)
            ..quadraticBezierTo(dir * 12, 0, 0, 6)
            ..close(),
          Paint()..color = _elementColor.withValues(alpha: 0.85),
        );
        canvas.restore();
      }
    }
    if (species == MascotSpecies.aqua) {
      // Aletas laterales tipo oreja.
      for (final dir in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(50 + dir * 34, 44);
        canvas.rotate(dir * (0.4 + _twitchAngle));
        final len = 10.0 + stage * 3;
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              dir * len,
              -len * 0.8,
              dir * len * 0.9,
              len * 0.3,
            )
            ..close(),
          Paint()..color = s.earOuter,
        );
        canvas.restore();
      }
    }
  }

  void _ears(Canvas canvas) {
    final outer = Paint()..color = s.earOuter;
    final inner = Paint()..color = s.earInner;
    for (final right in [false, true]) {
      double x(double v) => right ? 100 - v : v;
      final angle = right ? _twitchAngle : 0.0;
      canvas.save();
      switch (species) {
        case MascotSpecies.pig:
          _rotateAround(canvas, Offset(x(34), 30), angle);
          // Orejas un poco caídas: más animal, menos alcancía.
          canvas.drawPath(
            Path()
              ..moveTo(x(24), 36)
              ..quadraticBezierTo(x(18), 18, x(32), 20)
              ..quadraticBezierTo(x(40), 24, x(42), 31)
              ..close(),
            outer,
          );
          canvas.drawPath(
            Path()
              ..moveTo(x(27), 32)
              ..quadraticBezierTo(x(24), 22, x(32), 24)
              ..quadraticBezierTo(x(36), 27, x(38), 30)
              ..close(),
            inner,
          );
        case MascotSpecies.cat:
          _rotateAround(canvas, Offset(x(32), 34), angle);
          canvas.drawPath(
            Path()
              ..moveTo(x(20), 42)
              ..lineTo(x(24), 12)
              ..quadraticBezierTo(x(26), 10, x(29), 13)
              ..lineTo(x(45), 29)
              ..close(),
            outer,
          );
          canvas.drawPath(
            Path()
              ..moveTo(x(25), 36)
              ..lineTo(x(27), 19)
              ..lineTo(x(39), 30)
              ..close(),
            inner,
          );
        case MascotSpecies.bunny:
          _rotateAround(canvas, Offset(x(38), 30), angle * 1.4);
          canvas.save();
          canvas.translate(x(38), 18);
          canvas.rotate(right ? 0.18 : -0.18);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 14, height: 36),
            outer,
          );
          canvas.drawOval(
            Rect.fromCenter(center: const Offset(0, 2), width: 7, height: 26),
            inner,
          );
          canvas.restore();
        case MascotSpecies.panda:
          _rotateAround(canvas, Offset(x(25), 31), angle);
          canvas.drawCircle(Offset(x(25), 31), 9.5, outer);
          canvas.drawCircle(Offset(x(25), 31), 5, inner);
        case MascotSpecies.spark:
          // Orejas largas y afiladas con punta amarilla.
          _rotateAround(canvas, Offset(x(32), 32), angle);
          final tip = 6.0 + stage * 3;
          final ear = Path()
            ..moveTo(x(22), 38)
            ..lineTo(x(18), 10 - tip)
            ..lineTo(x(42), 28)
            ..close();
          canvas.drawPath(ear, outer);
          canvas.save();
          canvas.clipPath(ear);
          canvas.drawRect(
            Rect.fromLTRB(0, -20, 100, 14 - tip),
            Paint()..color = const Color(0xFFFFD43B),
          );
          canvas.restore();
        case MascotSpecies.sprout:
          _rotateAround(canvas, Offset(x(28), 34), angle);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x(24), 32), width: 14, height: 11),
            outer,
          );
        case MascotSpecies.ember:
          // Cuernitos.
          _rotateAround(canvas, Offset(x(34), 28), angle * 0.5);
          canvas.drawPath(
            Path()
              ..moveTo(x(30), 31)
              ..quadraticBezierTo(x(24), 18 - stage * 2, x(30), 12 - stage * 2)
              ..quadraticBezierTo(x(34), 20, x(39), 28)
              ..close(),
            Paint()..color = const Color(0xFF862E2E),
          );
        case MascotSpecies.aqua:
          break;
      }
      canvas.restore();
    }
  }

  void _rotateAround(Canvas canvas, Offset pivot, double angle) {
    if (angle == 0) return;
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _body(Canvas canvas) {
    const body = Rect.fromLTWH(13, 25, 74, 62);
    canvas.drawOval(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.bodyLight, s.bodyDark],
        ).createShader(body),
    );
    // Panza más clara: da volumen y se ve más "animal".
    canvas.drawOval(
      const Rect.fromLTWH(30, 62, 40, 22),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawOval(
      const Rect.fromLTWH(26, 31, 30, 13),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    if (species == MascotSpecies.cat) {
      final stripe = Paint()
        ..color = const Color(0xFFE8590C).withValues(alpha: 0.45)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(45, 30), const Offset(45.5, 36), stripe);
      canvas.drawLine(const Offset(50, 28.5), const Offset(50, 36), stripe);
      canvas.drawLine(const Offset(55, 30), const Offset(54.5, 36), stripe);
    }
  }

  /// Rasgos sobre el cuerpo que cambian con la evolución.
  void _frontFeatures(Canvas canvas) {
    switch (species) {
      case MascotSpecies.spark:
        // Cresta en zigzag que crece por etapa.
        final h = 6.0 + stage * 3;
        final crest = Path()..moveTo(42, 28);
        for (var i = 0; i < 2 + stage; i++) {
          final x = 42 + i * 16 / (1 + stage);
          crest
            ..lineTo(x + 3, 28 - h)
            ..lineTo(x + 6, 27);
        }
        crest
          ..lineTo(58, 28)
          ..close();
        canvas.drawPath(crest, Paint()..color = const Color(0xFFFFD43B));
      case MascotSpecies.sprout:
        final sway = sin(pose.breath * pi) * 0.12;
        canvas.save();
        canvas.translate(50, 27);
        canvas.rotate(sway);
        _leaf(canvas, Offset.zero, 12.0 + stage * 2, const Color(0xFF2F9E44));
        if (stage >= 2) {
          canvas.save();
          canvas.rotate(-0.8);
          _leaf(canvas, Offset.zero, 10.0 + stage, const Color(0xFF51CF66));
          canvas.restore();
          canvas.save();
          canvas.rotate(0.8);
          _leaf(canvas, Offset.zero, 10.0 + stage, const Color(0xFF51CF66));
          canvas.restore();
        }
        if (stage >= 3) {
          // Flor en la punta.
          for (var i = 0; i < 5; i++) {
            final a = i * 2 * pi / 5 + pose.breath;
            canvas.drawCircle(
              Offset(cos(a) * 4, -18 + sin(a) * 4),
              3,
              Paint()..color = const Color(0xFFFF8FAB),
            );
          }
          canvas.drawCircle(
            const Offset(0, -18),
            2.4,
            Paint()..color = const Color(0xFFFFD43B),
          );
        }
        canvas.restore();
      case MascotSpecies.ember:
        if (stage >= 2) _flame(canvas, const Offset(50, 25), 6 + stage * 2);
      case MascotSpecies.aqua:
        // Cresta de gota.
        final h = 8.0 + stage * 3;
        canvas.drawPath(
          Path()
            ..moveTo(44, 28)
            ..quadraticBezierTo(46, 26 - h, 50, 26 - h - 3)
            ..quadraticBezierTo(54, 26 - h, 56, 28)
            ..close(),
          Paint()..color = s.earOuter,
        );
        canvas.drawCircle(
          Offset(48.5, 26 - h * 0.5),
          1.6,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      default:
        break;
    }
  }

  double get _mouthY => switch (species) {
    MascotSpecies.pig => 73,
    MascotSpecies.cat => 67,
    MascotSpecies.bunny => 69,
    MascotSpecies.panda => 70,
    _ => 66,
  };

  void _face(Canvas canvas) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final lightInk = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;
    final panda = species == MascotSpecies.panda;

    // Mejillas: se encienden al acariciar.
    final blush = Paint()
      ..color = s.blush.withValues(alpha: 0.35 + pose.pet * 0.35);
    canvas.drawCircle(const Offset(30, 61), 5 + pose.pet, blush);
    canvas.drawCircle(const Offset(70, 61), 5 + pose.pet, blush);
    if (species == MascotSpecies.spark) {
      // Chispitas en las mejillas.
      final spark = Paint()
        ..color = const Color(0xFFFFD43B)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (final cx in [30.0, 70.0]) {
        canvas.drawLine(Offset(cx - 2, 59), Offset(cx + 1, 62), spark);
        canvas.drawLine(Offset(cx + 1, 62), Offset(cx - 1, 64), spark);
      }
    }

    if (panda) {
      final patch = Paint()..color = s.limb;
      for (final (cx, a) in [(38.5, 0.4), (61.5, -0.4)]) {
        canvas.save();
        canvas.translate(cx, 51);
        canvas.rotate(a);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 13, height: 17),
          patch,
        );
        canvas.restore();
      }
    }

    final eyeShift = Offset(pose.look.dx * 1.8, pose.look.dy * 1.4);
    for (final ex in [39.0, 61.0]) {
      final c = Offset(ex, 50) + eyeShift;
      final line = panda ? lightInk : ink;
      if (_closedEyes) {
        canvas.drawPath(
          Path()
            ..moveTo(ex - 4, 50)
            ..quadraticBezierTo(ex, 53.5, ex + 4, 50),
          line,
        );
        continue;
      }
      if (_happyEyes) {
        canvas.drawPath(
          Path()
            ..moveTo(ex - 4, 51.5)
            ..quadraticBezierTo(ex, 45.5, ex + 4, 51.5),
          line,
        );
        continue;
      }
      final open = 1 - pose.blink;
      if (open < 0.15) {
        canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), line);
        continue;
      }
      if (panda) {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 7.6, height: 8.4 * open),
          Paint()..color = Colors.white,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c + eyeShift * 0.4,
            width: 4.6,
            height: 5.2 * open,
          ),
          Paint()..color = _ink,
        );
      } else {
        // Ojos más grandes en criaturas (estilo "monstruito").
        final big = species.style.isCreature ? 1.15 : 1.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: c,
            width: 8.4 * big,
            height: 9.6 * big * open,
          ),
          Paint()..color = _ink,
        );
      }
      if (open > 0.5) {
        canvas.drawCircle(
          c.translate(1.4, -1.8),
          1.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          c.translate(-1.4, 1.6),
          0.8,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }

    if (mood == MascotMood.worried && pose.pet < 0.5) {
      canvas.drawLine(const Offset(34, 43.5), const Offset(43, 40.5), ink);
      canvas.drawLine(const Offset(57, 40.5), const Offset(66, 43.5), ink);
    }

    _muzzle(canvas);
    _mouth(canvas, ink);
  }

  void _muzzle(Canvas canvas) {
    switch (species) {
      case MascotSpecies.pig:
        const snout = Rect.fromLTWH(39.5, 55, 21, 15);
        canvas.drawOval(snout, Paint()..color = s.muzzle);
        canvas.drawOval(
          snout,
          Paint()
            ..color = const Color(0xFFE0708F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        for (final nx in [46.5, 53.5]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(nx, 62.5), width: 3.2, height: 4.6),
            Paint()..color = s.nose,
          );
        }
      case MascotSpecies.cat || MascotSpecies.bunny:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 64), width: 20, height: 12),
          Paint()..color = s.muzzle.withValues(alpha: 0.85),
        );
        if (species == MascotSpecies.cat) {
          canvas.drawPath(
            Path()
              ..moveTo(46.5, 59.5)
              ..lineTo(53.5, 59.5)
              ..lineTo(50, 63.5)
              ..close(),
            Paint()..color = s.nose,
          );
        } else {
          canvas.drawOval(
            Rect.fromCenter(
              center: const Offset(50, 61),
              width: 5.6,
              height: 4,
            ),
            Paint()..color = s.nose,
          );
        }
        final whisker = Paint()
          ..color = _ink.withValues(alpha: 0.45)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        final w = sin(pose.breath * pi * 2) * 0.6;
        for (final dir in [-1.0, 1.0]) {
          canvas.drawLine(
            Offset(50 + dir * 9, 63),
            Offset(50 + dir * 23, 60 + w),
            whisker,
          );
          canvas.drawLine(
            Offset(50 + dir * 9, 65),
            Offset(50 + dir * 23, 67 - w),
            whisker,
          );
        }
      case MascotSpecies.panda:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 64), width: 21, height: 14),
          Paint()..color = s.muzzle,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(50, 61),
            width: 7.5,
            height: 4.6,
          ),
          Paint()..color = s.nose,
        );
      default:
        // Criaturas: naricita pequeña.
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 60), width: 4, height: 2.6),
          Paint()..color = s.nose,
        );
    }
  }

  void _mouth(Canvas canvas, Paint ink) {
    final y = _mouthY;
    // Bostezo: boca ovalada que se abre y se cierra.
    if (pose.yawn > 0) {
      final open = sin(pose.yawn * pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(50, y + 2),
          width: 6 + open * 3,
          height: 2 + open * 8,
        ),
        Paint()..color = _ink,
      );
      return;
    }
    final feline =
        species == MascotSpecies.cat || species == MascotSpecies.bunny;
    final celebrating = mood == MascotMood.celebrating || pose.love > 0;
    if (celebrating) {
      final mouth = Path()
        ..moveTo(43.5, y - 1)
        ..quadraticBezierTo(50, y + 11, 56.5, y - 1)
        ..close();
      canvas.drawPath(mouth, Paint()..color = _ink);
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(50, y + 6), width: 9, height: 6),
        Paint()..color = const Color(0xFFFF6B8B),
      );
      canvas.restore();
      return;
    }
    switch (mood) {
      case MascotMood.happy || MascotMood.neutral when feline:
        canvas.drawPath(
          Path()
            ..moveTo(45, y - 1)
            ..quadraticBezierTo(47.5, y + 2.5, 50, y - 1)
            ..quadraticBezierTo(52.5, y + 2.5, 55, y - 1),
          ink,
        );
        if (species == MascotSpecies.bunny) _teeth(canvas, y);
      case MascotMood.happy:
        canvas.drawPath(
          Path()
            ..moveTo(44, y)
            ..quadraticBezierTo(50, y + 5.5, 56, y),
          ink,
        );
        // Colmillito para las criaturas.
        if (species.style.isCreature) {
          canvas.drawPath(
            Path()
              ..moveTo(52, y + 1.6)
              ..lineTo(53.6, y + 4)
              ..lineTo(54.4, y + 1.2)
              ..close(),
            Paint()..color = Colors.white,
          );
        }
      case MascotMood.neutral:
        canvas.drawLine(Offset(46, y + 1), Offset(54, y + 1), ink);
      case MascotMood.worried:
        canvas.drawPath(
          Path()
            ..moveTo(45, y + 3)
            ..quadraticBezierTo(50, y - 1, 55, y + 3),
          ink,
        );
      case MascotMood.sleeping:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(50, y + 1), width: 3.6, height: 4),
          Paint()..color = _ink,
        );
      case MascotMood.celebrating:
        break;
    }
  }

  void _teeth(Canvas canvas, double y) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(47.8, y + 0.2, 4.4, 4.2),
      const Radius.circular(1),
    );
    canvas.drawRRect(r, Paint()..color = Colors.white);
    canvas.drawRRect(
      r,
      Paint()
        ..color = _ink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  // ---------- Accesorios ----------

  void _accessory(Canvas canvas) {
    switch (accessory) {
      case MascotAccessory.none:
        return;
      case MascotAccessory.bow:
        const c = Offset(64, 27);
        final wing = Paint()..color = const Color(0xFFFF4D6D);
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..quadraticBezierTo(
                c.dx + dir * 4,
                c.dy - 9,
                c.dx + dir * 9,
                c.dy - 5,
              )
              ..lineTo(c.dx + dir * 9, c.dy + 5)
              ..quadraticBezierTo(c.dx + dir * 4, c.dy + 9, c.dx, c.dy)
              ..close(),
            wing,
          );
        }
        canvas.drawCircle(c, 2.8, Paint()..color = const Color(0xFFC9184A));
      case MascotAccessory.flower:
        const c = Offset(33, 27);
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5;
          canvas.drawCircle(
            c + Offset(cos(a) * 4.2, sin(a) * 4.2),
            3.4,
            Paint()..color = const Color(0xFFF783AC),
          );
        }
        canvas.drawCircle(c, 2.8, Paint()..color = const Color(0xFFFFD43B));
      case MascotAccessory.glasses:
        final frame = Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        for (final ex in [39.0, 61.0]) {
          canvas.drawCircle(
            Offset(ex, 50),
            7,
            Paint()..color = Colors.white.withValues(alpha: 0.18),
          );
          canvas.drawCircle(Offset(ex, 50), 7, frame);
        }
        canvas.drawLine(const Offset(46, 49), const Offset(54, 49), frame);
      case MascotAccessory.scarf:
        final red = Paint()..color = const Color(0xFFE03131);
        canvas.drawRRect(
          RRect.fromLTRBR(24, 74, 76, 81, const Radius.circular(4)),
          red,
        );
        canvas.save();
        canvas.translate(63, 79);
        canvas.rotate(sin(pose.breath * pi) * 0.1);
        canvas.drawRRect(
          RRect.fromLTRBR(-3, 0, 4, 13, const Radius.circular(2)),
          red,
        );
        canvas.restore();
        final stripe = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1.2;
        for (var x = 30.0; x < 74; x += 8) {
          canvas.drawLine(Offset(x, 74), Offset(x + 3, 81), stripe);
        }
      case MascotAccessory.partyHat:
        final hat = Path()
          ..moveTo(40, 30)
          ..lineTo(60, 30)
          ..lineTo(52, 3)
          ..close();
        canvas.drawPath(hat, Paint()..color = const Color(0xFF7C5CFF));
        canvas.save();
        canvas.clipPath(hat);
        final stripe = Paint()
          ..color = const Color(0xFFFFC233)
          ..strokeWidth = 3.5;
        for (final y in [10.0, 19.0, 28.0]) {
          canvas.drawLine(Offset(30, y + 6), Offset(70, y - 4), stripe);
        }
        canvas.restore();
        canvas.drawCircle(
          const Offset(52, 3),
          3.6,
          Paint()..color = const Color(0xFFFF7EB3),
        );
      case MascotAccessory.sunglasses:
        final lens = Paint()..color = const Color(0xFF212529);
        for (final ex in [39.0, 61.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(ex, 50), width: 15, height: 10),
              const Radius.circular(4),
            ),
            lens,
          );
          canvas.drawLine(
            Offset(ex - 4, 47),
            Offset(ex - 1, 47),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.6)
              ..strokeWidth = 1.2,
          );
        }
        canvas.drawLine(
          const Offset(46, 48.5),
          const Offset(54, 48.5),
          Paint()
            ..color = const Color(0xFF212529)
            ..strokeWidth = 2,
        );
      case MascotAccessory.crown:
        final crown = Path()
          ..moveTo(38, 30)
          ..lineTo(37, 16)
          ..lineTo(44, 22)
          ..lineTo(50, 11)
          ..lineTo(56, 22)
          ..lineTo(63, 16)
          ..lineTo(62, 30)
          ..close();
        canvas.drawPath(crown, Paint()..color = _gold);
        canvas.drawPath(
          crown,
          Paint()
            ..color = _goldDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeJoin = StrokeJoin.round,
        );
        for (final (x, y, color) in [
          (44.0, 26.0, const Color(0xFFFA5252)),
          (50.0, 24.5, const Color(0xFF4DABF7)),
          (56.0, 26.0, const Color(0xFF12B886)),
        ]) {
          canvas.drawCircle(Offset(x, y), 1.7, Paint()..color = color);
        }
      case MascotAccessory.wizardHat:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 29), width: 36, height: 7),
          Paint()..color = const Color(0xFF364FC7),
        );
        canvas.drawPath(
          Path()
            ..moveTo(38, 29)
            ..quadraticBezierTo(46, 14, 50, 4)
            ..quadraticBezierTo(60, 2, 66, 8)
            ..quadraticBezierTo(58, 8, 57, 14)
            ..lineTo(62, 29)
            ..close(),
          Paint()..color = const Color(0xFF4263EB),
        );
        for (final (x, y) in [(47.0, 20.0), (55.0, 24.0), (52.0, 13.0)]) {
          canvas.drawPath(_star(Offset(x, y), 2.4), Paint()..color = _gold);
        }
      case MascotAccessory.halo:
        final bob = sin(pose.breath * pi) * 1.5;
        final rect = Rect.fromCenter(
          center: Offset(50, 14 + bob),
          width: 30,
          height: 8,
        );
        canvas.drawOval(
          rect.inflate(2),
          Paint()
            ..color = _gold.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawOval(
          rect,
          Paint()
            ..color = _gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
    }
  }

  void _zzz(Canvas canvas) {
    for (final (i, size) in [(0, 9.0), (1, 12.0)]) {
      final t = (pose.breath + i * 0.5) % 1;
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF8C7AE6)
                .withValues(alpha: (1 - t).clamp(0.0, 1.0)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(76 + i * 7 + t * 4, 22 - i * 8 - t * 8));
    }
  }

  void _stars(Canvas canvas) {
    final paint = Paint()..color = _gold;
    for (var i = 0; i < 4; i++) {
      final a = pose.breath * pi * 0.6 + i * pi / 2;
      final c = Offset(50 + cos(a) * 46, 46 + sin(a) * 30);
      canvas.drawPath(_star(c, 3.4 + (i.isEven ? 1 : 0)), paint);
    }
  }

  Path _star(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.4;
      final a = -pi / 2 + i * pi / 4;
      final pt = c + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _sparkles(Canvas canvas, double t) {
    final paint = Paint()
      ..color = _elementColor.withValues(alpha: 1 - t)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.45;
      canvas.drawLine(
        Offset(50 + cos(a) * (10 + t * 10), 22 + sin(a) * (10 + t * 10)),
        Offset(50 + cos(a) * (14 + t * 14), 22 + sin(a) * (14 + t * 14)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) => true;
}
