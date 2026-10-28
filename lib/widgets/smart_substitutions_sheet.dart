import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/substitution_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SmartSubstitutionsSheet extends ConsumerStatefulWidget {
  final List<String> ingredients;

  const SmartSubstitutionsSheet({
    super.key,
    required this.ingredients,
  });

  @override
  ConsumerState<SmartSubstitutionsSheet> createState() => _SmartSubstitutionsSheetState();
}

class _SmartSubstitutionsSheetState extends ConsumerState<SmartSubstitutionsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final dietType = user?.dietType ?? 'Any';
      if (dietType != 'Any') {
        ref.read(substitutionProvider.notifier).getSubstitutions(
              ingredients: widget.ingredients,
              targetDiet: dietType.toLowerCase(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(substitutionProvider);
    final user = ref.watch(authProvider).user;
    final dietType = user?.dietType ?? 'Any';

    if (dietType == 'Any') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Specific Diet Set',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to set a specific diet type (e.g., Jain, Keto, Vegan) in your profile to use Smart Substitutions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.inputBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_calls_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Substitutions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textMain,
                      ),
                    ),
                    Text(
                      'Tailored for your $dietType diet',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Error loading substitutions.\n${state.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            )
          else if (state.data == null || state.data!.substitutions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                    const SizedBox(height: 16),
                    Text(
                      'Perfect Match!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All ingredients in this recipe comply with your $dietType diet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textMuted),
                    ),
                  ],
                ),
              ).animate().fade().scale(),
            )
          else
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.data!.substitutions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.data!.substitutions[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Replace ${item.originalIngredient.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Detected: ${item.detectedTrigger} (Violates $dietType)',
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recommended Substitutes:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: context.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.recommendedSubstitutes.map((sub) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                sub,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                        ),
                        if (item.culinaryTip.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.inputBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 16, color: context.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.culinaryTip,
                                    style: TextStyle(fontSize: 13, color: context.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ).animate().fade(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2);
                },
              ),
            ),
        ],
      ),
    );
  }
}
