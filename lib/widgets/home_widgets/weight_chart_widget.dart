import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

/// A hand-drawn line chart (CustomPainter, no animation/ticker involved) —
/// used both in-app and for the home-screen widget capture, so both look
/// identical. fl_chart's LineChart repeatedly rendered as a solid gray block
/// inside HomeWidget.renderFlutterWidget's isolated single-frame render
/// pipeline (a separate PipelineOwner/BuildOwner with no real ticker driving
/// it), even after disabling its implicit animation and curve overshoot.
/// A CustomPainter has no such dependency — paint() runs synchronously from
/// the data it's given, so it can't render differently depending on how many
/// frames were pumped before the capture.
///
/// Card chrome (shadow/border/radius) and header treatment now match
/// MacroRingsWidget and ContributionGraphWidget — the three home-screen
/// widgets used to be styled independently and looked like an unrelated
/// set rather than one family.
class WeightChartWidget extends StatelessWidget {
  final List<double> weightHistory; // chronological ascending
  final List<DateTime> dates; // same length as weightHistory
  final double currentWeight;
  final double height;

  const WeightChartWidget({
    super.key,
    required this.weightHistory,
    required this.dates,
    required this.currentWeight,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final weights = weightHistory.isEmpty ? [currentWeight] : weightHistory;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        // paint() has no BuildContext (it's a CustomPainter, not a widget
        // build method) — resolve theme colors here, where context is
        // available, and pass them down. In the off-screen launcher-widget
        // pipeline there's no real MaterialApp theme to inherit, so these
        // getters fall back to the same light defaults this always used;
        // in-app they correctly follow the live theme.
        painter: _WeightChartPainter(
          weights: weights,
          dates: dates,
          currentWeight: currentWeight,
          textDimColor: context.textDim,
          gridColor: context.borderColor,
          cardColor: context.inputBg,
          valueColor: context.textMain,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final List<DateTime> dates;
  final double currentWeight;
  final Color textDimColor;
  final Color gridColor;
  final Color cardColor;
  final Color valueColor;

  _WeightChartPainter({
    required this.weights,
    required this.dates,
    required this.currentWeight,
    required this.textDimColor,
    required this.gridColor,
    required this.cardColor,
    required this.valueColor,
  });

  static const _pad = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty || size.width <= 0 || size.height <= 0) return;

    // Card chrome — shared with MacroRingsWidget & ContributionGraphWidget.
    final cardRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20));
    canvas.drawRRect(cardRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.04));
    canvas.drawRRect(cardRect, Paint()..color = cardColor);
    canvas.drawRRect(cardRect.deflate(0.5), Paint()..color = gridColor..style = PaintingStyle.stroke..strokeWidth = 1);

    // Header: eyebrow on the left, current weight (the number someone
    // glances at a widget for) prominent on the right.
    final eyebrowTp = _text('WEIGHT', GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.purpleAction, letterSpacing: 0.6));
    eyebrowTp.paint(canvas, const Offset(_pad, _pad));

    final bigTp = _text(currentWeight.toStringAsFixed(1), GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor));
    final unitTp = _text(' kg', GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: textDimColor));
    final headerRight = size.width - _pad;
    unitTp.paint(canvas, Offset(headerRight - unitTp.width, _pad + (bigTp.height - unitTp.height)));
    bigTp.paint(canvas, Offset(headerRight - unitTp.width - bigTp.width, _pad));

    final headerHeight = math.max(eyebrowTp.height, bigTp.height);
    final plotLeft = _pad;
    final plotWidth = math.max(size.width - _pad * 2, 1.0);
    final plotTop = _pad + headerHeight + 14;
    final plotHeight = math.max(size.height - plotTop - 22, 1.0);

    double minW = weights.reduce(math.min);
    double maxW = weights.reduce(math.max);
    if ((maxW - minW) < 2.0) {
      final mid = (maxW + minW) / 2;
      minW = mid - 1.0;
      maxW = mid + 1.0;
    } else {
      minW -= 1.0;
      maxW += 1.0;
    }

    // Two faint gridlines (top/bottom of the plot band) — enough to read
    // the chart as a chart without the clutter of a full axis.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(plotLeft, plotTop), Offset(plotLeft + plotWidth, plotTop), gridPaint);
    canvas.drawLine(Offset(plotLeft, plotTop + plotHeight), Offset(plotLeft + plotWidth, plotTop + plotHeight), gridPaint);

    final n = weights.length;
    double xFor(int i) => n > 1 ? plotLeft + plotWidth * i / (n - 1) : plotLeft + plotWidth / 2;
    double yFor(double w) => plotTop + plotHeight * (1 - (w - minW) / (maxW - minW));
    final points = List.generate(n, (i) => Offset(xFor(i), yFor(weights[i])));

    // Gradient area fill under the line — reads as an actual chart rather
    // than a flat 12%-alpha wash.
    if (points.length > 1) {
      final fillPath = Path()
        ..moveTo(points.first.dx, plotTop + plotHeight)
        ..lineTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, plotTop + plotHeight);
      fillPath.close();
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.purpleAction.withValues(alpha: 0.22), AppColors.purpleAction.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(plotLeft, plotTop, plotWidth, plotHeight));
      canvas.drawPath(fillPath, Paint()..shader = shader);
    }

    // The line itself.
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.purpleAction
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        linePath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Dots: small hollow markers for history, a bold filled one on the
    // latest point — "you are here", not just a row of identical dots.
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 2.5, Paint()..color = AppColors.purpleAction.withValues(alpha: 0.5));
    }
    if (points.isNotEmpty) {
      final last = points.last;
      canvas.drawCircle(last, 5, Paint()..color = cardColor);
      canvas.drawCircle(last, 5, Paint()..color = AppColors.purpleAction..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }

    // X-axis date labels: first / last only — cleaner than three, and the
    // header already carries "now" via the current-weight number.
    if (dates.isNotEmpty) {
      final fmt = DateFormat('d MMM');
      final labelStyle = GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w600, color: textDimColor);
      final firstTp = _text(fmt.format(dates.first), labelStyle);
      firstTp.paint(canvas, Offset(plotLeft, plotTop + plotHeight + 6));
      if (dates.length > 1) {
        final lastTp = _text(fmt.format(dates.last), labelStyle);
        lastTp.paint(canvas, Offset(plotLeft + plotWidth - lastTp.width, plotTop + plotHeight + 6));
      }
    }
  }

  TextPainter _text(String text, TextStyle style) {
    return TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.weights != weights ||
        oldDelegate.dates != dates ||
        oldDelegate.currentWeight != currentWeight ||
        oldDelegate.textDimColor != textDimColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.cardColor != cardColor ||
        oldDelegate.valueColor != valueColor;
  }
}
