import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/auth_provider.dart';

class AnalyticsHistoryScreen extends ConsumerStatefulWidget {
  const AnalyticsHistoryScreen({super.key});

  @override
  ConsumerState<AnalyticsHistoryScreen> createState() => _AnalyticsHistoryScreenState();
}

class _AnalyticsHistoryScreenState extends ConsumerState<AnalyticsHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  void _fetchLogs() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      // Today: no date (the server decides). A date is sent only for a day picked here.
      final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dateStr = isToday ? null : DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.read(analyticsProvider.notifier).fetchMealLogsForDate(user.id, dateStr);
    }
  }

  void _changeDate(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
    _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final dateStr = DateFormat('MMMM d, yyyy').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History Timeline'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(dateStr, isToday),
          const Divider(height: 1),
          Expanded(
            child: state.isLoadingBrowsedDate
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text(state.error!, style: const TextStyle(color: AppColors.error)))
                    : (state.browsedDateLogs == null || state.browsedDateLogs!.isEmpty)
                        ? Center(
                            child: Text(
                              'No meals logged on this date.',
                              style: TextStyle(color: context.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: state.browsedDateLogs!.length,
                            itemBuilder: (context, index) {
                              final log = state.browsedDateLogs![index];
                              return _buildLogCard(log);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String dateStr, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: context.cardBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
            color: AppColors.primary,
          ),
          Column(
            children: [
              Text(
                isToday ? 'Today' : dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!isToday)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _fetchLogs();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Back to Today', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : () => _changeDate(1),
            color: isToday ? context.borderColor : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      color: context.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    log['meal_type']?.toString().toUpperCase() ?? 'MEAL',
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${log['calories']?.round() ?? 0} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.calories),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              log['food_name'] ?? 'Unknown Food',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroItem('Protein', log['protein'] ?? 0, AppColors.protein),
                _buildMacroItem('Carbs', log['carbs'] ?? 0, AppColors.carbs),
                _buildMacroItem('Fat', log['fat'] ?? 0, AppColors.fat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, num value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        const SizedBox(height: 2),
        Text('${value.round()}g', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
