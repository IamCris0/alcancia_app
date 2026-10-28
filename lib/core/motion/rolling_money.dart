import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../money.dart';
import '../providers.dart';

/// Monto con dígitos que ruedan como un odómetro. Cada posición se anima
/// por separado (de derecha a izquierda con un leve desfase).
class RollingMoney extends ConsumerWidget {
  const RollingMoney(this.cents, {super.key, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = formatMoney(cents, ref.watch(currencyProvider));
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(text, style: base);
    }
    final scaler = MediaQuery.textScalerOf(context);
    final digitSize = (TextPainter(
      text: TextSpan(text: '0', style: base),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout()).size;

    final chars = text.split('');
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, ch) in chars.indexed)
              _isDigit(ch)
                  ? _RollingDigit(
                      // Clave por posición desde la derecha: al crecer el
                      // número, las unidades siguen siendo las unidades.
                      key: ValueKey('d${chars.length - i}'),
                      digit: int.parse(ch),
                      style: base,
                      size: digitSize,
                      order: chars.length - i,
                    )
                  : Text(ch, style: base),
          ],
        ),
      ),
    );
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    required this.size,
    required this.order,
  });

  final int digit;
  final TextStyle style;
  final Size size;
  final int order;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: digit.toDouble()),
      duration: Duration(milliseconds: 450 + order * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => ClipRect(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: size.height * 10,
            child: Transform.translate(
              offset: Offset(0, -value * size.height),
              child: Column(
                children: [
                  for (var d = 0; d < 10; d++)
                    SizedBox(
                      height: size.height,
                      child: Text('$d', style: style),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
