import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// Today's calories/protein rings + carbs/fat bars, for the Home dashboard.
///
/// `macro_rings_widget.dart` already draws this exact concept, but it's
/// hardcoded to light colors and a fixed 320x160 box because
/// `HomeWidget.renderFlutterWidget`'s off-screen pipeline needs an exact,
/// non-animated, theme-independent size (it renders for the Android
/// launcher, which has no theme to read). This is a separate, in-app
/// widget — same visual language, but theme-aware and responsive, since
/// neither of those constraints apply inside the running app.
class MacroRingsCard extends StatelessWidget {
  const MacroRingsCard({
    super.key,
    required this.calories,
    required this.maxCalories,
    required this.protein,
    required this.maxProtein,
    required this.carbs,
    required this.maxCarbs,
    required this.fat,
    required this.maxFat,
  });

  final double calories, maxCalories, protein, maxProtein, carbs, maxCarbs, fat, maxFat;

  @override
  Widget build(BuildContext context) {
    final calPercent = maxCalories > 0 ? (calories / maxCalories).clamp(0.0, 1.0) : 0.0;
    final proPercent = maxProtein > 0 ? (protein / maxProtein).clamp(0.0, 1.0) : 0.0;
    final carbPercent = maxCarbs > 0 ? (carbs / maxCarbs).clamp(0.0, 1.0) : 0.0;
    final fatPercent = maxFat > 0 ? (fat / maxFat).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: AppRadius.lgAll, border: Border.all(color: context.borderColor)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ring(context, title: 'Calories', current: calories.round().toString(), max: maxCalories.round().toString(), percent: calPercent, color: AppColors.calories),
              _ring(context, title: 'Protein', current: '${protein.round()}g', max: '${maxProtein.round()}g', percent: proPercent, color: AppColors.protein),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _bar(context, label: 'Carbs', value: '${carbs.round()}/${maxCarbs.round()}g', percent: carbPercent, color: AppColors.carbs),
          const SizedBox(height: AppSpacing.sm),
          _bar(context, label: 'Fat', value: '${fat.round()}/${maxFat.round()}g', percent: fatPercent, color: AppColors.fat),
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, {required String title, required String current, required String max, required double percent, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: 42,
          lineWidth: 9,
          animation: true,
          animationDuration: 700,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(current, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textMain)),
              Text('/$max', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: context.textMuted)),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.16),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: context.textMuted)),
      ],
    );
  }

  Widget _bar(BuildContext context, {required String label, required String value, required double percent, required Color color}) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: TextStyle(fontSize: 11.5, color: context.textMuted))),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: context.borderColor, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 80,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, maxLines: 1, softWrap: false, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textMain)),
          ),
        ),
      ],
    );
  }
}
