import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mascot_painter.dart';
import 'mascot_species.dart';

export 'mascot_species.dart';

/// Mascota vectorial animada (sin assets). Gestos:
/// - tocar: salta;
/// - doble toque: da una vuelta y suelta corazones;
/// - mantener presionado: se deja acariciar (ojos felices, meneo, corazones);
/// - mover el dedo encima: te sigue con la mirada.
/// Sola: respira, parpadea, mira alrededor, mueve orejas, se estira y de
/// noche bosteza. Cambiar [reactKey] la hace atrapar una moneda.
class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    this.species = MascotSpecies.pig,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.reactKey = 0,
    this.onTap,
    this.interactive = true,
    this.accessory = MascotAccessory.none,
    this.stage = 1,
  });

  final MascotSpecies species;
  final MascotMood mood;
  final double size;
  final int reactKey;
  final VoidCallback? onTap;
  final bool interactive;
  final MascotAccessory accessory;

  /// Etapa evolutiva (1–3).
  final int stage;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  AnimationController _c(int ms) => AnimationController(
    vsync: this,
    duration: Duration(milliseconds: ms),
  );

  late final _breath = _c(2400);
  late final _blink = _c(120);
  late final _look = _c(220);
  late final _twitch = _c(400);
  late final _tap = _c(750);
  late final _hop = _c(560);
  late final _spin = _c(700);
  late final _love = _c(1300);
  late final _pet = _c(220);
  late final _yawn = _c(1500);
  late final _stretch = _c(650);
  late final _coin = _c(900);
  late final _all = [
    _breath,
    _blink,
    _look,
    _twitch,
    _tap,
    _hop,
    _spin,
    _love,
    _pet,
    _yawn,
    _stretch,
    _coin,
  ];

  final _rng = Random();
  Timer? _idle;
  Timer? _lookBack;
  Offset _lookFrom = Offset.zero;
  Offset _lookTo = Offset.zero;
  DateTime _lastTap = DateTime(2000);
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
    if (old.reactKey != widget.reactKey && !_reduceMotion) {
      _coin.forward(from: 0);
      _tap.forward(from: 0);
    }
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
      _hop.animateTo(0, duration: const Duration(milliseconds: 160));
    }
  }

  bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 22 || h < 6;
  }

  void _scheduleIdle() {
    _idle = Timer(Duration(milliseconds: 1400 + _rng.nextInt(2400)), () async {
      if (!mounted) return;
      if (!_reduceMotion &&
          widget.mood != MascotMood.sleeping &&
          _pet.value == 0) {
        final r = _rng.nextDouble();
        // De noche bosteza más seguido.
        final yawnChance = _isNight ? 0.25 : 0.06;
        if (r < yawnChance) {
          _yawn.forward(from: 0);
        } else if (r < yawnChance + 0.08) {
          _stretch.forward(from: 0);
        } else if (r < 0.6) {
          await _doBlink();
        } else if (r < 0.85) {
          _lookAt(
            _rng.nextDouble() < 0.35
                ? Offset.zero
                : Offset(_rng.nextDouble() * 2 - 1, _rng.nextDouble() - 0.5),
          );
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

  void _lookAt(Offset target) {
    _lookFrom = _currentLook;
    _lookTo = Offset(target.dx.clamp(-1.0, 1.0), target.dy.clamp(-1.0, 1.0));
    _look.forward(from: 0);
  }

  /// La mirada sigue al dedo (sin capturar el gesto: no bloquea scroll).
  void _follow(Offset local) {
    if (!widget.interactive || _reduceMotion) return;
    final c = Offset(widget.size / 2, widget.size / 2);
    _lookAt((local - c) / (widget.size / 2));
    _lookBack?.cancel();
    _lookBack = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _lookAt(Offset.zero);
    });
  }

  void _onTap() {
    final now = DateTime.now();
    final isDouble = now.difference(_lastTap).inMilliseconds < 320;
    _lastTap = now;
    if (_reduceMotion) {
      widget.onTap?.call();
      return;
    }
    if (isDouble) {
      HapticFeedback.mediumImpact();
      _spin.forward(from: 0);
      _love.forward(from: 0);
    } else {
      HapticFeedback.lightImpact();
      _tap.forward(from: 0);
      _twitch.forward(from: 0);
    }
    widget.onTap?.call();
  }

  void _petStart() {
    HapticFeedback.selectionClick();
    _pet.forward();
  }

  void _petEnd() {
    _pet.reverse();
    if (!_reduceMotion) _love.forward(from: 0);
  }

  @override
  void dispose() {
    _idle?.cancel();
    _lookBack?.cancel();
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: Listenable.merge(_all),
      builder: (context, _) => CustomPaint(
        painter: MascotPainter(
          species: widget.species,
          mood: widget.mood,
          stage: widget.stage,
          accessory: widget.accessory,
          pose: MascotPose(
            breath: Curves.easeInOut.transform(_breath.value),
            blink: _blink.value,
            look: _currentLook,
            twitch: _twitch.value,
            tap: _tap.value,
            hop: _hop.value,
            spin: _spin.value,
            love: _love.value,
            pet: _pet.value,
            yawn: _yawn.value,
            stretch: _stretch.value,
            coin: _coin.value,
          ),
        ),
      ),
    );
    final box = RepaintBoundary(
      child: SizedBox.square(dimension: widget.size, child: painter),
    );
    if (!widget.interactive) {
      return Semantics(
        label: 'Mascota ${widget.species.style.label}',
        child: box,
      );
    }
    return Semantics(
      label: 'Mascota ${widget.species.style.label}',
      hint: 'Toca, toca dos veces o mantén presionado',
      button: true,
      child: Listener(
        onPointerDown: (e) => _follow(e.localPosition),
        onPointerMove: (e) => _follow(e.localPosition),
        onPointerHover: (e) => _follow(e.localPosition),
        child: GestureDetector(
          onTap: _onTap,
          onLongPressStart: (_) => _petStart(),
          onLongPressEnd: (_) => _petEnd(),
          onLongPressCancel: () => _pet.reverse(),
          child: box,
        ),
      ),
    );
  }
}
