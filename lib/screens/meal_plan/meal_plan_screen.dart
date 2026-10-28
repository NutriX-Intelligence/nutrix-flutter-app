import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../models/meal_plan.dart';
import '../../widgets/common/nx_select_field.dart';

const List<String> _mealPlanCuisines = [
  'Any Cuisine',
  'North Indian', 'South Indian', 'Gujarati', 'Punjabi', 'Maharashtrian',
  'Rajasthani', 'Bengali', 'Mughlai', 'Kashmiri',
  'Chinese', 'Italian', 'Mexican', 'Continental', 'Asian',
];

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  String _preference = 'balanced';
  DateTime _planDate = DateTime.now();
  bool _planDatePicked = false; // false = today: no date is sent, the server decides
  final Map<String, String> _slotCuisines = {'Breakfast': 'Any Cuisine', 'Lunch': 'Any Cuisine', 'Dinner': 'Any Cuisine', 'Snack': 'Any Cuisine'};
  final Set<String> _loggingSlots = {};
  bool _isLoggingAll = false;

  // Once a plan exists, the config that produced it collapses into a
  // summary bar — re-scrolling past the whole 4-section form just to see
  // your own plan was the exact complaint. Starts expanded (nothing to
  // summarize yet); flips false right after a successful generate.
  bool _configExpanded = true;

  final _preferences = [
    {'key': 'balanced', 'label': 'Balanced', 'icon': Icons.balance_rounded, 'color': AppColors.primary},
    {'key': 'high_protein', 'label': 'High Protein', 'icon': Icons.fitness_center_rounded, 'color': AppColors.protein},
    {'key': 'low_carb', 'label': 'Low Carb', 'icon': Icons.grass_rounded, 'color': AppColors.accent},
    {'key': 'low_fat', 'label': 'Low Fat', 'icon': Icons.water_drop_rounded, 'color': AppColors.info},
    {'key': 'high_fiber', 'label': 'High Fiber', 'icon': Icons.eco_rounded, 'color': AppColors.fiber},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(mealPlanHistoryProvider.notifier).fetchHistory(user.id);
      }
    });
  }

  void _onAuthReady(AuthState? previous, AuthState next) {
    if (previous?.user == null && next.user != null) {
      ref.read(mealPlanHistoryProvider.notifier).fetchHistory(next.user!.id);
    }
  }

  Future<void> _pickPlanDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _planDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _planDate = picked;
        _planDatePicked = true;
      });
    }
  }

  Map<String, String> get _mealCuisinesPayload {
    final payload = <String, String>{};
    _slotCuisines.forEach((slot, cuisine) {
      if (cuisine != 'Any Cuisine') payload[slot] = cuisine;
    });
    return payload;
  }

  String get _preferenceLabel => (_preferences.firstWhere((p) => p['key'] == _preference))['label'] as String;

  Future<void> _generate(int userId) async {
    await ref.read(mealPlanProvider.notifier).generatePlan(
          userId,
          _preference,
          planDate: _planDatePicked ? _planDate : null,
          mealCuisines: _mealCuisinesPayload,
        );
    if (mounted && ref.read(mealPlanProvider).value != null) {
      setState(() => _configExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, _onAuthReady);
    final mealPlanState = ref.watch(mealPlanProvider);
    final user = ref.watch(authProvider).user;
    final hasPlan = mealPlanState.value != null;
    final showConfig = !hasPlan || _configExpanded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              if (showConfig) ..._buildConfigSection(context, mealPlanState, user)
              else ...[
                _buildConfigSummaryBar(context),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Results
              mealPlanState.when(
                loading: () => _buildLoadingPlaceholder(),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Could not generate a plan. Try different preferences or adjust your targets.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                data: (plan) {
                  if (plan == null) {
                    return _buildEmptyState(context);
                  }
                  return _buildMealPlanResult(context, plan);
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),
              _buildHistorySection(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildConfigSection(BuildContext context, AsyncValue<MealPlan?> mealPlanState, dynamic user) {
    return [
      Text(
        'AI-optimized daily meal plan using OR-Tools solver',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.xxl),

      // Preference selector
      Text('Dietary Preference', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _preferences.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final pref = _preferences[index];
            final selected = _preference == pref['key'];
            final color = pref['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _preference = pref['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.15) : context.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : context.borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(pref['icon'] as IconData, color: color, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      pref['label'] as String,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),

      Text('Plan Date', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      InkWell(
        onTap: _pickPlanDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: context.textMuted),
              const SizedBox(width: 10),
              Text(DateFormat('EEEE, d MMM yyyy').format(_planDate), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),

      Text('Customize Cuisine per Meal Slot (Optional)', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      // Was a 2x2 GridView at childAspectRatio 2.6 — every label truncated
      // ("Breakfast: North In..."). Full-width rows give each one room.
      Column(
        children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
            .map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _slotCuisineDropdown(slot),
                ))
            .toList(),
      ),
      const SizedBox(height: AppSpacing.md),

      // Generate Button
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: mealPlanState.isLoading || user == null ? null : () => _generate(user.id),
          icon: mealPlanState.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(mealPlanState.isLoading ? 'Generating...' : 'Generate Meal Plan'),
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
    ];
  }

  Widget _buildConfigSummaryBar(BuildContext context) {
    final cuisineCount = _mealCuisinesPayload.length;
    final summary = [
      _preferenceLabel,
      DateFormat('d MMM').format(_planDate),
      if (cuisineCount > 0) '$cuisineCount cuisine${cuisineCount == 1 ? '' : 's'}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 16, color: context.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(summary, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textMain))),
          TextButton(
            onPressed: () => setState(() => _configExpanded = true),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('Edit', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _slotCuisineDropdown(String slot) {
    // The slot prefix shows in the closed field so you can tell which slot
    // this is; the open list shows only the cuisine names.
    return NxSelectField<String>(
      compact: true,
      prefix: '$slot: ',
      value: _slotCuisines[slot],
      sheetTitle: '$slot cuisine',
      options: _mealPlanCuisines.map((c) => NxSelectOption<String>(value: c, title: c)).toList(),
      onChanged: (val) => setState(() => _slotCuisines[slot] = val),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final historyState = ref.watch(mealPlanHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Meal Plan History', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () {
                final user = ref.read(authProvider).user;
                if (user != null) ref.read(mealPlanHistoryProvider.notifier).fetchHistory(user.id);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        historyState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load meal plan history.', style: TextStyle(color: context.textMuted, fontSize: 12)),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No saved plans yet.', style: TextStyle(color: context.textMuted, fontSize: 12)),
              );
            }
            return Column(
              children: items.map<Widget>((item) {
                final meals = [item['breakfast_recipe_name'], item['lunch_recipe_name'], item['dinner_recipe_name'], item['snack_recipe_name']]
                    .where((m) => m != null && m.toString().isNotEmpty)
                    .join(' · ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['plan_date']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (meals.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meals, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      if (item['actual_calories'] != null) ...[
                        const SizedBox(height: 4),
                        Text('${(item['actual_calories'] as num).round()} kcal', style: const TextStyle(fontSize: 11, color: AppColors.calories, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.restaurant_menu_rounded, size: 64, color: context.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No meal plan yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Generate a personalized plan above',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }

  Future<bool> _logMeal(MealItem meal, String slot, {bool silent = false}) async {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    final key = '$slot:${meal.recipeCode}';
    setState(() => _loggingSlots.add(key));
    try {
      await ApiClient().dio.post(
        ApiEndpoints.mealLogs,
        data: {
          'user_id': user.id,
          if (_planDatePicked) 'log_date': DateFormat('yyyy-MM-dd').format(_planDate),
          'meal_type': slot,
          'source': 'recipe',
          'food_name': meal.recipeName,
          'calories': meal.calories,
          'protein': meal.proteinG,
          'carbs': meal.carbsG,
          'fat': meal.fatG,
        },
      );
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id);
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged $slot: ${meal.recipeName}'), backgroundColor: AppColors.primary),
        );
      }
      return true;
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log $slot: $e'), backgroundColor: AppColors.error),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _loggingSlots.remove(key));
    }
  }

  Future<void> _logAllMeals(MealPlan plan) async {
    setState(() => _isLoggingAll = true);
    var succeeded = 0;
    final entries = plan.meals.entries.toList();
    for (final entry in entries) {
      final ok = await _logMeal(entry.value, entry.key, silent: true);
      if (ok) succeeded++;
    }
    if (!mounted) return;
    setState(() => _isLoggingAll = false);
    final allOk = succeeded == entries.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allOk ? 'Logged all ${entries.length} meals!' : 'Logged $succeeded of ${entries.length} meals.'),
        backgroundColor: allOk ? AppColors.primary : AppColors.warning,
      ),
    );
  }

  Widget _buildMealPlanResult(BuildContext context, MealPlan plan) {
    final slots = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final slotIcons = {
      'Breakfast': Icons.free_breakfast_rounded,
      'Lunch': Icons.lunch_dining_rounded,
      'Dinner': Icons.dinner_dining_rounded,
      'Snack': Icons.icecream_rounded,
    };
    final slotColors = {
      'Breakfast': AppColors.warning,
      'Lunch': AppColors.accent,
      'Dinner': AppColors.primary,
      'Snack': AppColors.accentPink,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Plan', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _isLoggingAll ? null : () => _logAllMeals(plan),
              icon: _isLoggingAll
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: Text(_isLoggingAll ? 'Logging...' : 'Log All Meals'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ...slots.asMap().entries.map((entry) {
          final i = entry.key;
          final slot = entry.value;
          final meal = plan.meals[slot];
          final color = slotColors[slot] ?? AppColors.primary;
          final icon = slotIcons[slot] ?? Icons.restaurant;
          final isLogging = meal != null && _loggingSlots.contains('$slot:${meal.recipeCode}');

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: meal == null ? null : () => context.push('/recipe/${meal.recipeCode}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meal?.recipeName ?? 'No recipe assigned',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (meal != null)
                          Text(
                            '${meal.calories.toInt()} kcal · P${meal.proteinG.toInt()}g · C${meal.carbsG.toInt()}g · F${meal.fatG.toInt()}g',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  if (meal != null)
                    IconButton(
                      onPressed: isLogging ? null : () => _logMeal(meal, slot),
                      icon: isLogging
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.add_circle_outline_rounded, color: color),
                      tooltip: 'Log $slot',
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (200 + 100 * i).ms, duration: 400.ms).slideX(begin: 0.05);
        }),

        const SizedBox(height: 16),

        // Totals Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textMain)),
              const SizedBox(height: 12),
              _totalRow('Calories', plan.totals['calories'] ?? 0, plan.targets['calories'] ?? 0, AppColors.calories),
              _totalRow('Protein', plan.totals['protein_g'] ?? 0, plan.targets['protein_g'] ?? 0, AppColors.protein),
              _totalRow('Carbs', plan.totals['carbs_g'] ?? 0, plan.targets['carbs_g'] ?? 0, AppColors.carbs),
              _totalRow('Fat', plan.totals['fat_g'] ?? 0, plan.targets['fat_g'] ?? 0, AppColors.fat),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
      ],
    );
  }

  Widget _totalRow(String label, double actual, double target, Color color) {
    final percent = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: context.textMuted, fontSize: 13)),
              Text(
                '${actual.toInt()} / ${target.toInt()}',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
