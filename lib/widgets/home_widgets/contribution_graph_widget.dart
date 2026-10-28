import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum DailyStatus {
  noLog,
  less,
  reach,
  extraPro,
  extraCals,
  extraBoth,
}

class _Cell {
  final int day;
  final DailyStatus? status; // null = future day, no data yet
  const _Cell(this.day, this.status);
}

/// A hand-drawn calendar-month grid (CustomPainter). A previous version
/// used nested Container/Row/Column/Expanded/Text widgets and rendered as a
/// blank solid-color card inside HomeWidget.renderFlutterWidget's isolated
/// single-pass build pipeline — the same failure WeightChartWidget hit with
/// fl_chart, which a CustomPainter rewrite fixed there too. A deep widget
/// tree apparently doesn't reliably finish building/laying out within that
/// pipeline's fixed two build passes; a CustomPainter has no widget tree to
/// resolve at all, so there's nothing to fail.
///
/// Card chrome and header now match MacroRingsWidget/WeightChartWidget —
/// previously each of the three home-screen widgets was designed
/// separately (different shadow, no shadow, different color picks) and
/// read as three unrelated widgets rather than one family. The status
/// color scale was also an arbitrary Tailwind grab-bag before; it's now
/// built from the app's own brand colors (AppColors.calories/primary/
/// error/purpleAction) so a day's color means the same thing it would
/// in-app.
class ContributionGraphWidget extends StatelessWidget {
  final List<DailyStatus> monthlyHistory; // index 0 = day 1 of the current month, through today

  const ContributionGraphWidget({
    super.key,
    required this.monthlyHistory,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CalendarPainter(monthlyHistory: monthlyHistory),
      size: Size.infinite,
    );
  }
}

class _CalendarPainter extends CustomPainter {
  final List<DailyStatus> monthlyHistory;

  _CalendarPainter({required this.monthlyHistory});

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _pad = 18.0;
  static const _rowHeight = 25.0;
  static const _cellMargin = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Card chrome — shared with MacroRingsWidget & WeightChartWidget.
    final cardRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20));
    canvas.drawRRect(cardRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.04));
    canvas.drawRRect(cardRect, Paint()..color = AppColors.bgLightCard);
    canvas.drawRRect(cardRect.deflate(0.5), Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1);

    final contentLeft = _pad;
    final contentWidth = size.width - _pad * 2;

    final eyebrowTp = _text('THIS MONTH', GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6));
    eyebrowTp.paint(canvas, Offset(contentLeft, _pad));
    final titleTp = _text('Activity', GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textMain));
    titleTp.paint(canvas, Offset(contentLeft, _pad + eyebrowTp.height + 2));

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Dart's weekday is 1 (Mon) .. 7 (Sun) — Monday-first offset.
    final emptyStartCells = firstDay.weekday - 1;

    final cells = <_Cell?>[];
    for (int i = 0; i < emptyStartCells; i++) {
      cells.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final status = day <= monthlyHistory.length ? monthlyHistory[day - 1] : null;
      cells.add(_Cell(day, status));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weekCount = cells.length ~/ 7;

    final colWidth = contentWidth / 7;
    final headerTop = _pad + eyebrowTp.height + 2 + titleTp.height + 12;

    double headerRowHeight = 0;
    for (int c = 0; c < 7; c++) {
      final tp = _text(_weekdayLabels[c], GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textDim));
      headerRowHeight = tp.height;
      final x = contentLeft + colWidth * c + (colWidth - tp.width) / 2;
      tp.paint(canvas, Offset(x, headerTop));
    }

    final gridTop = headerTop + headerRowHeight + 6;

    for (int r = 0; r < weekCount; r++) {
      for (int c = 0; c < 7; c++) {
        final cell = cells[r * 7 + c];
        if (cell == null) continue;

        final cellRect = Rect.fromLTWH(
          contentLeft + colWidth * c + _cellMargin,
          gridTop + _rowHeight * r + _cellMargin,
          colWidth - _cellMargin * 2,
          _rowHeight - _cellMargin * 2,
        );
        final cellRRect = RRect.fromRectAndRadius(cellRect, const Radius.circular(7));

        final isToday = cell.day == now.day;
        final isFuture = cell.status == null;

        if (!isFuture) {
          canvas.drawRRect(cellRRect, Paint()..color = _colorForStatus(cell.status!));
        }

        final showBorder = isFuture || cell.status == DailyStatus.noLog || cell.status == DailyStatus.less;
        if (isToday) {
          canvas.drawRRect(cellRRect, Paint()..color = AppColors.purpleAction..style = PaintingStyle.stroke..strokeWidth = 1.6);
        } else if (showBorder) {
          canvas.drawRRect(cellRRect, Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 1);
        }

        final dayTp = _text(
          '${cell.day}',
          GoogleFonts.outfit(fontSize: 10.5, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: _textColorForStatus(cell.status, isFuture)),
        );
        dayTp.paint(canvas, Offset(cellRect.center.dx - dayTp.width / 2, cellRect.center.dy - dayTp.height / 2));
      }
    }

    // Legend — turns an unexplained color grid into a readable key. Only
    // the three buckets a user actually needs to recognize at a glance.
    final legendTop = gridTop + _rowHeight * weekCount + 12;
    if (legendTop + 14 <= size.height - 10) {
      double x = contentLeft;
      x = _legendItem(canvas, Offset(x, legendTop), AppColors.border, 'No log');
      x = _legendItem(canvas, Offset(x, legendTop), AppColors.primary, 'On track');
      _legendItem(canvas, Offset(x, legendTop), AppColors.error, 'Over target');
    }
  }

  double _legendItem(Canvas canvas, Offset topLeft, Color color, String label) {
    const dotSize = 8.0;
    final dotRect = Rect.fromLTWH(topLeft.dx, topLeft.dy + 3, dotSize, dotSize);
    canvas.drawRRect(RRect.fromRectAndRadius(dotRect, const Radius.circular(2.5)), Paint()..color = color);
    final labelTp = _text(label, GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted));
    labelTp.paint(canvas, Offset(topLeft.dx + dotSize + 5, topLeft.dy));
    return topLeft.dx + dotSize + 5 + labelTp.width + 14;
  }

  Color _textColorForStatus(DailyStatus? status, bool isFuture) {
    if (isFuture) return AppColors.textDim;
    switch (status!) {
      case DailyStatus.extraPro:
      case DailyStatus.extraBoth:
      case DailyStatus.extraCals:
      case DailyStatus.reach:
        return Colors.white;
      case DailyStatus.noLog:
      case DailyStatus.less:
        return AppColors.textMain;
    }
  }

  // Built from the app's own brand palette instead of an arbitrary
  // Tailwind grab-bag, so a color here means the same thing it would
  // in-app: green is "on target" everywhere, red is calories, purple is
  // the app's secondary accent.
  Color _colorForStatus(DailyStatus status) {
    switch (status) {
      case DailyStatus.noLog:
        return AppColors.border;
      case DailyStatus.less:
        return AppColors.calories.withValues(alpha: 0.35);
      case DailyStatus.reach:
        return AppColors.primary;
      case DailyStatus.extraPro:
        return AppColors.carbs; // Gold: protein over target.
      case DailyStatus.extraCals:
        return AppColors.error;
      case DailyStatus.extraBoth:
        return AppColors.purpleAction;
    }
  }

  TextPainter _text(String text, TextStyle style) {
    return TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  }

  @override
  bool shouldRepaint(covariant _CalendarPainter oldDelegate) {
    return oldDelegate.monthlyHistory != monthlyHistory;
  }
}
