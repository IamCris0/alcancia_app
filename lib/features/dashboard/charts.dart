import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/pickers.dart';
import 'animated_donut.dart';
import 'month_summary.dart';

/// Dona de gastos por categoría con leyenda y barras de porcentaje.
class ExpenseDonut extends ConsumerStatefulWidget {
  const ExpenseDonut({super.key, required this.summary});

  final MonthSummary summary;

  @override
  ConsumerState<ExpenseDonut> createState() => _ExpenseDonutState();
}

class _ExpenseDonutState extends ConsumerState<ExpenseDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final items = widget.summary.byCategory;
    final total = widget.summary.expense;
    // Máximo 5 porciones; el resto se agrupa en "Otros".
    final top = items.take(5).toList();
    final rest = items.skip(5).fold<int>(0, (s, c) => s + c.total);
    final slices = [
      for (final c in top)
        (
          c.category?.name ?? 'Sin categoría',
          c.total,
          Color(c.category?.colorValue ?? 0xFF868E96),
          c.category?.iconKey ?? 'other',
        ),
      if (rest > 0) ('Otros', rest, const Color(0xFFADB5BD), 'other'),
    ];
    final touched = _touched >= 0 && _touched < slices.length
        ? slices[_touched]
        : null;

    return Column(
      children: [
        SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedDonut(
                    slices: [
                      for (final s in slices) DonutSlice(s.$2.toDouble(), s.$3),
                    ],
                    selected: _touched,
                    onSelected: (i) => setState(() => _touched = i),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      key: ValueKey(touched?.$1),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          touched?.$1 ?? 'Total gastado',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(touched?.$2 ?? total, currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
        const SizedBox(height: 12),
        for (final (i, s) in slices.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                IconBadge(iconKey: s.$4, color: s.$3, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.$1,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            '${(s.$2 * 100 / max(total, 1)).round()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatMoney(s.$2, currency),
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: s.$2 / max(total, 1)),
                          duration: Duration(milliseconds: 700 + i * 120),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            color: s.$3,
                            backgroundColor: s.$3.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Línea suave con relleno degradado del gasto diario del mes.
class DailyExpenseChart extends ConsumerWidget {
  const DailyExpenseChart({
    super.key,
    required this.daily,
    required this.month,
  });

  final List<int> daily;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();
    final isCurrent = now.year == month.year && now.month == month.month;
    // En el mes actual solo hasta hoy, para no dibujar días futuros en cero.
    final days = isCurrent ? now.day : daily.length;
    final maxY = daily.take(days).fold<int>(0, max).toDouble();

    final chart = LineChart(
      LineChartData(
        minX: 1,
        maxX: daily.length.toDouble(),
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.25,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == 0 ? 1 : maxY * 1.25 / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  'Día ${s.x.toInt()}\n${formatMoney(s.y.round(), currency)}',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < days; i++)
                FlSpot(i + 1.0, daily[i].toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: AppColors.brand,
            barWidth: 3,
            isStrokeCapRound: true,
            // Solo un punto destacado en el último día con datos.
            dotData: FlDotData(
              checkToShowDot: (spot, _) => spot.x == days.toDouble(),
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppColors.brand,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brand.withValues(alpha: 0.30),
                  AppColors.brand.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
    // La línea se "dibuja" de izquierda a derecha al aparecer.
    return SizedBox(
      height: 170,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
        builder: (context, t, child) =>
            ClipRect(clipper: _RevealClipper(t), child: child),
        child: chart,
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.t);

  final double t;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, -20, size.width * t + 8, size.height + 40);

  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}
