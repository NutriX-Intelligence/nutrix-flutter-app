import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/homely_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_select_field.dart';
import 'homely_switcher.dart';

/// The interactive "Quick Build" flow — pick a base Indian meal, adjust
/// quantity and toppings, see macros live. Was the first of three tabs
/// crammed under a Log tab that was itself under a shell tab; now its own
/// destination, and a valid drop target for "Add to My Builder" from the
/// Community screen (see [initialBaseMealCode]).
class HomelyBuildScreen extends ConsumerStatefulWidget {
  const HomelyBuildScreen({super.key, this.initialBaseMealCode, this.initialQuantity});

  final String? initialBaseMealCode;
  final int? initialQuantity;

  @override
  ConsumerState<HomelyBuildScreen> createState() => _HomelyBuildScreenState();
}

class _HomelyBuildScreenState extends ConsumerState<HomelyBuildScreen> {
  String? _selectedBaseMealCode;
  int _quantity = 4;
  final Map<String, double> _condimentQuantities = {};
  String _selectedSlot = 'Lunch';

  @override
  void initState() {
    super.initState();
    _selectedBaseMealCode = widget.initialBaseMealCode;
    _quantity = widget.initialQuantity ?? 4;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Each visit to this route creates a fresh State, but the defaults
      // (and any synthetic "added from Community" meal) live in the shared
      // provider. Re-fetching unconditionally here would overwrite a
      // synthetic entry the Community screen just added a moment ago —
      // only fetch when nothing is loaded yet.
      final existing = ref.read(homelyBuilderProvider).defaults;
      final future = existing != null ? Future<void>.value() : ref.read(homelyBuilderProvider.notifier).fetchDefaults();
      future.then((_) {
        final defaultsState = ref.read(homelyBuilderProvider);
        if (defaultsState.defaults != null) {
          if (_selectedBaseMealCode == null) {
            final baseMeals = defaultsState.defaults!['base_meals'] as List;
            if (baseMeals.isNotEmpty) {
              setState(() => _selectedBaseMealCode = baseMeals[0]['code']);
            }
          }
          final condiments = defaultsState.defaults!['condiments'] as List;
          for (var c in condiments) {
            _condimentQuantities.putIfAbsent(c['id'], () => 0.0);
          }
        }
      });
    });
  }

  void _openAddToppingSheet(List condiments) {
    final selected = <String>{
      for (final c in condiments)
        if ((_condimentQuantities[c['id']] ?? 0.0) > 0) c['id'] as String,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: context.cardBg,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  top: AppSpacing.xl,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
                      alignment: Alignment.center,
                    ),
                    Text('Add Toppings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Tap to add or remove condiments from your plate.', style: TextStyle(fontSize: 12, color: context.textMuted)),
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.5),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: condiments.map<Widget>((c) {
                            final id = c['id'] as String;
                            final isSelected = selected.contains(id);
                            return GestureDetector(
                              onTap: () => sheetSetState(() {
                                if (isSelected) {
                                  selected.remove(id);
                                } else {
                                  selected.add(id);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : context.inputBg,
                                  borderRadius: AppRadius.pillAll,
                                  border: Border.all(color: isSelected ? AppColors.primary : context.borderColor, width: isSelected ? 1.4 : 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      c['name'] as String,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : context.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (final c in condiments) {
                              final id = c['id'] as String;
                              final wasActive = (_condimentQuantities[id] ?? 0.0) > 0;
                              final isNowSelected = selected.contains(id);
                              if (isNowSelected && !wasActive) {
                                _condimentQuantities[id] = 1.0;
                              } else if (!isNowSelected && wasActive) {
                                _condimentQuantities[id] = 0.0;
                              }
                            }
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(selected.isEmpty ? 'Done' : 'Done (${selected.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _calculateLiveMacros(Map<String, dynamic> defaults) {
    final baseMeals = defaults['base_meals'] as List;
    final condiments = defaults['condiments'] as List;

    final baseItem = baseMeals.firstWhere((m) => m['code'] == _selectedBaseMealCode, orElse: () => null);
    if (baseItem == null) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};

    final baseWeight = _quantity * (baseItem['unit_weight_g'] as num).toDouble();
    final baseNutrients = baseItem['nutrients_100g'] as Map<String, dynamic>;

    double calories = ((baseNutrients['energy_kcal'] as num).toDouble() * baseWeight) / 100.0;
    double protein = ((baseNutrients['protein_g'] as num).toDouble() * baseWeight) / 100.0;
    double carbs = ((baseNutrients['carb_g'] as num).toDouble() * baseWeight) / 100.0;
    double fat = ((baseNutrients['fat_g'] as num).toDouble() * baseWeight) / 100.0;

    for (var c in condiments) {
      final qty = _condimentQuantities[c['id']] ?? 0.0;
      if (qty > 0) {
        final weight = qty * (c['unit_weight_g'] as num).toDouble();
        final condNutrients = c['nutrients_100g'] as Map<String, dynamic>;
        calories += ((condNutrients['energy_kcal'] as num).toDouble() * weight) / 100.0;
        protein += ((condNutrients['protein_g'] as num).toDouble() * weight) / 100.0;
        carbs += ((condNutrients['carb_g'] as num).toDouble() * weight) / 100.0;
        fat += ((condNutrients['fat_g'] as num).toDouble() * weight) / 100.0;
      }
    }

    return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  void _logMeal(Map<String, dynamic> defaults, Map<String, double> liveMacros) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final baseMeals = defaults['base_meals'] as List;
    final baseItem = baseMeals.firstWhere((m) => m['code'] == _selectedBaseMealCode, orElse: () => null);
    if (baseItem == null) return;

    String mealDesc = '$_quantity ${baseItem['name']}';
    final condiments = defaults['condiments'] as List;
    for (var c in condiments) {
      final qty = _condimentQuantities[c['id']] ?? 0.0;
      if (qty > 0) mealDesc += ' + ${c['name']} ($qty ${c['unit']})';
    }

    final apiClient = ApiClient();
    final logPayload = {
      'user_id': user.id,
      'meal_type': _selectedSlot,
      'source': 'homely',
      'food_name': mealDesc,
      'calories': liveMacros['calories']!.roundToDouble(),
      'protein': liveMacros['protein']!.roundToDouble(),
      'carbs': liveMacros['carbs']!.roundToDouble(),
      'fat': liveMacros['fat']!.roundToDouble(),
    };

    try {
      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logPayload);
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged homely meal as $_selectedSlot successfully!'), backgroundColor: AppColors.primary),
      );
      setState(() {
        _quantity = 4;
        for (var key in _condimentQuantities.keys) {
          _condimentQuantities[key] = 0.0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(homelyBuilderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Build')),
      body: Column(
        children: [
          const HomelySwitcher(current: HomelySection.build),
          Expanded(
            child: builderState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : builderState.defaults == null
                    ? Center(
                        child: NxErrorState(
                          message: builderState.error ?? 'Could not load builder defaults.',
                          onRetry: () => ref.read(homelyBuilderProvider.notifier).fetchDefaults(),
                        ),
                      )
                    : _buildContent(builderState.defaults!),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> defaults) {
    final baseMeals = defaults['base_meals'] as List;
    final condiments = defaults['condiments'] as List;
    final liveMacros = _calculateLiveMacros(defaults);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a base Indian meal and adjust condiment sliders to dynamically calculate macros.',
            style: TextStyle(color: context.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          _inputLabel('BASE INDIAN MEAL'),
          const SizedBox(height: 8),
          NxSelectField<String>(
            value: _selectedBaseMealCode,
            sheetTitle: 'Choose a base meal',
            options: baseMeals
                .map<NxSelectOption<String>>((m) => NxSelectOption<String>(
                      value: m['code'] as String,
                      title: m['name'].toString(),
                      subtitle: '${(m['nutrients_100g']?['energy_kcal'] ?? 0).round()} kcal per 100 g',
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedBaseMealCode = val),
          ),
          const SizedBox(height: AppSpacing.xl),
          _inputLabel('QUANTITY (PIECES): $_quantity'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: context.borderColor,
              inactiveTrackColor: context.borderColor,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _quantity.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (val) => setState(() => _quantity = val.toInt()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _inputLabel('CONDIMENTS & ADD-ONS'),
          const SizedBox(height: AppSpacing.md),
          Builder(builder: (context) {
            final active = condiments.where((c) => (_condimentQuantities[c['id']] ?? 0.0) > 0).toList();
            if (active.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No toppings added yet — tap "Add Topping" to build your plate.',
                  style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.4),
                ),
              );
            }
            return Column(
              children: active.map<Widget>((c) {
                final val = _condimentQuantities[c['id']] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${c['name']} (${c['unit']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Text('${val.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.close_rounded, size: 16, color: context.textDim),
                              onPressed: () => setState(() => _condimentQuantities[c['id']] = 0.0),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: val,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (newVal) => setState(() => _condimentQuantities[c['id']] = newVal),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _openAddToppingSheet(condiments),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Topping'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(color: context.cardBg, border: Border.all(color: context.borderColor), borderRadius: AppRadius.mdAll),
            child: Column(
              children: [
                const Text('COMBINED LIVE NUTRITION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroStat('Calories (kcal)', '${liveMacros['calories']!.round()}', AppColors.primary),
                    _macroStat('Protein', '${liveMacros['protein']!.round()}g', AppColors.blueAction),
                    _macroStat('Carbs', '${liveMacros['carbs']!.round()}g', AppColors.calories),
                    _macroStat('Fat', '${liveMacros['fat']!.round()}g', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _inputLabel('MEAL SLOT'),
          const SizedBox(height: 8),
          NxSelectField<String>(
            value: _selectedSlot,
            sheetTitle: 'Meal slot',
            options: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                .map((e) => NxSelectOption<String>(value: e, title: e))
                .toList(),
            onChanged: (val) => setState(() => _selectedSlot = val),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _logMeal(defaults, liveMacros),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Log Homely Meal'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5));
  }

  Widget _macroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: context.textMuted)),
      ],
    );
  }
}
