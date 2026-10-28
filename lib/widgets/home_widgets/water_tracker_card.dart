import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_provider.dart';

const List<Map<String, dynamic>> _quickAmounts = [
  {'label': '+250 ml', 'sub': 'Glass', 'ml': 250.0},
  {'label': '+500 ml', 'sub': 'Bottle', 'ml': 500.0},
  {'label': '+750 ml', 'sub': 'Sipper', 'ml': 750.0},
  {'label': '+1000 ml', 'sub': '1 Liter', 'ml': 1000.0},
];

class WaterTrackerCard extends ConsumerStatefulWidget {
  const WaterTrackerCard({super.key});

  @override
  ConsumerState<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends ConsumerState<WaterTrackerCard> {
  final _customController = TextEditingController();
  double? _pendingAmount;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _addWater(double amountMl) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _pendingAmount = amountMl);
    final success = await ref.read(waterProvider.notifier).addWater(user.id, amountMl);
    if (!mounted) return;
    setState(() => _pendingAmount = null);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${amountMl.round()} ml of water 💧'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref.read(waterProvider).error ?? 'Failed to log water intake.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _addCustomAmount() async {
    final amount = double.tryParse(_customController.text.trim());
    if (amount == null || amount <= 0 || amount > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount (1-10000 ml)')),
      );
      return;
    }
    _customController.clear();
    await _addWater(amount);
  }

  Future<void> _deleteLog(int logId) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    await ref.read(waterProvider.notifier).deleteLog(user.id, logId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterProvider);
    final progress = state.targetMl > 0 ? (state.totalMl / state.targetMl).clamp(0.0, 1.0) : 0.0;
    final remaining = (state.targetMl - state.totalMl).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text("Today's Water Intake", style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (state.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.totalMl.round()} / ${state.targetMl.round()} ml',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.info),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: context.inputBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            progress >= 1.0 ? "Target reached! 🎉" : '${remaining.round()} ml remaining',
            style: TextStyle(fontSize: 11, color: context.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Log Water',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((entry) {
              final ml = entry['ml'] as double;
              final isPending = _pendingAmount == ml;
              return OutlinedButton(
                onPressed: state.isLogging ? null : () => _addWater(ml),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: const BorderSide(color: AppColors.info, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: isPending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                      )
                    : Text('${entry['label']} (${entry['sub']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Custom amount (ml)...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: state.isLogging ? null : _addCustomAmount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (state.logs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Today's Entries",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted),
            ),
            const SizedBox(height: 8),
            ...state.logs.map((log) => _buildLogRow(log)),
          ],
        ],
      ),
    );
  }

  Widget _buildLogRow(dynamic log) {
    // Note: the backend stores `logged_at` as a date (no time-of-day), so
    // individual entries can only be distinguished by amount, not by time.
    final amount = double.tryParse(log['amount_ml'].toString()) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.info),
          const SizedBox(width: 8),
          Text('${amount.round()} ml', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMain)),
          const Spacer(),
          InkWell(
            onTap: () => _deleteLog(log['id'] as int),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: context.textDim),
            ),
          ),
        ],
      ),
    );
  }
}
