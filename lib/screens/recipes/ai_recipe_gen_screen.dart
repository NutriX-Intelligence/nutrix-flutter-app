import '../../widgets/common/nx_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_select_field.dart';

/// Generates a recipe from a free-text craving via `/api/ai/recipe-generator`
/// (already live on the backend). This screen used to fake it entirely —
/// a `Future.delayed` returning a hardcoded string with literal `\n`
/// escapes that rendered as visible backslash-n on screen.
class AiRecipeGenScreen extends ConsumerStatefulWidget {
  const AiRecipeGenScreen({super.key});

  @override
  ConsumerState<AiRecipeGenScreen> createState() => _AiRecipeGenScreenState();
}

class _AiRecipeGenScreenState extends ConsumerState<AiRecipeGenScreen> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String? _generatedRecipe;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.aiRecipeGenerator,
        data: {'ingredients': prompt},
      );
      final recipe = response.data['recipe']?.toString();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generatedRecipe = (recipe == null || recipe.trim().isEmpty) ? null : recipe;
        _error = recipe == null ? 'The AI returned an empty recipe. Try rephrasing your request.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not generate a recipe. Check your connection and try again.';
      });
    }
  }

  /// The backend returns free text, not structured macros — this is a
  /// best-effort extraction so the log dialog can pre-fill sensible
  /// defaults; the user can always correct them before logging.
  Map<String, double> _extractMacros(String text) {
    double find(String pattern) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      return match != null ? double.tryParse(match.group(1)!) ?? 0 : 0;
    }

    return {
      'calories': find(r'([\d.]+)\s*kcal'),
      'protein': find(r'([\d.]+)\s*g\s*protein'),
      'carbs': find(r'([\d.]+)\s*g\s*carbs?'),
      'fat': find(r'([\d.]+)\s*g\s*fats?'),
    };
  }

  String _extractName(String text) {
    final match = RegExp(r'recipe name\s*[:\-]\s*(.+)', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim() ?? 'AI Generated Recipe';
  }

  Future<void> _logRecipe() async {
    final recipe = _generatedRecipe;
    final user = ref.read(authProvider).user;
    if (recipe == null || user == null) return;

    final macros = _extractMacros(recipe);
    final nameCtrl = TextEditingController(text: _extractName(recipe));
    final calCtrl = TextEditingController(text: macros['calories']!.round().toString());
    final protCtrl = TextEditingController(text: macros['protein']!.round().toString());
    final carbCtrl = TextEditingController(text: macros['carbs']!.round().toString());
    final fatCtrl = TextEditingController(text: macros['fat']!.round().toString());
    var mealType = 'Lunch';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Log This Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The macros below are estimated from the AI's text — adjust if needed.",
                  style: TextStyle(fontSize: 12, color: dialogContext.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Recipe name', isDense: true)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories', isDense: true))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: TextField(controller: protCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)', isDense: true))),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)', isDense: true))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)', isDense: true))),
                ]),
                const SizedBox(height: AppSpacing.md),
                NxSelectField<String>(
                  value: mealType,
                  sheetTitle: 'Meal type',
                  options: ['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((e) => NxSelectOption<String>(value: e, title: e)).toList(),
                  onChanged: (val) => setDialogState(() => mealType = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log Meal')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiClient().dio.post(ApiEndpoints.mealLogs, data: {
        'user_id': user.id,
        'meal_type': mealType,
        'source': 'recipe',
        'food_name': nameCtrl.text.trim().isEmpty ? 'AI Generated Recipe' : nameCtrl.text.trim(),
        'calories': double.tryParse(calCtrl.text) ?? 0,
        'protein': double.tryParse(protCtrl.text) ?? 0,
        'carbs': double.tryParse(carbCtrl.text) ?? 0,
        'fat': double.tryParse(fatCtrl.text) ?? 0,
      });
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged as $mealType!'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Recipe Generator'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe what you want to eat, and our AI will instantly generate a custom recipe with macros.',
              style: TextStyle(color: context.textMuted, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. A high-protein vegetarian breakfast that takes under 15 minutes to make...',
                filled: true,
                fillColor: context.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateRecipe,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generating...' : 'Generate Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (_error != null) NxErrorState(message: _error!, onRetry: _generateRecipe),
            if (_generatedRecipe != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generated Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: AppSpacing.lg),
                    NxMarkdown(_generatedRecipe!),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logRecipe,
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Log This Recipe'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
