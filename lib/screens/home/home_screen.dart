import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/home_widgets/weight_chart_widget.dart';
import '../../widgets/home_widgets/water_tracker_card.dart';
import '../../widgets/home_widgets/weekly_trends_card.dart';
import '../../widgets/home_widgets/macro_rings_card.dart';
import '../../widgets/common/nx_card.dart';
import '../../widgets/common/nx_skeleton.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_empty_state.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/services/widget_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Meals the smart scale logs on its own are written straight to the account's
  // diary on the server. Home polls quietly so they show up without a tap.
  Timer? _scalePoll;

  void _startScalePoll() {
    _scalePoll?.cancel();
    _scalePoll = Timer.periodic(const Duration(seconds: 5), (_) {
      final user = ref.read(authProvider).user;
      if (!mounted || user == null) return;
      ref.read(analyticsProvider.notifier).fetchMealLogs(user.id, silent: true);
    });
  }

  Future<void> _fetchAll(int userId) async {
    final user = ref.read(authProvider).user;
    await Future.wait([
      ref.read(analyticsProvider.notifier).fetchSummary(userId),
      ref.read(analyticsProvider.notifier).fetchMealLogs(userId),
      ref.read(waterProvider.notifier).fetchToday(userId),
      ref.read(profileProvider.notifier).fetchWeightHistory(),
    ]);

    // The launcher-widget refresh has nothing to do with what's on screen —
    // it fires up to ~31 concurrent requests to build the activity
    // calendar. Letting it start only after the dashboard's own data has
    // already landed keeps it from competing for bandwidth with the data
    // the user is actually waiting to see.
    if (user != null) {
      unawaited(WidgetService.updateContributionWidgetFromBackend(
        userId: userId,
        targetCalories: user.targetCalories,
        targetProtein: user.targetProtein,
      ));
    }
  }

  @override
  void dispose() {
    _scalePoll?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startScalePoll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auth may not have resolved yet on a cold start (token check +
      // optional biometric prompt + /api/auth/me are all async) — if `user`
      // is still null here, the `ref.listen` below in build() catches the
      // moment it becomes available instead.
      final user = ref.read(authProvider).user;
      if (user != null) _fetchAll(user.id);
    });
  }

  void _openWeightLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: context.cardBg,
      builder: (_) => const _WeightLogSheet(),
    );
  }

  void _openWaterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: context.cardBg,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: sheetContext.borderColor, borderRadius: BorderRadius.circular(2)),
                ),
                const WaterTrackerCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fires once auth actually resolves, covering the cold-start race where
    // initState ran before the user was loaded.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        _fetchAll(next.user!.id);
      }
    });

    final user = ref.watch(authProvider).user;
    final analyticsState = ref.watch(analyticsProvider);

    // A skeleton only makes sense before any data has ever arrived — once
    // loaded, a background refresh (pull-to-refresh, or returning from
    // logging something) shouldn't blank the dashboard again.
    final isFirstLoad = analyticsState.isLoading && analyticsState.summaryData == null && analyticsState.mealLogs == null;
    final firstLoadFailed = analyticsState.error != null && analyticsState.summaryData == null && analyticsState.mealLogs == null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) await _fetchAll(user.id);
          },
          child: isFirstLoad
              ? _buildSkeleton()
              : firstLoadFailed
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: NxErrorState(
                        message: analyticsState.error!,
                        onRetry: user != null ? () => _fetchAll(user.id) : null,
                      ),
                    )
                  : _buildDashboard(context),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      children: const [
        NxCardSkeleton(height: 210),
        SizedBox(height: AppSpacing.xxl),
        NxCardSkeleton(lines: 2, height: 110),
        SizedBox(height: AppSpacing.xxl),
        NxCardSkeleton(lines: 2, height: 110),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final user = ref.watch(authProvider).user;
    final totals = analyticsState.mealLogTotals;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayHeader(context),
          const SizedBox(height: AppSpacing.xxl),
          MacroRingsCard(
            calories: (totals?['calories'] as num?)?.toDouble() ?? 0,
            maxCalories: user?.targetCalories ?? 2000,
            protein: (totals?['protein'] as num?)?.toDouble() ?? 0,
            maxProtein: user?.targetProtein ?? 120,
            carbs: (totals?['carbs'] as num?)?.toDouble() ?? 0,
            maxCarbs: user?.targetCarbs ?? 250,
            fat: (totals?['fat'] as num?)?.toDouble() ?? 0,
            maxFat: user?.targetFat ?? 60,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildWaterCompact(context),
          const SizedBox(height: AppSpacing.xxl),
          _buildWeightCompact(context),
          const SizedBox(height: AppSpacing.xxl),
          const WeeklyTrendsCard(),
          const SizedBox(height: AppSpacing.xxl),
          _buildTodaysLoggedItems(context),
          const SizedBox(height: AppSpacing.xxl),
          _buildQuickActionsGrid(context),
        ],
      ),
    );
  }

  Widget _buildTodayHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Today', style: Theme.of(context).textTheme.headlineMedium),
        Text(DateFormat('EEE, d MMM').format(DateTime.now()), style: TextStyle(fontSize: 13, color: context.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWaterCompact(BuildContext context) {
    final state = ref.watch(waterProvider);
    final progress = state.targetMl > 0 ? (state.totalMl / state.targetMl).clamp(0.0, 1.0) : 0.0;

    return NxCard(
      onTap: _openWaterSheet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text('Water', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: context.textMain)),
              const Spacer(),
              Text('${state.totalMl.round()} / ${state.targetMl.round()} ml', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.info)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 18, color: context.textDim),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: context.borderColor, valueColor: const AlwaysStoppedAnimation(AppColors.info)),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: state.isLogging
                  ? null
                  : () {
                      final user = ref.read(authProvider).user;
                      if (user != null) ref.read(waterProvider.notifier).addWater(user.id, 250.0);
                    },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.info, side: const BorderSide(color: AppColors.info, width: 1.2)),
              child: const Text('+250 ml', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCompact(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final history = profileState.weightHistory;

    return NxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.purpleAction, size: 18),
              const SizedBox(width: 8),
              Text('Weight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: context.textMain)),
              const Spacer(),
              TextButton(
                onPressed: _openWeightLogSheet,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Log ›', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (history == null || history.isEmpty)
            NxEmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'Log your first weight',
              subtitle: 'Track your progress over time.',
              actionLabel: 'Log Weight',
              onAction: _openWeightLogSheet,
            )
          else
            Builder(builder: (context) {
              // Backend returns most-recent-first; reverse to chronological ascending for the chart/stats.
              final ascending = history.reversed.toList();
              final weights = ascending.map((e) => (e['weight'] as num).toDouble()).toList();
              final dates = ascending.map((e) => DateTime.parse(e['logged_at'].toString())).toList();

              final current = weights.last;
              final starting = weights.first;
              final netChange = current - starting;
              final weeklyRate = analyticsState.summaryData?['weight_stats']?['rate_kg_per_week'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _weightStatTile(context, 'Current', '${current.toStringAsFixed(1)} kg'),
                      const SizedBox(width: AppSpacing.sm),
                      _weightStatTile(context, 'Starting', '${starting.toStringAsFixed(1)} kg'),
                      const SizedBox(width: AppSpacing.sm),
                      _weightStatTile(
                        context,
                        'Net Change',
                        '${netChange >= 0 ? '+' : ''}${netChange.toStringAsFixed(1)} kg',
                        color: netChange > 0 ? AppColors.warning : (netChange < 0 ? AppColors.primary : null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _weightStatTile(
                        context,
                        'Weekly Rate',
                        weeklyRate != null ? '${(weeklyRate as num) >= 0 ? '+' : ''}${weeklyRate.toStringAsFixed(2)} kg' : '—',
                        color: AppColors.purpleAction,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  WeightChartWidget(weightHistory: weights, dates: dates, currentWeight: current),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _weightStatTile(BuildContext context, String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.smAll, border: Border.all(color: context.borderColor)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color ?? context.textMain), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: context.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static const _todaysLoggedItemsCap = 5;

  Widget _buildTodaysLoggedItems(BuildContext context) {
    final logs = ref.watch(analyticsProvider).mealLogs ?? [];
    // Most-recently-logged first, capped so this section can't grow the
    // page indefinitely as more meals get logged today — full history
    // (today or any other day) already lives at /history.
    final recent = logs.length > _todaysLoggedItemsCap
        ? logs.reversed.take(_todaysLoggedItemsCap).toList()
        : logs.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Logged Items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textMain, letterSpacing: -0.2),
            ),
            if (logs.length > _todaysLoggedItemsCap)
              TextButton(
                onPressed: () => context.push('/history'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: const Text('View all', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Text(
              "No meals logged yet today — scan a barcode, build a homely meal, or log a recipe to see it here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 13, height: 1.5),
            ),
          )
        else
          ...recent.map((log) => _todaysLogCard(context, log)),
      ],
    );
  }

  Widget _todaysLogCard(BuildContext context, dynamic log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (log['meal_type']?.toString() ?? 'Meal').toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${(log['calories'] as num?)?.round() ?? 0} kcal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.calories),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            log['food_name']?.toString() ?? 'Unknown Food',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textMain),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _todaysLogMacro(context, 'Protein', log['protein'], AppColors.protein),
              _todaysLogMacro(context, 'Carbs', log['carbs'], AppColors.carbs),
              _todaysLogMacro(context, 'Fat', log['fat'], AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todaysLogMacro(BuildContext context, String label, dynamic value, Color color) {
    final numValue = value is num ? value : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.textMuted)),
        const SizedBox(height: 2),
        Text('${numValue.round()}g', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textMain, letterSpacing: -0.2),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.35,
          children: [
            _actionTile(
              context,
              title: 'Scan Barcode',
              desc: 'Scan & log meals',
              icon: Icons.qr_code_scanner,
              color: AppColors.primary,
              route: '/scan',
            ),
            _actionTile(
              context,
              title: 'Homely Builder',
              desc: 'Estimate macros',
              icon: Icons.science_outlined,
              color: AppColors.blueAction,
              route: '/homely-build',
            ),
            _actionTile(
              context,
              title: 'Meal Plan',
              desc: 'AI daily meal plan',
              icon: Icons.auto_awesome_outlined,
              color: AppColors.accent,
              route: '/meal-plan',
            ),
            _actionTile(
              context,
              title: 'Meal History',
              desc: 'View past logged meals',
              icon: Icons.history_rounded,
              color: AppColors.calories,
              route: '/history',
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textMain),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 10, color: context.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The weight-logging form — used to live inline on the dashboard (a date
/// picker, a text field, a checkbox, and a submit button sitting between
/// the macro rings and the water tracker). It's an action, not something
/// worth permanent shelf space on a screen meant to be scanned at a glance.
class _WeightLogSheet extends ConsumerStatefulWidget {
  const _WeightLogSheet();

  @override
  ConsumerState<_WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends ConsumerState<_WeightLogSheet> {
  final _weightController = TextEditingController();
  DateTime _logDate = DateTime.now();
  bool _logDatePicked = false; // false = "today": no date is sent, the server decides
  bool _followedPlanToday = true;
  bool _isLogging = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _logDate = picked;
        _logDatePicked = true;
      });
    }
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight < 10 || weight > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight (10-600 kg)')),
      );
      return;
    }

    setState(() => _isLogging = true);
    try {
      await ApiClient().dio.post(
        ApiEndpoints.trackWeight,
        data: {
          'user_id': user.id,
          'weight': weight,
          if (_logDatePicked) 'logged_at': DateFormat('yyyy-MM-dd').format(_logDate),
          'adherence': _followedPlanToday,
        },
      );
      if (!mounted) return;
      ref.read(authProvider.notifier).fetchUserSession();
      ref.read(analyticsProvider.notifier).fetchSummary(user.id);
      ref.read(profileProvider.notifier).fetchWeightHistory();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Weight logged successfully!'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log weight: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.purpleAction, size: 20),
              const SizedBox(width: 8),
              Text('Log Weight', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              InkWell(
                onTap: _pickDate,
                borderRadius: AppRadius.mdAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(color: context.inputBg, borderRadius: AppRadius.mdAll, border: Border.all(color: context.borderColor)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 15, color: context.textMuted),
                      const SizedBox(width: 6),
                      Text(DateFormat('d MMM').format(_logDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textMain)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Weight in kg...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => setState(() => _followedPlanToday = !_followedPlanToday),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _followedPlanToday,
                  onChanged: (val) => setState(() => _followedPlanToday = val ?? true),
                  activeColor: AppColors.purpleAction,
                ),
                Text('Followed diet plan today', style: TextStyle(fontSize: 13, color: context.textMain)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLogging ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAction),
              child: _isLogging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Log Weight'),
            ),
          ),
        ],
      ),
    );
  }
}
