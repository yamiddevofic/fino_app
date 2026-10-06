import 'dart:math' as math;

import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _drawDuration = Duration(milliseconds: 1100);
const _drawCurve = Curves.easeOutCubic;

/// Monto que cuenta hasta su valor cada vez que cambia.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({super.key, required this.value, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: _drawDuration,
      curve: _drawCurve,
      builder: (context, v, _) => Text(
        formatCop(v),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: tabularFigures,
        ),
      ),
    );
  }
}

/// Anillo que se dibuja como un trazo SVG animado (stroke-dashoffset)
/// hasta [value], entre 0 y 1.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.size = 92,
    this.stroke = 9,
    this.child,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: _drawDuration,
      curve: _drawCurve,
      builder: (context, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, color, trackColor, stroke),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Totales de un mes para [MonthlyBars].
class MonthTotals {
  const MonthTotals(this.month, this.incomes, this.expenses);

  final DateTime month;
  final double incomes;
  final double expenses;
}

/// Barras pareadas de ingresos y gastos por mes que crecen al aparecer.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({
    super.key,
    required this.months,
    required this.incomeColor,
    required this.expenseColor,
  });

  final List<MonthTotals> months;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final maxValue = months.fold<double>(
      0,
      (m, e) => math.max(m, math.max(e.incomes, e.expenses)),
    );
    final label = DateFormat.MMM('es');

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: _drawDuration,
            curve: _drawCurve,
            builder: (context, progress, _) => CustomPaint(
              size: Size.infinite,
              painter: _BarsPainter(
                months: months,
                maxValue: maxValue,
                progress: progress,
                incomeColor: incomeColor,
                expenseColor: expenseColor,
                gridColor: tokens.border,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in months)
              Expanded(
                child: Text(
                  label.format(m.month).replaceAll('.', ''),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.textMuted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.months,
    required this.maxValue,
    required this.progress,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
  });

  final List<MonthTotals> months;
  final double maxValue;
  final double progress;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (months.isEmpty || maxValue <= 0) return;

    final slot = size.width / months.length;
    final barWidth = math.min(10.0, slot / 4);
    for (var i = 0; i < months.length; i++) {
      final cx = slot * i + slot / 2;
      _bar(
        canvas,
        size,
        cx - barWidth * 0.65,
        barWidth,
        months[i].incomes,
        incomeColor,
      );
      _bar(
        canvas,
        size,
        cx + barWidth * 0.65,
        barWidth,
        months[i].expenses,
        expenseColor,
      );
    }
  }

  void _bar(
    Canvas canvas,
    Size size,
    double cx,
    double w,
    double value,
    Color color,
  ) {
    if (value <= 0) return;
    final h = math.max(3.0, size.height * (value / maxValue) * progress);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w / 2, size.height - h, w, h),
        Radius.circular(w / 2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress ||
      old.months != months ||
      old.incomeColor != incomeColor ||
      old.expenseColor != expenseColor;
}
