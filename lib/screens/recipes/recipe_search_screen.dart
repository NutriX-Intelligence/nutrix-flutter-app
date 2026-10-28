import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/common/nx_select_field.dart';

// Canonical values the backend actually recognizes (app/services/classification_engine.py,
// app/services/optimization_engine.py) — see app/templates/index.html for the matching web UI.
const List<Map<String, String>> _dietOptions = [
  {'label': 'Any Diet', 'value': ''},
  {'label': 'Non-Vegetarian', 'value': 'Non-Vegetarian'},
  {'label': 'Eggetarian', 'value': 'Eggetarian'},
  {'label': 'Vegetarian', 'value': 'Vegetarian'},
  {'label': 'Jain Vegetarian', 'value': 'Jain'},
  {'label': 'Vegan', 'value': 'Vegan'},
];

const List<String> _cuisineOptions = [
  'Any Cuisine',
  'North Indian', 'South Indian', 'Gujarati', 'Punjabi', 'Maharashtrian',
  'Rajasthani', 'Bengali', 'Mughlai', 'Kashmiri',
  'Chinese', 'Italian', 'Mexican', 'Continental', 'Asian',
];

// max_cooking_time semantics per backend: 999 is a sentinel meaning "> 60 min",
// not a literal upper bound.
const List<Map<String, dynamic>> _cookingTimeOptions = [
  {'label': 'Any Cooking Time', 'value': null},
  {'label': '≤ 15 mins', 'value': 15},
  {'label': '≤ 30 mins', 'value': 30},
  {'label': '≤ 45 mins', 'value': 45},
  {'label': '≤ 60 mins', 'value': 60},
  {'label': '> 60 mins', 'value': 999},
];

class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final _ingredientsCtrl = TextEditingController();
  final _excludeCtrl = TextEditingController();

  String _selectedGoal = '';
  String _selectedDiet = '';
  String _selectedCuisine = 'Any Cuisine';
  int? _selectedCookingTime;
  int _topN = 10;

  @override
  void dispose() {
    _ingredientsCtrl.dispose();
    _excludeCtrl.dispose();
    super.dispose();
  }

  void _handleFindRecipes() {
    final ingredientsStr = _ingredientsCtrl.text.trim();
    if (ingredientsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one ingredient.')),
      );
      return;
    }

    final ingredients = ingredientsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one valid ingredient.')),
      );
      return;
    }

    final excludesStr = _excludeCtrl.text.trim();
    final excludes = excludesStr.isNotEmpty 
        ? excludesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() 
        : null;

    ref.read(recipeProvider.notifier).recommendRecipes(
      ingredients: ingredients,
      goal: _selectedGoal,
      dietType: _selectedDiet,
      cuisine: _selectedCuisine == 'Any Cuisine' ? '' : _selectedCuisine,
      excludeIngredients: excludes,
      maxCookingTime: _selectedCookingTime,
      topN: _topN,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find by Ingredients'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchConfigCard(),
            const SizedBox(height: 24),
            _buildRecommendedRecipesCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tell us what's in your kitchen — we'll match recipes to it.",
              style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text('Ingredients on Hand (Comma-Separated)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _ingredientsCtrl,
              decoration: const InputDecoration(hintText: 'e.g. paneer, tomato, rice, spinach'),
            ),
            const SizedBox(height: 16),
            Text('Exclude Ingredients (Comma-Separated, optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _excludeCtrl,
              decoration: const InputDecoration(hintText: 'e.g. mushroom, cashew'),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 14),
                title: Text('Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.textMain)),
                subtitle: Text(_activeFilterSummary(), style: TextStyle(fontSize: 11, color: context.textMuted)),
                children: [
                  _dropdownField(
                    label: 'Goal',
                    value: _selectedGoal,
                    items: const [
                      {'label': 'Any Goal', 'value': ''},
                      {'label': 'Weight Loss', 'value': 'weight loss'},
                      {'label': 'Muscle Gain', 'value': 'muscle gain'},
                      {'label': 'Weight Gain', 'value': 'weight gain'},
                      {'label': 'Maintenance', 'value': 'maintenance'},
                    ],
                    onChanged: (v) => setState(() => _selectedGoal = v),
                  ),
                  const SizedBox(height: 14),
                  _dropdownField(
                    label: 'Diet Type',
                    value: _selectedDiet,
                    items: _dietOptions,
                    onChanged: (v) => setState(() => _selectedDiet = v),
                  ),
                  const SizedBox(height: 14),
                  _dropdownField(
                    label: 'Cuisine',
                    value: _selectedCuisine,
                    items: _cuisineOptions.map((c) => {'label': c, 'value': c}).toList(),
                    onChanged: (v) => setState(() => _selectedCuisine = v),
                  ),
                  const SizedBox(height: 14),
                  _cookingTimeDropdown(),
                  const SizedBox(height: 14),
                  _dropdownField(
                    label: 'Results to Show',
                    value: _topN.toString(),
                    items: const [
                      {'label': 'Top 5', 'value': '5'},
                      {'label': 'Top 10', 'value': '10'},
                      {'label': 'Top 15', 'value': '15'},
                      {'label': 'Top 20', 'value': '20'},
                    ],
                    onChanged: (v) => setState(() => _topN = int.parse(v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleFindRecipes,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Find Recipes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activeFilterSummary() {
    final parts = <String>[];
    if (_selectedGoal.isNotEmpty) parts.add(_selectedGoal);
    if (_selectedDiet.isNotEmpty) parts.add(_selectedDiet);
    if (_selectedCuisine != 'Any Cuisine') parts.add(_selectedCuisine);
    if (_selectedCookingTime != null) {
      parts.add(_selectedCookingTime == 999 ? '> 60 min' : '≤ $_selectedCookingTime min');
    }
    parts.add('Top $_topN');
    return parts.join(' · ');
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        NxSelectField<String>(
          value: value,
          sheetTitle: label,
          options: items.map((e) => NxSelectOption<String>(value: e['value']!, title: e['label']!)).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _cookingTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cooking Time', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        NxSelectField<int?>(
          value: _selectedCookingTime,
          sheetTitle: 'Cooking time',
          options: _cookingTimeOptions
              .map((e) => NxSelectOption<int?>(value: e['value'] as int?, title: e['label'] as String))
              .toList(),
          onChanged: (v) => setState(() => _selectedCookingTime = v),
        ),
      ],
    );
  }

  Widget _buildRecommendedRecipesCard() {
    final recipeState = ref.watch(recipeProvider);

    if (recipeState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (recipeState.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: ${recipeState.error}', style: const TextStyle(color: AppColors.error)),
        ),
      );
    }

    if (recipeState.recipes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Enter your ingredients and click "Find Recipes" to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Recommended Recipes',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.textMain, letterSpacing: 0.2),
                  ),
                ),
                Text(
                  'Showing ${recipeState.recipes.length} of ${recipeState.totalResults} matches',
                  style: TextStyle(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipeState.recipes.length,
              itemBuilder: (context, index) {
                final r = recipeState.recipes[index];
                final matchPct = ((r['match_score'] ?? 0.0) as num).toDouble() * 100;
                final isHealthy = r['health_category'] == 'Healthy';
                final isUnhealthy = r['health_category'] == 'Unhealthy';
                final color = isHealthy
                    ? AppColors.healthy
                    : isUnhealthy
                        ? AppColors.unhealthy
                        : AppColors.moderate;

                final missing = r['ingredient_match']?['missing'] as List? ?? [];
                final extra = missing.isNotEmpty 
                    ? 'Additional: ${missing.take(3).join(', ')}${missing.length > 3 ? '...' : ''}' 
                    : 'All ingredients covered';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: context.cardBg,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => context.push('/recipe/${r['recipe_code']}'),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r['recipe_name'] ?? 'Unnamed Recipe',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${matchPct.round()}% Match',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Health Score: ${r['health_score']?.round() ?? '--'} (${r['health_category'] ?? '—'})', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(extra, style: TextStyle(fontSize: 12, color: context.textMuted)),
                        const SizedBox(height: 4),
                        if (r['reason'] != null)
                          Text(r['reason'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: context.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
