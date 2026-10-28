import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MascotSpecies { pig, cat, bunny, panda }

enum MascotMood { happy, neutral, worried, sleeping, celebrating }

/// Colores y textos de cada especie. Todas comparten el mismo "esqueleto"
/// (cuerpo, ojos, patas) y cambian orejas, hocico, cola y paleta.
class SpeciesStyle {
  const SpeciesStyle({
    required this.label,
    required this.defaultName,
    required this.bodyLight,
    required this.bodyDark,
    required this.limb,
    required this.limbDark,
    required this.earOuter,
    required this.earInner,
    required this.muzzle,
    required this.nose,
    required this.blush,
  });

  final String label;
  final String defaultName;
  final Color bodyLight;
  final Color bodyDark;
  final Color limb;
  final Color limbDark;
  final Color earOuter;
  final Color earInner;
  final Color muzzle;
  final Color nose;
  final Color blush;
}

extension MascotSpeciesStyle on MascotSpecies {
  SpeciesStyle get style => switch (this) {
    MascotSpecies.pig => const SpeciesStyle(
      label: 'Cerdito',
      defaultName: 'Chanchi',
      bodyLight: Color(0xFFFFC9D8),
      bodyDark: Color(0xFFFF8FAB),
      limb: Color(0xFFFFB3C7),
      limbDark: Color(0xFFFF8FAB),
      earOuter: Color(0xFFFF8FAB),
      earInner: Color(0xFFFFB3C7),
      muzzle: Color(0xFFFFA5BE),
      nose: Color(0xFFB84D6E),
      blush: Color(0xFFFF6B8B),
    ),
    MascotSpecies.cat => const SpeciesStyle(
      label: 'Gatito',
      defaultName: 'Michi',
      bodyLight: Color(0xFFFFE0B8),
      bodyDark: Color(0xFFFFA94D),
      limb: Color(0xFFFFC078),
      limbDark: Color(0xFFFFA94D),
      earOuter: Color(0xFFFFA94D),
      earInner: Color(0xFFFFC9D8),
      muzzle: Color(0xFFFFF4E6),
      nose: Color(0xFFFF8FAB),
      blush: Color(0xFFFF8787),
    ),
    MascotSpecies.bunny => const SpeciesStyle(
      label: 'Conejito',
      defaultName: 'Coco',
      bodyLight: Color(0xFFFFFFFF),
      bodyDark: Color(0xFFE5DBFF),
      limb: Color(0xFFF3F0FF),
      limbDark: Color(0xFFD0BFFF),
      earOuter: Color(0xFFEDE7FF),
      earInner: Color(0xFFFFC9DE),
      muzzle: Color(0xFFFFFFFF),
      nose: Color(0xFFFF8FAB),
      blush: Color(0xFFFFA8C5),
    ),
    MascotSpecies.panda => const SpeciesStyle(
      label: 'Panda',
      defaultName: 'Bambú',
      bodyLight: Color(0xFFFFFFFF),
      bodyDark: Color(0xFFDEE2E6),
      limb: Color(0xFF343A40),
      limbDark: Color(0xFF212529),
      earOuter: Color(0xFF343A40),
      earInner: Color(0xFF495057),
      muzzle: Color(0xFFFFFFFF),
      nose: Color(0xFF212529),
      blush: Color(0xFFFFA8A8),
    ),
  };
}

/// Mascota vectorial animada (sin assets): respira, parpadea, mira a los
/// lados, mueve orejas y cola, y al tocarla salta y guarda una moneda.
/// Cambiar [reactKey] dispara esa reacción desde fuera (p. ej. al guardar).
class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    this.species = MascotSpecies.pig,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.reactKey = 0,
    this.onTap,
    this.interactive = true,
  });

  final MascotSpecies species;
  final MascotMood mood;
  final double size;
  final int reactKey;
  final VoidCallback? onTap;
  final bool interactive;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );
  late final _look = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final _twitch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  final _rng = Random();
  Timer? _idle;
  Offset _lookFrom = Offset.zero;
  Offset _lookTo = Offset.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _scheduleIdle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncLoops();
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _syncLoops();
    if (old.reactKey != widget.reactKey) _react();
  }

  void _syncLoops() {
    if (_reduceMotion) {
      _breath.stop();
      _hop.stop();
      return;
    }
    if (!_breath.isAnimating) _breath.repeat(reverse: true);
    if (widget.mood == MascotMood.celebrating) {
      if (!_hop.isAnimating) _hop.repeat();
    } else if (_hop.isAnimating) {
      _hop.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  /// Pequeñas acciones al azar para que la mascota se sienta viva.
  void _scheduleIdle() {
    _idle = Timer(Duration(milliseconds: 1600 + _rng.nextInt(2600)), () async {
      if (!mounted) return;
      if (!_reduceMotion && widget.mood != MascotMood.sleeping) {
        final r = _rng.nextDouble();
        if (r < 0.5) {
          await _doBlink();
        } else if (r < 0.8) {
          _lookFrom = _currentLook;
          _lookTo = _rng.nextDouble() < 0.35
              ? Offset.zero
              : Offset(_rng.nextDouble() * 2 - 1, _rng.nextDouble() - 0.5);
          _look.forward(from: 0);
          if (_rng.nextBool()) await _doBlink();
        } else {
          _twitch.forward(from: 0);
        }
      }
      if (mounted) _scheduleIdle();
    });
  }

  Future<void> _doBlink() async {
    await _blink.forward();
    if (mounted) await _blink.reverse();
  }

  Offset get _currentLook => Offset.lerp(
    _lookFrom,
    _lookTo,
    Curves.easeOutCubic.transform(_look.value),
  )!;

  void _react() {
    if (_reduceMotion) return;
    _tap.forward(from: 0);
    _twitch.forward(from: 0);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _react();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _idle?.cancel();
    for (final c in [_breath, _blink, _look, _twitch, _tap, _hop]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: Listenable.merge([
        _breath,
        _blink,
        _look,
        _twitch,
        _tap,
        _hop,
      ]),
      builder: (context, _) => CustomPaint(
        painter: _MascotPainter(
          species: widget.species,
          mood: widget.mood,
          breath: Curves.easeInOut.transform(_breath.value),
          blink: _blink.value,
          look: _currentLook,
          twitch: _twitch.value,
          tap: _tap.value,
          hop: _hop.value,
        ),
      ),
    );
    return Semantics(
      label: 'Mascota ${widget.species.style.label}',
      button: widget.interactive,
      child: GestureDetector(
        onTap: widget.interactive ? _onTap : null,
        child: RepaintBoundary(
          child: SizedBox.square(dimension: widget.size, child: painter),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.species,
    required this.mood,
    required this.breath,
    required this.blink,
    required this.look,
    required this.twitch,
    required this.tap,
    required this.hop,
  }) : s = species.style;

  final MascotSpecies species;
  final MascotMood mood;
  final double breath;
  final double blink;
  final Offset look;
  final double twitch;
  final double tap;
  final double hop;
  final SpeciesStyle s;

  static const _ink = Color(0xFF3D2C3E);
  static const _gold = Color(0xFFFFC233);
  static const _goldDark = Color(0xFFE09B00);

  /// Oscilación amortiguada para la sacudida de orejas.
  double get _twitchAngle => sin(twitch * pi * 3) * (1 - twitch) * 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);

    final jumpT = (tap / 0.45).clamp(0.0, 1.0);
    final jump = tap == 0 ? 0.0 : -sin(jumpT * pi) * 9;
    final hopY = -sin(hop * pi).abs() * 7;
    final landing = tap > 0.45 && tap < 0.6
        ? sin((tap - 0.45) / 0.15 * pi)
        : 0.0;
    final lift = jump + hopY;

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 94),
        width: 54 * (1 + lift / 30),
        height: 6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    if (tap > 0.3 && tap < 0.8) {
      final t = Curves.easeIn.transform((tap - 0.3) / 0.5);
      _coin(canvas, Offset(50, -2 + t * 34));
    }

    canvas.save();
    canvas.translate(50, 90 + lift);
    canvas.scale(
      1 - breath * 0.012 + landing * 0.06,
      1 + breath * 0.028 - landing * 0.07,
    );
    canvas.translate(-50, -90);

    _tail(canvas);
    _legs(canvas);
    _ears(canvas);
    _body(canvas);
    _face(canvas);

    canvas.restore();

    if (mood == MascotMood.sleeping) _zzz(canvas);
    if (mood == MascotMood.celebrating) _stars(canvas);
    if (tap > 0.75) _sparkles(canvas, (tap - 0.75) / 0.25);
  }

  // ---------- Partes ----------

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

  void _tail(Canvas canvas) {
    final wag = sin(breath * pi) * 0.25 + _twitchAngle * 0.6;
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
          Paint()
            ..color = s.bodyDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round,
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
          Paint()
            ..color = s.bodyDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      case MascotSpecies.bunny:
        canvas.drawCircle(
          Offset(86 + wag * 2, 68),
          7,
          Paint()..color = s.bodyLight,
        );
        canvas.drawCircle(
          Offset(86 + wag * 2, 68),
          7,
          Paint()
            ..color = s.limbDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      case MascotSpecies.panda:
        canvas.drawCircle(Offset(86 + wag * 2, 67), 5, Paint()..color = s.limb);
    }
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

  void _ears(Canvas canvas) {
    final outer = Paint()..color = s.earOuter;
    final inner = Paint()..color = s.earInner;
    for (final right in [false, true]) {
      double x(double v) => right ? 100 - v : v;
      // Solo una oreja se sacude, para que se vea natural.
      final angle = right ? _twitchAngle : 0.0;
      canvas.save();
      switch (species) {
        case MascotSpecies.pig:
          _rotateAround(canvas, Offset(x(34), 30), angle);
          canvas.drawPath(
            Path()
              ..moveTo(x(25), 37)
              ..quadraticBezierTo(x(20), 15, x(33), 19)
              ..quadraticBezierTo(x(40), 23, x(43), 30)
              ..close(),
            outer,
          );
          canvas.drawPath(
            Path()
              ..moveTo(x(28), 33)
              ..quadraticBezierTo(x(25), 20, x(33), 23)
              ..quadraticBezierTo(x(37), 26, x(39), 30)
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
          final tilt = right ? 0.18 : -0.18;
          canvas.save();
          canvas.translate(x(38), 18);
          canvas.rotate(tilt);
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
    canvas.drawOval(
      const Rect.fromLTWH(26, 31, 30, 13),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    switch (species) {
      case MascotSpecies.pig:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(50, 29.5),
              width: 15,
              height: 3.4,
            ),
            const Radius.circular(1.7),
          ),
          Paint()..color = s.nose,
        );
      case MascotSpecies.cat:
        final stripe = Paint()
          ..color = const Color(0xFFE8590C).withValues(alpha: 0.45)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(45, 30), const Offset(45.5, 36), stripe);
        canvas.drawLine(const Offset(50, 28.5), const Offset(50, 36), stripe);
        canvas.drawLine(const Offset(55, 30), const Offset(54.5, 36), stripe);
      case MascotSpecies.bunny:
      case MascotSpecies.panda:
        break;
    }
  }

  double get _mouthY => switch (species) {
    MascotSpecies.pig => 73,
    MascotSpecies.cat => 67,
    MascotSpecies.bunny => 69,
    MascotSpecies.panda => 70,
  };

  void _face(Canvas canvas) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blush = Paint()..color = s.blush.withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(30, 61), 5, blush);
    canvas.drawCircle(const Offset(70, 61), 5, blush);

    if (species == MascotSpecies.panda) {
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

    final eyeShift = Offset(look.dx * 1.8, look.dy * 1.4);
    for (final ex in [39.0, 61.0]) {
      final c = Offset(ex, 50) + eyeShift;
      if (mood == MascotMood.sleeping) {
        canvas.drawPath(
          Path()
            ..moveTo(ex - 4, 50)
            ..quadraticBezierTo(ex, 53.5, ex + 4, 50),
          species == MascotSpecies.panda ? (ink..color = Colors.white) : ink,
        );
        ink.color = _ink;
        continue;
      }
      if (mood == MascotMood.celebrating) {
        canvas.drawPath(
          Path()
            ..moveTo(ex - 4, 51.5)
            ..quadraticBezierTo(ex, 45.5, ex + 4, 51.5),
          species == MascotSpecies.panda ? (ink..color = Colors.white) : ink,
        );
        ink.color = _ink;
        continue;
      }
      final open = 1 - blink;
      if (open < 0.15) {
        canvas.drawLine(
          c.translate(-4, 0),
          c.translate(4, 0),
          species == MascotSpecies.panda ? (ink..color = Colors.white) : ink,
        );
        ink.color = _ink;
        continue;
      }
      if (species == MascotSpecies.panda) {
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
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 8.4, height: 9.6 * open),
          Paint()..color = _ink,
        );
      }
      if (open > 0.5) {
        canvas.drawCircle(
          c.translate(1.4, -1.8),
          1.5,
          Paint()..color = Colors.white,
        );
      }
    }

    if (mood == MascotMood.worried) {
      canvas.drawLine(const Offset(34, 43.5), const Offset(43, 40.5), ink);
      canvas.drawLine(const Offset(57, 40.5), const Offset(66, 43.5), ink);
    }

    _muzzle(canvas, ink);
    _mouth(canvas, ink);
  }

  void _muzzle(Canvas canvas, Paint ink) {
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
      case MascotSpecies.cat:
      case MascotSpecies.bunny:
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
        final wiggle = sin(breath * pi * 2) * 0.6;
        for (final dir in [-1.0, 1.0]) {
          canvas.drawLine(
            Offset(50 + dir * 9, 63),
            Offset(50 + dir * 23, 60 + wiggle),
            whisker,
          );
          canvas.drawLine(
            Offset(50 + dir * 9, 65),
            Offset(50 + dir * 23, 67 - wiggle),
            whisker,
          );
        }
      case MascotSpecies.panda:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 64), width: 21, height: 14),
          Paint()..color = s.muzzle,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 64), width: 21, height: 14),
          Paint()
            ..color = s.bodyDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(50, 61),
            width: 7.5,
            height: 4.6,
          ),
          Paint()..color = s.nose,
        );
    }
  }

  void _mouth(Canvas canvas, Paint ink) {
    final y = _mouthY;
    final feline =
        species == MascotSpecies.cat || species == MascotSpecies.bunny;
    switch (mood) {
      case MascotMood.happy || MascotMood.neutral when feline:
        // Boca en "w" típica de gato/conejo.
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

  void _zzz(Canvas canvas) {
    for (final (i, size) in [(0, 9.0), (1, 12.0)]) {
      final t = (breath + i * 0.5) % 1;
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

  /// Estrellitas que orbitan cuando celebra.
  void _stars(Canvas canvas) {
    final paint = Paint()..color = _gold;
    for (var i = 0; i < 4; i++) {
      final a = breath * pi * 0.6 + i * pi / 2;
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
      ..color = _gold.withValues(alpha: 1 - t)
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
  bool shouldRepaint(_MascotPainter old) =>
      old.species != species ||
      old.mood != mood ||
      old.breath != breath ||
      old.blink != blink ||
      old.look != look ||
      old.twitch != twitch ||
      old.tap != tap ||
      old.hop != hop;
}
