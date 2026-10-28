import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DonutSlice {
  const DonutSlice(this.value, this.color);

  final double value;
  final Color color;
}

/// Dona que se dibuja en un barrido en sentido horario al aparecer (y al
/// cambiar los datos). Tocar una porción la resalta engrosándola.
class AnimatedDonut extends StatefulWidget {
  const AnimatedDonut({
    super.key,
    required this.slices,
    required this.selected,
    required this.onSelected,
    this.thickness = 22,
    this.center,
  });

  final List<DonutSlice> slices;
  final int selected;
  final ValueChanged<int> onSelected;
  final double thickness;
  final Widget? center;

  @override
  State<AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<AnimatedDonut>
    with TickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _select = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  int _previous = -1;

  @override
  void initState() {
    super.initState();
    _sweep.forward();
  }

  @override
  void didUpdateWidget(AnimatedDonut old) {
    super.didUpdateWidget(old);
    final changed =
        old.slices.length != widget.slices.length ||
        [
          for (var i = 0; i < widget.slices.length; i++)
            old.slices[i].value != widget.slices[i].value,
        ].any((c) => c);
    if (changed) _sweep.forward(from: 0);
    if (old.selected != widget.selected) {
      _previous = old.selected;
      _select.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _select.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d, Size size) {
    final c = size.center(Offset.zero);
    final v = d.localPosition - c;
    final radius = min(size.width, size.height) / 2 - widget.thickness / 2 - 6;
    if ((v.distance - radius).abs() > widget.thickness) {
      widget.onSelected(-1);
      return;
    }
    // Ángulo desde las 12 en punto, en sentido horario.
    var angle = atan2(v.dy, v.dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final total = widget.slices.fold<double>(0, (s, x) => s + x.value);
    var acc = 0.0;
    for (final (i, s) in widget.slices.indexed) {
      acc += s.value / total * 2 * pi;
      if (angle <= acc) {
        HapticFeedback.selectionClick();
        widget.onSelected(i == widget.selected ? -1 : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          onTapDown: (d) => _onTapDown(d, size),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_sweep, _select]),
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: _DonutPainter(
                    slices: widget.slices,
                    progress: reduce
                        ? 1
                        : Curves.easeOutCubic.transform(_sweep.value),
                    selected: widget.selected,
                    previous: _previous,
                    selectT: Curves.easeOutBack.transform(_select.value),
                    thickness: widget.thickness,
                  ),
                ),
              ),
              ?widget.center,
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.selected,
    required this.previous,
    required this.selectT,
    required this.thickness,
  });

  final List<DonutSlice> slices;
  final double progress;
  final int selected;
  final int previous;
  final double selectT;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 - thickness / 2 - 6;
    final gap = slices.length > 1 ? 0.035 : 0.0;
    final end = -pi / 2 + 2 * pi * progress;

    // Pista de fondo tenue.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = slices.first.color.withValues(alpha: 0.06),
    );

    var start = -pi / 2;
    for (final (i, s) in slices.indexed) {
      final sweep = s.value / total * 2 * pi;
      final from = start + gap / 2;
      final to = min(start + sweep - gap / 2, end);
      start += sweep;
      if (to <= from) continue;

      var grow = 0.0;
      if (i == selected) grow = selectT;
      if (i == previous && i != selected) grow = 1 - selectT;
      final w = thickness + 9 * grow;
      final dim = selected >= 0 && i != selected ? 0.45 : 1.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        from,
        to - from,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = s.color.withValues(alpha: dim),
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}
