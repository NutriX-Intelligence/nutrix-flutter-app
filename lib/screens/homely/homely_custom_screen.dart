import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/homely_provider.dart';
import 'homely_switcher.dart';
import '../../widgets/common/nx_select_field.dart';

/// Build-your-own recipe from a raw ingredient list — a genuinely different
/// flow from Quick Build (compose-from-base), previously stacked directly
/// above it in one long scroll.
class HomelyCustomScreen extends ConsumerStatefulWidget {
  const HomelyCustomScreen({super.key});

  @override
  ConsumerState<HomelyCustomScreen> createState() => _HomelyCustomScreenState();
}

class _HomelyCustomScreenState extends ConsumerState<HomelyCustomScreen> {
  final _mealNameCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController(text: 'Indian');
  final _regionCtrl = TextEditingController();
  bool _isCommunity = true;

  final List<Map<String, dynamic>> _ingredientRows = [
    {'nameCtrl': TextEditingController(), 'qtyCtrl': TextEditingController(text: '100'), 'unit': 'grams'}
  ];

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _cuisineCtrl.dispose();
    _regionCtrl.dispose();
    for (var row in _ingredientRows) {
      row['nameCtrl'].dispose();
      row['qtyCtrl'].dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientRows.add({'nameCtrl': TextEditingController(), 'qtyCtrl': TextEditingController(text: '100'), 'unit': 'grams'});
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientRows.length > 1) {
      setState(() {
        _ingredientRows[index]['nameCtrl'].dispose();
        _ingredientRows[index]['qtyCtrl'].dispose();
        _ingredientRows.removeAt(index);
      });
    }
  }

  List<Map<String, dynamic>> _getIngredientsPayload() {
    return _ingredientRows.map((row) {
      return {
        'ingredient_name': (row['nameCtrl'] as TextEditingController).text.trim(),
        'amount': double.tryParse((row['qtyCtrl'] as TextEditingController).text) ?? 0.0,
        'unit': row['unit'],
      };
    }).toList();
  }

  void _calculateMacros() {
    final payload = _getIngredientsPayload();
    if (payload.any((i) => i['ingredient_name'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all ingredient names.')),
      );
      return;
    }
    ref.read(homelyCustomMealProvider.notifier).calculateMacros(payload);
  }

  void _saveMeal() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final name = _mealNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meal name.')),
      );
      return;
    }

    final ingredients = _getIngredientsPayload();
    if (ingredients.any((i) => i['ingredient_name'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all ingredient names.')),
      );
      return;
    }

    ref.read(homelyCustomMealProvider.notifier).createCustomMeal(
      name: name,
      cuisine: _cuisineCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      isCommunity: _isCommunity,
      ingredients: ingredients,
      userId: user.id,
    ).then((success) {
      if (success) {
        _mealNameCtrl.clear();
        _regionCtrl.clear();
        setState(() {
          _ingredientRows.clear();
          _ingredientRows.add({'nameCtrl': TextEditingController(), 'qtyCtrl': TextEditingController(text: '100'), 'unit': 'grams'});
        });
        ref.read(homelyCommunityProvider.notifier).searchMeals('');
        ref.read(homelyCommunityProvider.notifier).fetchPending();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customState = ref.watch(homelyCustomMealProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Recipe')),
      body: Column(
        children: [
          const HomelySwitcher(current: HomelySection.custom),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputLabel('MEAL NAME'),
            const SizedBox(height: 8),
            TextField(controller: _mealNameCtrl, decoration: const InputDecoration(hintText: 'e.g. Papad Churi / Ghee Rice')),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel('CUISINE'),
                      const SizedBox(height: 8),
                      TextField(controller: _cuisineCtrl, decoration: const InputDecoration(hintText: 'e.g. Indian')),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel('REGION (OPTIONAL)'),
                      const SizedBox(height: 8),
                      TextField(controller: _regionCtrl, decoration: const InputDecoration(hintText: 'e.g. Rajasthan')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => setState(() => _isCommunity = !_isCommunity),
              child: Row(
                children: [
                  Checkbox(
                    value: _isCommunity,
                    onChanged: (val) {
                      if (val != null) setState(() => _isCommunity = val);
                    },
                    activeColor: AppColors.blueAction,
                  ),
                  Expanded(
                    child: Text('Publish to Community Kitchen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.textMain)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Ingredients & Quantities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: AppSpacing.lg),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientRows.length,
              itemBuilder: (context, index) {
                final row = _ingredientRows[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: context.cardBg, border: Border.all(color: context.borderColor), borderRadius: AppRadius.mdAll),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row['nameCtrl'],
                              decoration: const InputDecoration(hintText: 'Ingredient e.g. Paneer', labelText: 'Ingredient Name', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error),
                            onPressed: () => _removeIngredientRow(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row['qtyCtrl'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Qty', labelText: 'Quantity', isDense: true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 3,
                            child: NxSelectField<String>(
                              compact: true,
                              value: row['unit'],
                              sheetTitle: 'Unit',
                              options: ['grams', 'ml', 'pieces'].map((e) => NxSelectOption<String>(value: e, title: e)).toList(),
                              onChanged: (v) => setState(() => row['unit'] = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: OutlinedButton(
                onPressed: _addIngredientRow,
                style: OutlinedButton.styleFrom(side: BorderSide(color: context.borderColor), foregroundColor: context.textMain),
                child: const Text('+ Add Ingredient'),
              ),
            ),
            if (customState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(customState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (customState.successMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(customState.successMessage!, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
            if (customState.calculatedMacros != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CALCULATED TOTAL MACROS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _totalMacroItem('Calories', '${customState.calculatedMacros!['totals']?['energy_kcal']?.round() ?? 0} kcal'),
                        _totalMacroItem('Protein', '${customState.calculatedMacros!['totals']?['protein_g'] ?? 0}g'),
                        _totalMacroItem('Carbs', '${customState.calculatedMacros!['totals']?['carb_g'] ?? 0}g'),
                        _totalMacroItem('Fat', '${customState.calculatedMacros!['totals']?['fat_g'] ?? 0}g'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: customState.isLoading ? null : _calculateMacros,
                icon: const Icon(Icons.flash_on, size: 18),
                label: customState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Calculate Macros'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: customState.isSaving ? null : _saveMeal,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: customState.isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save & Publish Meal'),
              ),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5));
  }

  Widget _totalMacroItem(String label, String val) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          Text(label, style: TextStyle(fontSize: 10, color: context.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
