import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/recipe.dart';
import '../../widgets/smart_substitutions_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_meal_type_dialog.dart';

final recipeDetailProvider =
    FutureProvider.family<Recipe, String>((ref, code) async {
  final response = await ApiClient().dio.get(ApiEndpoints.recipeDetail(code));
  return Recipe.fromJson(response.data);
});

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeCode;

  const RecipeDetailScreen({super.key, required this.recipeCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeCode));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          recipeAsync.maybeWhen(data: (r) => r.recipeName, orElse: () => 'Recipe'),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NxErrorState(
          message: 'Could not load this recipe.',
          onRetry: () => ref.refresh(recipeDetailProvider(recipeCode)),
        ),
        data: (recipe) => _buildRecipeContent(context, ref, recipe),
      ),
    );
  }

  Widget _buildRecipeContent(BuildContext context, WidgetRef ref, Recipe recipe) {
    final healthColor = (recipe.healthScore ?? 50) >= 70
        ? AppColors.healthy
        : (recipe.healthScore ?? 50) >= 40
            ? AppColors.moderate
            : AppColors.unhealthy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            recipe.recipeName,
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tag(recipe.category, AppColors.primary),
              if (recipe.cuisine != null) _tag(recipe.cuisine!, AppColors.accent),
              if (recipe.difficulty != null) _tag(recipe.difficulty!, AppColors.warning),
              if (recipe.cookingTimeMinutes != null)
                _tag('${recipe.cookingTimeMinutes} min', AppColors.info),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showLogMealDialog(context, ref, recipe),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Log This as a Meal'),
            ),
          ),

          const SizedBox(height: 20),

          // Health Score
          if (recipe.healthScore != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: healthColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: healthColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: healthColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Score',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${recipe.healthScore!.toInt()}/100 — ${recipe.healthCategory ?? "Moderate"}',
                          style: TextStyle(
                            color: healthColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Nutrition
          if (recipe.nutrition != null) ...[
            Text('Nutrition per serving',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildNutritionGrid(context, recipe.nutrition!),
            const SizedBox(height: 20),
          ],

          // Ingredients
          if (recipe.ingredients.isNotEmpty) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Ingredients (${recipe.ingredients.length})',
                    style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SmartSubstitutionsSheet(
                        ingredients: recipe.ingredients.map((i) => i.ingredientName ?? '').where((s) => s.isNotEmpty).toList(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_calls, size: 18),
                  label: const Text('Smart Substitutions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recipe.ingredients.asMap().entries.map((entry) {
              final i = entry.key;
              final ing = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ing.foodName ?? ing.ingredientName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (ing.amount != null && ing.unit != null)
                      Text(
                        '${ing.amount} ${ing.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.textMuted,
                            ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: (300 + 40 * i).ms, duration: 300.ms);
            }),
            const SizedBox(height: 20),
          ],

          // Instructions
          if (recipe.instructions != null && recipe.instructions!.isNotEmpty) ...[
            Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                recipe.instructions!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(BuildContext context, Map<String, dynamic> nutrition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _nutrientItem(context, 'Calories',
                  '${(nutrition['energy_kcal'] ?? 0).toStringAsFixed(0)}', 'kcal', AppColors.calories),
              _nutrientItem(context, 'Protein',
                  '${(nutrition['protein_g'] ?? 0).toStringAsFixed(1)}', 'g', AppColors.protein),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _nutrientItem(context, 'Carbs',
                  '${(nutrition['carb_g'] ?? 0).toStringAsFixed(1)}', 'g', AppColors.carbs),
              _nutrientItem(context, 'Fat',
                  '${(nutrition['fat_g'] ?? 0).toStringAsFixed(1)}', 'g', AppColors.fat),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _nutrientItem(
      BuildContext context, String label, String value, String unit, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                          color: color, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogMealDialog(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final nutrition = recipe.nutrition ?? {};

    final mealType = await NxMealTypeDialog.show(
      context,
      itemLabel: recipe.recipeName,
      title: 'Log Recipe to Meal',
      confirmLabel: 'Log It',
    );
    if (mealType == null || !context.mounted) return;

    try {
      await ApiClient().dio.post(
        ApiEndpoints.mealLogs,
        data: {
          'user_id': user.id,
          'meal_type': mealType,
          'source': 'recipe',
          'food_name': recipe.recipeName,
          'calories': (nutrition['energy_kcal'] ?? 0),
          'protein': (nutrition['protein_g'] ?? 0),
          'carbs': (nutrition['carb_g'] ?? 0),
          'fat': (nutrition['fat_g'] ?? 0),
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

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
