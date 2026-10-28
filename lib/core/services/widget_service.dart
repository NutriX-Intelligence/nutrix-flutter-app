import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../widgets/home_widgets/macro_rings_widget.dart';
import '../../widgets/home_widgets/contribution_graph_widget.dart';
import '../../widgets/home_widgets/weight_chart_widget.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class WidgetService {
  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.nutrix.nutrix_app');
  }

  static Future<void> updateMacroWidget({
    required double calories,
    required double maxCalories,
    required double protein,
    required double maxProtein,
  }) async {
    try {
      await HomeWidget.renderFlutterWidget(
        MacroRingsWidget(
          calories: calories,
          maxCalories: maxCalories,
          protein: protein,
          maxProtein: maxProtein,
        ),
        logicalSize: const Size(320, 160),
        // Default pixelRatio is 1.0, which renders far below what a modern
        // Android screen's density needs — the launcher then upscales the
        // small bitmap to fill the actual widget slot, which is what read
        // as "blurry". 3.0 covers essentially all real device densities.
        pixelRatio: 3.0,
        key: 'macro_widget_image',
      );
      await HomeWidget.updateWidget(androidName: 'MacroWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Macro Widget: $e');
    }
  }

  static Future<void> updateContributionWidget(List<DailyStatus> history) async {
    try {
      await HomeWidget.renderFlutterWidget(
        ContributionGraphWidget(monthlyHistory: history),
        // Grew from a 120px GitHub-style strip to a real 5-6 row calendar
        // month grid (weekday header + up to 6 week rows). renderFlutterWidget
        // gives the content a TIGHT box matching logicalSize — too short and
        // the extra rows just clip instead of shrinking to fit.
        logicalSize: const Size(320, 300),
        pixelRatio: 3.0,
        key: 'contribution_widget_image',
      );
      await HomeWidget.updateWidget(androidName: 'ContributionWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Contribution Widget: $e');
    }
  }

  /// There is no backend endpoint for a month's worth of daily log status,
  /// and backend code is off-limits, so this builds the contribution graph
  /// client-side: fetch each day-so-far-this-month individually via the
  /// existing per-date meal-logs endpoint and classify it against the
  /// user's targets. Runs once per Home load, not per meal log — it's up to
  /// ~31 requests.
  static Future<void> updateContributionWidgetFromBackend({
    required int userId,
    required double targetCalories,
    required double targetProtein,
  }) async {
    try {
      final now = DateTime.now();
      final apiClient = ApiClient();
      final statuses = await Future.wait(
        List.generate(now.day, (i) async {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, i + 1));
          try {
            final res = await apiClient.dio.get(
              ApiEndpoints.mealLogsToday(userId),
              // today's cell: no date, the server decides; other days: explicit date
              queryParameters: (i + 1 == now.day) ? null : {'log_date': dateStr},
            );
            final data = res.data;
            final logs = data is Map ? data['logs'] as List? : null;
            final totals = data is Map ? data['totals'] as Map<String, dynamic>? : null;
            return _classifyDay(logs, totals, targetCalories, targetProtein);
          } catch (_) {
            return DailyStatus.noLog;
          }
        }),
      );
      await updateContributionWidget(statuses);
    } catch (e) {
      debugPrint('Error building Contribution Widget: $e');
    }
  }

  static DailyStatus _classifyDay(
    List? logs,
    Map<String, dynamic>? totals,
    double targetCalories,
    double targetProtein,
  ) {
    if (logs == null || logs.isEmpty || totals == null) return DailyStatus.noLog;
    final calories = (totals['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (totals['protein'] as num?)?.toDouble() ?? 0.0;
    if (calories <= 0 && protein <= 0) return DailyStatus.noLog;

    final calRatio = targetCalories > 0 ? calories / targetCalories : 0.0;
    final proRatio = targetProtein > 0 ? protein / targetProtein : 0.0;
    final calOver = calRatio > 1.15;
    final proOver = proRatio > 1.3;

    if (calOver && proOver) return DailyStatus.extraBoth;
    if (proOver) return DailyStatus.extraPro;
    if (calOver) return DailyStatus.extraCals;
    if (calRatio >= 0.7) return DailyStatus.reach;
    return DailyStatus.less;
  }

  static Future<void> updateWeightWidget(List<double> history, List<DateTime> dates, double current) async {
    try {
      await HomeWidget.renderFlutterWidget(
        WeightChartWidget(
          weightHistory: history,
          dates: dates,
          currentWeight: current,
          height: 160,
        ),
        // Widened from a 160x160 square to match the other two widgets'
        // 320-wide canvas — the square version left almost no horizontal
        // room for 3 date labels, so the rightmost one ("30 Aug") was
        // getting clipped at the render boundary.
        logicalSize: const Size(320, 160),
        pixelRatio: 3.0,
        key: 'weight_widget_image',
      );
      await HomeWidget.updateWidget(androidName: 'WeightWidgetProvider');
    } catch (e) {
      debugPrint('Error updating Weight Widget: $e');
    }
  }
}
