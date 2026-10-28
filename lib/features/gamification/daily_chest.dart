import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/confetti.dart';
import '../../core/theme.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/pressable.dart';
import 'celebration_dialog.dart';
import 'gamification_providers.dart';

final chestOpenedTodayProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(gamificationServiceProvider).chestOpenedToday(),
);

/// Tarjeta del cofre diario en el inicio. Se esconde tras abrirlo.
class DailyChestCard extends ConsumerStatefulWidget {
  const DailyChestCard({super.key});

  @override
  ConsumerState<DailyChestCard> createState() => _DailyChestCardState();
}

class _DailyChestCardState extends ConsumerState<DailyChestCard>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int? _xp;
  bool _hidden = false;

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  Future<void> _tapChest() async {
    if (_open.isAnimating || _xp != null) return;
    HapticFeedback.heavyImpact();
    final res = await ref.read(gamificationServiceProvider).openDailyChest();
    if (!mounted || res == null) return;
    setState(() => _xp = res.xp);
    await _open.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _hidden = true);
    if (res.result.hasCelebrations) await showCelebrations(context, res.result);
    ref.invalidate(chestOpenedTodayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final opened = ref.watch(chestOpenedTodayProvider).value ?? true;
    final theme = Theme.of(context);
    final show = !_hidden && (!opened || _xp != null);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                onTap: _tapChest,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        _ChestIcon(open: _open, closed: _xp == null),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _xp == null ? 'Cofre del día' : '¡+$_xp XP!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _xp == null ? null : AppColors.savings,
                                ),
                              ),
                              Text(
                                _xp == null
                                    ? 'Tócalo para abrirlo. Más racha = más premio.'
                                    : 'Vuelve mañana por otro.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_xp != null)
                      const Positioned.fill(
                        child: ConfettiBurst(
                          count: 26,
                          origin: Alignment(-0.75, 0),
                          duration: Duration(milliseconds: 1300),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}

class _ChestIcon extends StatelessWidget {
  const _ChestIcon({required this.open, required this.closed});

  final Animation<double> open;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    Widget chest = Pressable(
      child: SizedBox.square(
        dimension: 58,
        child: AnimatedBuilder(
          animation: open,
          builder: (_, _) => CustomPaint(painter: _ChestPainter(open.value)),
        ),
      ),
    );
    if (closed) {
      // Se sacude cada tanto: "¡ábreme!".
      chest = chest
          .animate(onPlay: (c) => c.repeat())
          .shake(delay: 1600.ms, duration: 500.ms, hz: 4, rotation: 0.08);
    }
    return chest;
  }
}

class _ChestPainter extends CustomPainter {
  _ChestPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60);
    const wood = Color(0xFFA0522D);
    const woodDark = Color(0xFF7A3E1D);
    const gold = Color(0xFFFFC233);

    // Rayos de luz al abrir.
    if (t > 0) {
      final glow = Paint()
        ..color = gold.withValues(alpha: 0.35 * (1 - (t - 0.6).abs()));
      for (var i = 0; i < 7; i++) {
        final a = -pi / 2 + (i - 3) * 0.32;
        canvas.drawPath(
          Path()
            ..moveTo(30, 30)
            ..lineTo(30 + cos(a - 0.08) * 40 * t, 30 + sin(a - 0.08) * 40 * t)
            ..lineTo(30 + cos(a + 0.08) * 40 * t, 30 + sin(a + 0.08) * 40 * t)
            ..close(),
          glow,
        );
      }
      // Monedas saliendo.
      for (var i = 0; i < 4; i++) {
        final p = Curves.easeOut.transform((t * 1.3 - i * 0.1).clamp(0.0, 1.0));
        canvas.drawCircle(
          Offset(30 + (i - 1.5) * 9 * p, 30 - p * 26 + p * p * 8),
          3.5,
          Paint()..color = gold.withValues(alpha: 1 - p * 0.3),
        );
      }
    }

    // Caja.
    final box = RRect.fromLTRBR(8, 30, 52, 54, const Radius.circular(4));
    canvas.drawRRect(box, Paint()..color = wood);
    canvas.drawRect(
      const Rect.fromLTRB(8, 40, 52, 44),
      Paint()..color = woodDark,
    );
    canvas.drawRect(const Rect.fromLTRB(27, 36, 33, 46), Paint()..color = gold);

    // Tapa que gira hacia atrás.
    canvas.save();
    canvas.translate(8, 30);
    canvas.rotate(-Curves.easeOutBack.transform(t) * 1.9);
    final lid = RRect.fromLTRBAndCorners(
      0,
      -12,
      44,
      0,
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(lid, Paint()..color = wood);
    canvas.drawRect(const Rect.fromLTRB(19, -12, 25, 0), Paint()..color = gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter old) => old.t != t;
}
