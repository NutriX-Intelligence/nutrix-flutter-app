import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_meal_type_dialog.dart';

final homelyMealDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, mealId) async {
  final response = await ApiClient().dio.get(ApiEndpoints.homelyDetail(mealId));
  return response.data as Map<String, dynamic>;
});

class HomelyMealDetailScreen extends ConsumerWidget {
  final int mealId;

  const HomelyMealDetailScreen({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealAsync = ref.watch(homelyMealDetailProvider(mealId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mealAsync.maybeWhen(data: (m) => m['name']?.toString() ?? 'Homely Meal', orElse: () => 'Homely Meal'),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: mealAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NxErrorState(
          message: 'Could not load this meal.',
          onRetry: () => ref.refresh(homelyMealDetailProvider(mealId)),
        ),
        data: (meal) => _buildContent(context, ref, meal),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> meal) {
    final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
    final ingredients = meal['ingredients'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal['name'] ?? 'Homely Meal', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (meal['cuisine'] != null) _tag(meal['cuisine'].toString(), AppColors.accent),
              if (meal['region'] != null) _tag(meal['region'].toString(), context.textMuted),
              _tag(meal['status'] == 'approved' ? 'Community Verified' : 'Pending Review', meal['status'] == 'approved' ? AppColors.success : AppColors.warning),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _logMeal(context, ref, meal, nutrition),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Log This as a Meal'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Nutrition (per serving)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.cardBg, border: Border.all(color: context.borderColor), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _nutrientItem(context, 'Calories', '${(nutrition['energy_kcal'] ?? 0).round()}', 'kcal', AppColors.calories),
                _nutrientItem(context, 'Protein', '${(nutrition['protein_g'] ?? 0).round()}', 'g', AppColors.protein),
                _nutrientItem(context, 'Carbs', '${(nutrition['carb_g'] ?? 0).round()}', 'g', AppColors.carbs),
                _nutrientItem(context, 'Fat', '${(nutrition['fat_g'] ?? 0).round()}', 'g', AppColors.fat),
              ],
            ),
          ),
          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Ingredients (${ingredients.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...ingredients.map((ing) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: context.cardBg, border: Border.all(color: context.borderColor), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(child: Text(ing['ingredient_name'] ?? ing['name'] ?? 'Ingredient')),
                    if (ing['amount'] != null)
                      Text('${ing['amount']} ${ing['unit'] ?? ''}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _logMeal(BuildContext context, WidgetRef ref, Map<String, dynamic> meal, Map<String, dynamic> nutrition) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final mealType = await NxMealTypeDialog.show(
      context,
      itemLabel: meal['name']?.toString() ?? 'Homely Meal',
      title: 'Log Homely Meal',
      initialMealType: 'Lunch',
      confirmLabel: 'Log It',
    );
    if (mealType == null || !context.mounted) return;

    try {
      await ApiClient().dio.post(
        ApiEndpoints.mealLogs,
        data: {
          'user_id': user.id,
          'meal_type': mealType,
          'source': 'homely',
          'food_name': meal['name'],
          'calories': nutrition['energy_kcal'] ?? 0,
          'protein': nutrition['protein_g'] ?? 0,
          'carbs': nutrition['carb_g'] ?? 0,
          'fat': nutrition['fat_g'] ?? 0,
        },
      );
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged as $mealType!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _nutrientItem(BuildContext context, String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
