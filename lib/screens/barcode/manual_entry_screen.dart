import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_meal_type_dialog.dart';

/// Manual product entry — the 12-field form used to be crammed inside a
/// card, inside a dropdown option, on the barcode screen. It's a
/// first-class flow (adding a product the backend has never seen), so it
/// gets a first-class route.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key, this.prefilledBarcode});

  final String? prefilledBarcode;

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  late final _barcodeCtrl = TextEditingController(text: widget.prefilledBarcode);
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _satFatCtrl = TextEditingController();

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientsCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sodiumCtrl.dispose();
    _sugarCtrl.dispose();
    _satFatCtrl.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(analyticsProvider.notifier).fetchSummary(user.id);
    }
  }

  void _submit() {
    final barcode = _barcodeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (barcode.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode number and product name are required.')),
      );
      return;
    }
    ref.read(barcodeProvider.notifier).submitManualBarcode(
          barcode: barcode,
          productName: name,
          brand: _brandCtrl.text.trim().isEmpty ? 'Unknown Brand' : _brandCtrl.text.trim(),
          ingredientsText: _ingredientsCtrl.text.trim(),
          calories: double.tryParse(_calCtrl.text) ?? 0,
          protein: double.tryParse(_protCtrl.text) ?? 0,
          carbs: double.tryParse(_carbCtrl.text) ?? 0,
          fat: double.tryParse(_fatCtrl.text) ?? 0,
          fiber: double.tryParse(_fiberCtrl.text) ?? 0,
          sodium: double.tryParse(_sodiumCtrl.text) ?? 0,
          sugar: double.tryParse(_sugarCtrl.text) ?? 0,
          saturatedFat: double.tryParse(_satFatCtrl.text) ?? 0,
        ).then((_) async {
      final state = ref.read(barcodeProvider);
      if (state.productData == null || !mounted) return;
      final mealType = await NxMealTypeDialog.show(
        context,
        itemLabel: state.productData!['name'] ?? name,
        confirmLabel: 'Log & Find Alternatives',
      );
      if (mealType == null || !mounted) return;
      final user = ref.read(authProvider).user;
      final nut = state.productData!['nutriments'] ?? {};
      if (user != null) {
        ref.read(barcodeProvider.notifier).logScannedMeal(
          userId: user.id,
          mealType: mealType,
          productName: "${state.productData!['name']} (${state.productData!['brand'] ?? 'Unknown Brand'})",
          calories: (nut['energy_kcal'] ?? 0.0).toDouble(),
          protein: (nut['protein_g'] ?? 0.0).toDouble(),
          carbs: (nut['carb_g'] ?? 0.0).toDouble(),
          fat: (nut['fat_g'] ?? 0.0).toDouble(),
        ).then((_) => _loadAnalytics());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final barcodeState = ref.watch(barcodeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add custom packaged food details and evaluate its health score immediately.',
              style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            _labeledField('Barcode Number *', _barcodeCtrl, hint: 'e.g. 8909999123456'),
            const SizedBox(height: AppSpacing.md),
            _labeledField('Product Name *', _nameCtrl, hint: 'e.g. Protein Granola Bar'),
            const SizedBox(height: AppSpacing.md),
            _labeledField('Brand', _brandCtrl, hint: 'e.g. Nature Organics'),
            const SizedBox(height: AppSpacing.md),
            _labeledField('Ingredients (comma separated)', _ingredientsCtrl, hint: 'e.g. Oats, Almonds, Honey'),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _labeledField('Calories (kcal)', _calCtrl, isNumber: true, hint: '400')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _labeledField('Protein (g)', _protCtrl, isNumber: true, hint: '15')),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _labeledField('Carbs (g)', _carbCtrl, isNumber: true, hint: '45')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _labeledField('Fat (g)', _fatCtrl, isNumber: true, hint: '12')),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _labeledField('Fiber (g)', _fiberCtrl, isNumber: true, hint: '2')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _labeledField('Sodium (mg)', _sodiumCtrl, isNumber: true, hint: '100')),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _labeledField('Sugar (g)', _sugarCtrl, isNumber: true, hint: '2')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _labeledField('Sat Fat (g)', _satFatCtrl, isNumber: true, hint: '1')),
            ]),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: barcodeState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: barcodeState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Save to Verified Database & Analyze',
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
              ),
            ),
            if (barcodeState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(barcodeState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController controller, {bool isNumber = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: context.textMuted, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: hint, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
        ),
      ],
    );
  }
}
