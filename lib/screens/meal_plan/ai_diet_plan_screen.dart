import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ai_plan_provider.dart';
import '../../widgets/common/nx_select_field.dart';
import '../../widgets/common/nx_markdown.dart';

class AiDietPlanScreen extends ConsumerStatefulWidget {
  const AiDietPlanScreen({super.key});

  @override
  ConsumerState<AiDietPlanScreen> createState() => _AiDietPlanScreenState();
}

class _AiDietPlanScreenState extends ConsumerState<AiDietPlanScreen> {
  String _goal = 'Weight Loss';
  String _dietType = 'Standard';

  void _generatePlan() {
    ref.read(aiPlanProvider.notifier).generateDietPlan(
      days: 1,
      goal: _goal.toLowerCase(),
      dietType: _dietType.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diet Plan Generator'),
        elevation: 0,
      ),
      body: state.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('AI is curating your personalized plan...', style: TextStyle(color: context.textMuted)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigForm(),
                  const SizedBox(height: 32),
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(state.error!, style: const TextStyle(color: AppColors.error)),
                    ),
                  if (state.dietPlan != null && state.dietPlan!.isNotEmpty)
                    _buildPlan(state.dietPlan!, state.planSource),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      color: context.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customize Your Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Text('Goal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 8),
            NxSelectField<String>(
              value: _goal,
              sheetTitle: 'Goal',
              options: ['Weight Loss', 'Muscle Gain', 'Maintenance']
                  .map((e) => NxSelectOption<String>(value: e, title: e))
                  .toList(),
              onChanged: (val) => setState(() => _goal = val),
            ),
            const SizedBox(height: 16),
            Text('Diet Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 8),
            NxSelectField<String>(
              value: _dietType,
              sheetTitle: 'Diet type',
              options: ['Standard', 'Vegetarian', 'Vegan', 'Keto']
                  .map((e) => NxSelectOption<String>(value: e, title: e))
                  .toList(),
              onChanged: (val) => setState(() => _dietType = val),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: _generatePlan,
                child: const Text('Generate Plan with AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The plan is one Markdown text. A small hint shows when the answer came from
  /// the limited local/offline mode instead of the main AI.
  Widget _buildPlan(String plan, String? source) {
    final limited = source == 'local' || source == 'offline';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Custom Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        if (limited) ...[
          const SizedBox(height: 8),
          Text(
            source == 'offline' ? 'Limited mode: a basic plan, the AI is unavailable right now.' : 'Limited mode: shorter answer from the backup model.',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: NxMarkdown(plan),
        ),
      ],
    );
  }
}
