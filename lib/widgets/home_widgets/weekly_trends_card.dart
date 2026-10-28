import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../common/nx_select_field.dart';

const List<Map<String, String>> _metricOptions = [
  {'label': 'Weekly Calories Average', 'value': 'calories_weekly_avg'},
  {'label': 'Weekly Protein Average', 'value': 'protein_weekly_avg'},
  {'label': 'Weekly Carbs Average', 'value': 'carbs_weekly_avg'},
  {'label': 'Weekly Water Average', 'value': 'water_weekly_avg'},
  {'label': 'Weight Trend', 'value': 'weight_trend'},
];

class WeeklyTrendsCard extends ConsumerStatefulWidget {
  const WeeklyTrendsCard({super.key});

  @override
  ConsumerState<WeeklyTrendsCard> createState() => _WeeklyTrendsCardState();
}

class _WeeklyTrendsCardState extends ConsumerState<WeeklyTrendsCard> {
  String _selectedMetric = _metricOptions[0]['value']!;

  void _loadMetric(String metric) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    ref.read(analyticsProvider.notifier).fetchMetricHistory(user.id, metric);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetric(_selectedMetric));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final averages = state.summaryData?['averages_7_days'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7-Day Averages & Metric Trends',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _avgTile('Calories', averages?['calories'], '', AppColors.calories),
              const SizedBox(width: 10),
              _avgTile('Protein', averages?['protein_g'], 'g', AppColors.protein),
              const SizedBox(width: 10),
              _avgTile('Carbs', averages?['carbs_g'], 'g', AppColors.carbs),
              const SizedBox(width: 10),
              _avgTile('Water', averages?['water_ml'], 'ml', AppColors.info),
            ],
          ),
          const SizedBox(height: 16),
          Text('Explore Metric History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textMuted)),
          const SizedBox(height: 8),
          NxSelectField<String>(
            value: _selectedMetric,
            sheetTitle: 'Metric',
            options: _metricOptions
                .map((m) => NxSelectOption<String>(value: m['value']!, title: m['label']!))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedMetric = val);
              _loadMetric(val);
            },
          ),
          const SizedBox(height: 16),
          _buildChart(state),
        ],
      ),
    );
  }

  /// Rounds [raw] up to 1, 2, 2.5, 5 or 10 times a power of ten.
  double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nice = f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10;
    return nice * exp;
  }

  Widget _avgTile(String label, dynamic value, String unit, Color color) {
    final display = value == null ? '—' : '${(value as num).round()}$unit';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Text(display, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text('7d Avg $label', style: TextStyle(fontSize: 9, color: context.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(AnalyticsState state) {
    if (state.isLoadingMetricHistory) {
      return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    }
    final history = state.metricHistory ?? [];
    if (history.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No data yet for this metric.', style: TextStyle(color: context.textMuted, fontSize: 12)),
        ),
      );
    }

    final values = history.map((e) => ((e['value'] as num?) ?? 0).toDouble()).toList();
    final dates = history.map((e) => DateTime.tryParse(e['date'].toString()) ?? DateTime.now()).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final allNonNegative = dataMin >= 0;
    final span = (dataMax - dataMin) == 0 ? (dataMax.abs() * 0.1 + 1) : (dataMax - dataMin);
    // Round the axis to a "nice" step so grid lines and labels land on the
    // same values (previously the raw min/max produced a stray label like 312
    // drawn on top of 300, and a -41 floor for data that is never negative).
    final step = _niceStep(span / 4);
    double minY = (dataMin / step).floor() * step;
    double maxY = (dataMax / step).ceil() * step;
    if (allNonNegative && minY < 0) minY = 0;
    if (maxY == minY) maxY = minY + step;
    String fmt(double v) => step >= 1 ? v.round().toString() : v.toStringAsFixed(1);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) => FlLine(color: context.borderColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: step,
                getTitlesWidget: (value, meta) => Text(fmt(value), style: TextStyle(fontSize: 9, color: context.textDim)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                  if (dates.length > 1 && i != 0 && i != dates.length - 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('d MMM').format(dates[i]), style: TextStyle(fontSize: 9, color: context.textDim)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }
}
