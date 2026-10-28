import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../widgets/common/nx_select_field.dart';

/// Photograph a nutrition label and extract its macros directly. Was
/// previously reachable only as the second tab of the barcode screen — now
/// its own destination from the Log chooser.
class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _foodNameController = TextEditingController();
  XFile? _selectedImage;
  String _mealType = 'Breakfast';

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(analyticsProvider.notifier).fetchSummary(user.id);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    ref.read(authProvider.notifier).ignoreNextLifecycleResume = true;
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null) return;
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(ocrProvider.notifier).uploadOcrImage(
        filePath: _selectedImage!.path,
        fileName: _selectedImage!.name,
        mealType: _mealType,
        foodName: _foodNameController.text,
        userId: user.id,
      );
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Snap a Label')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload a nutrition label image to extract macros and log it directly to your meals.',
              style: TextStyle(color: context.textMain, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('LABEL IMAGE FILE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedImage == null ? 'No image selected' : _selectedImage!.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: context.textMuted),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: Image.file(File(_selectedImage!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('MEAL TYPE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            NxSelectField<String>(
              value: _mealType,
              sheetTitle: 'Meal type',
              options: ['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((e) => NxSelectOption<String>(value: e, title: e)).toList(),
              onChanged: (val) => setState(() => _mealType = val),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('FOOD NAME (OPTIONAL)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _foodNameController,
              decoration: const InputDecoration(hintText: 'e.g. Scanned Oats'),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedImage == null || ocrState.isLoading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueAction),
                child: ocrState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Extract & Log Meal'),
              ),
            ),
            if (ocrState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(ocrState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (ocrState.ocrData != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        ocrState.ocrData!['status'] == 'success' ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ocrState.ocrData!['status'] == 'success' ? 'OCR Success!' : 'OCR Fallback',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (ocrState.ocrData!['meal_logged'] == true)
                      const Text('Logged to your meals successfully!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Text('Parsed Nutrition details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Calories: ${ocrState.ocrData!['parsed_nutrition']?['energy_kcal'] ?? 0} kcal'),
                    Text('Protein: ${ocrState.ocrData!['parsed_nutrition']?['protein_g'] ?? 0}g'),
                    Text('Carbs: ${ocrState.ocrData!['parsed_nutrition']?['carb_g'] ?? 0}g'),
                    Text('Fat: ${ocrState.ocrData!['parsed_nutrition']?['fat_g'] ?? 0}g'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
