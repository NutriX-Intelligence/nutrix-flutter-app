import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_meal_type_dialog.dart';
import '../../widgets/common/nx_segmented.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

// Real product codes, matching app/templates/index.html's own quick-test
// list, so they actually resolve against the backend's product cache.
const List<Map<String, String>> quickTestBarcodes = [
  {'code': '8901058852712', 'label': 'Maggi Noodles', 'emoji': '🍜'},
  {'code': '8901262010052', 'label': 'Amul Butter', 'emoji': '🧈'},
  {'code': '8901491101835', 'label': "Lay's Magic Masala", 'emoji': '🥔'},
  {'code': '8901719101037', 'label': 'Parle-G', 'emoji': '🍪'},
  {'code': '5449000000996', 'label': 'Coca-Cola', 'emoji': '🥤'},
  {'code': '8000500310427', 'label': 'Nutella', 'emoji': '🍫'},
  {'code': '1234567890123', 'label': 'NutriX Muesli', 'emoji': '🥣'},
  {'code': '8904063200143', 'label': "Haldiram's Bhujia", 'emoji': '🥨'},
];

/// Camera-first barcode scanning. Used to be one of four options inside a
/// dropdown buried in a card — that dropdown was navigation disguised as a
/// form control. Camera, Type number, and Upload are now equal, visible
/// options; Manual Entry (a 12-field form) gets its own route entirely,
/// reached via the link at the bottom.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _barcodeInputController = TextEditingController();

  // 'camera' | 'upload' | 'number'
  String _mode = 'camera';
  XFile? _selectedImage;

  @override
  void dispose() {
    _barcodeInputController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(analyticsProvider.notifier).fetchSummary(user.id);
    }
  }

  Future<void> _startCameraScan() async {
    ref.read(authProvider.notifier).ignoreNextLifecycleResume = true;
    var res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
    );
    if (res is String && res != '-1' && res.isNotEmpty) {
      _barcodeInputController.text = res;
      _handleLookup(res);
    }
  }

  void _handleLookup(String barcode) {
    ref.read(barcodeProvider.notifier).lookupBarcode(barcode).then((_) {
      final state = ref.read(barcodeProvider);
      if (state.productData != null) {
        _showMealTypePicker(state.productData!);
      } else if (state.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product not found — you can add it manually.'),
            action: SnackBarAction(label: 'Enter manually', onPressed: () => context.push('/manual-entry', extra: barcode)),
          ),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    ref.read(authProvider.notifier).ignoreNextLifecycleResume = true;
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _handleImageUpload() async {
    if (_selectedImage == null) return;
    final user = ref.read(authProvider).user;
    await ref.read(barcodeProvider.notifier).scanBarcodeImage(
          filePath: _selectedImage!.path,
          fileName: _selectedImage!.name,
          userId: user?.id,
        );
    final state = ref.read(barcodeProvider);
    if (state.productData != null) _showMealTypePicker(state.productData!);
  }

  void _showMealTypePicker(Map<String, dynamic> product) async {
    final mealType = await NxMealTypeDialog.show(
      context,
      itemLabel: product['name'] ?? 'Product',
      confirmLabel: 'Log & Find Alternatives',
    );
    if (mealType == null || !mounted) return;
    final user = ref.read(authProvider).user;
    final nut = product['nutriments'] ?? {};
    if (user != null) {
      ref.read(barcodeProvider.notifier).logScannedMeal(
        userId: user.id,
        mealType: mealType,
        productName: "${product['name']} (${product['brand'] ?? 'Unknown Brand'})",
        calories: (nut['energy_kcal'] ?? 0.0).toDouble(),
        protein: (nut['protein_g'] ?? 0.0).toDouble(),
        carbs: (nut['carb_g'] ?? 0.0).toDouble(),
        fat: (nut['fat_g'] ?? 0.0).toDouble(),
      ).then((_) => _loadAnalytics());
    }
  }

  @override
  Widget build(BuildContext context) {
    final barcodeState = ref.watch(barcodeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NxSegmented<String>(
              values: const ['camera', 'number', 'upload'],
              selected: _mode,
              labelBuilder: (v) => switch (v) { 'camera' => 'Camera', 'number' => 'Type number', _ => 'Upload' },
              onChanged: (v) => setState(() => _mode = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_mode == 'camera') _buildCameraMode(),
            if (_mode == 'upload') _buildUploadMode(barcodeState),
            if (_mode == 'number') _buildNumberMode(barcodeState),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => context.push('/manual-entry'),
                child: const Text('Prefer to enter details manually?'),
              ),
            ),
            if (barcodeState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(barcodeState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            ],
            if (barcodeState.logSuccessMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(barcodeState.logSuccessMessage!, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold))),
                ]),
              ),
            ],
            if (barcodeState.productData != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildProductResult(barcodeState.productData!),
            ],
            if (barcodeState.alternatives != null && barcodeState.alternatives!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'RECOMMENDED HEALTHIER ALTERNATIVES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary, letterSpacing: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Column(children: barcodeState.alternatives!.map<Widget>(_alternativeCard).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraMode() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColors.blueAction),
          const SizedBox(height: AppSpacing.md),
          Text('Align the barcode inside the camera frame to scan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _startCameraScan,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Camera Scanner'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadMode(BarcodeState barcodeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: AppRadius.mdAll,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
            child: _selectedImage == null
                ? Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.blueAction),
                      const SizedBox(height: 8),
                      const Text('Upload or choose a packaging photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Auto-detects the barcode from the photo', style: TextStyle(fontSize: 11, color: context.textMuted)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.file(File(_selectedImage!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _selectedImage == null || barcodeState.isLoading ? null : _handleImageUpload,
            child: barcodeState.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Scan Photo'),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberMode(BarcodeState barcodeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK TEST BARCODES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickTestBarcodes.map((p) {
            return GestureDetector(
              onTap: () {
                _barcodeInputController.text = p['code']!;
                _handleLookup(p['code']!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.pillAll, border: Border.all(color: context.borderColor)),
                child: Text('${p['emoji']} ${p['label']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMain)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('PRODUCT BARCODE NUMBER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _barcodeInputController,
                decoration: const InputDecoration(hintText: 'e.g. 8901058852712'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: barcodeState.isLoading ? null : () => _handleLookup(_barcodeInputController.text),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              child: barcodeState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Lookup'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductResult(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product['product_name'] ?? product['name'] ?? 'Unknown Product',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
                child: Text(
                  (product['source'] ?? 'Cached').toString().toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Brand: ${product['brand'] ?? '—'} | Grade: ${(product['nutrition_grade'] ?? '—').toString().toUpperCase()}'),
          const SizedBox(height: 4),
          Text(
            'Health Score: ${product['health_score'] != null ? product['health_score'].round() : '—'} (${product['health_category'] ?? '—'})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purpleAction),
          ),
          const SizedBox(height: 12),
          Divider(color: context.borderColor),
          const SizedBox(height: 8),
          Text('NUTRITION PER 100G', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textMuted)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutritionGridItem('Energy', '${(product['nutriments']?['energy_kcal'] ?? 0).round()} kcal'),
              _nutritionGridItem('Protein', '${product['nutriments']?['protein_g'] ?? 0}g'),
              _nutritionGridItem('Carbs', '${product['nutriments']?['carb_g'] ?? 0}g'),
              _nutritionGridItem('Fat', '${product['nutriments']?['fat_g'] ?? 0}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionGridItem(String label, String val) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(color: context.cardBg, border: Border.all(color: context.borderColor), borderRadius: AppRadius.smAll),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMain), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: context.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _alternativeCard(dynamic alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(border: Border.all(color: context.borderColor), borderRadius: AppRadius.mdAll, color: context.cardBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(alt['name'] ?? 'Alternative', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(width: 8),
              Text('Rs. ${alt['price'] ?? '--'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories)),
            ],
          ),
          const SizedBox(height: 6),
          Text(alt['reason'] ?? '', style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 4),
          Text(alt['comparison'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
