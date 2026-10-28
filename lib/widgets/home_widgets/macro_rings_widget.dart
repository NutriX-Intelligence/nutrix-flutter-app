import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Today's calorie/protein rings for the Android home-screen widget.
/// Rewritten as a CustomPainter (was `percent_indicator`'s CircularPercentIndicator)
/// so its card chrome, typography, and ring geometry match the other two
/// launcher widgets (WeightChartWidget, ContributionGraphWidget) exactly —
/// previously each was designed separately and looked like three unrelated
/// widgets rather than a set. `animation: false` was already required here
/// for `HomeWidget.renderFlutterWidget`'s single-pass off-screen pipeline
/// (no ticker drives a second frame); a CustomPainter has no animation to
/// worry about disabling in the first place.
class MacroRingsWidget extends StatelessWidget {
  final double calories;
  final double maxCalories;
  final double protein;
  final double maxProtein;

  const MacroRingsWidget({
    super.key,
    required this.calories,
    required this.maxCalories,
    required this.protein,
    required this.maxProtein,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MacroRingsPainter(
        calories: calories,
        maxCalories: maxCalories,
        protein: protein,
        maxProtein: maxProtein,
      ),
      size: Size.infinite,
    );
  }
}

class _MacroRingsPainter extends CustomPainter {
  final double calories, maxCalories, protein, maxProtein;

  _MacroRingsPainter({
    required this.calories,
    required this.maxCalories,
    required this.protein,
    required this.maxProtein,
  });

  static const _pad = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Card chrome — shared with WeightChartWidget & ContributionGraphWidget.
    final cardRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20));
    canvas.drawRRect(cardRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.04));
    canvas.drawRRect(cardRect, Paint()..color = AppColors.bgLightCard);
    canvas.drawRRect(cardRect.deflate(0.5), Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1);

    // Eyebrow + title, matching the other two widgets' header style.
    final eyebrowTp = _text('TODAY', GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6));
    eyebrowTp.paint(canvas, const Offset(_pad, _pad));
    final titleTp = _text('Nutrition', GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textMain));
    titleTp.paint(canvas, Offset(_pad, _pad + eyebrowTp.height + 2));

    final ringTop = _pad + eyebrowTp.height + 2 + titleTp.height + 8;
    const ringRadius = 31.0;
    const strokeWidth = 8.0;
    final ringCenterY = ringTop + ringRadius;
    final leftCx = size.width * 0.27;
    final rightCx = size.width * 0.73;

    _ring(canvas, Offset(leftCx, ringCenterY), ringRadius, strokeWidth,
        percent: maxCalories > 0 ? (calories / maxCalories).clamp(0.0, 1.0) : 0.0,
        color: AppColors.calories,
        big: calories.round().toString(),
        small: '/${maxCalories.round()}',
        label: 'Calories');

    _ring(canvas, Offset(rightCx, ringCenterY), ringRadius, strokeWidth,
        percent: maxProtein > 0 ? (protein / maxProtein).clamp(0.0, 1.0) : 0.0,
        color: AppColors.primary,
        big: '${protein.round()}g',
        small: '/${maxProtein.round()}g',
        label: 'Protein');
  }

  void _ring(Canvas canvas, Offset center, double radius, double strokeWidth, {
    required double percent,
    required Color color,
    required String big,
    required String small,
    required String label,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);
    if (percent > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round);
    }

    final bigTp = _text(big, GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textMain));
    final smallTp = _text(small, GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textDim));
    final totalH = bigTp.height + smallTp.height - 2;
    bigTp.paint(canvas, Offset(center.dx - bigTp.width / 2, center.dy - totalH / 2));
    smallTp.paint(canvas, Offset(center.dx - smallTp.width / 2, center.dy - totalH / 2 + bigTp.height - 2));

    final labelTp = _text(label, GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted));
    labelTp.paint(canvas, Offset(center.dx - labelTp.width / 2, center.dy + radius + 7));
  }

  TextPainter _text(String text, TextStyle style) {
    return TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  }

  @override
  bool shouldRepaint(covariant _MacroRingsPainter oldDelegate) {
    return oldDelegate.calories != calories ||
        oldDelegate.maxCalories != maxCalories ||
        oldDelegate.protein != protein ||
        oldDelegate.maxProtein != maxProtein;
  }
}
