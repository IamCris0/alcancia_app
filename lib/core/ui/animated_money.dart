import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../money.dart';
import '../providers.dart';

/// Monto que "cuenta" desde el valor anterior hasta el nuevo. Usa cifras
/// tabulares para que el ancho no salte durante la animación.
class AnimatedMoney extends ConsumerWidget {
  const AnimatedMoney(
    this.cents, {
    super.key,
    this.style,
    this.signed = false,
    this.duration = const Duration(milliseconds: 900),
  });

  final int cents;
  final TextStyle? style;
  final bool signed;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: cents.toDouble()),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        signed
            ? formatSigned(value.round(), currency)
            : formatMoney(value.round(), currency),
        style: base,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
