import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/app_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/nx_error_state.dart';
import '../../widgets/common/nx_logo.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // A logged-in user with a still-null `user` object should only ever be
  // a brief transient (session fetch in flight) — but if the request
  // hangs with no timeout ever firing, this was a spinner with no way out.
  bool _timedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  void _armTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && ref.read(authProvider).user == null) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _timedOut = false);
    _armTimeout();
    ref.read(authProvider.notifier).fetchUserSession();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: _timedOut
              ? NxErrorState(message: 'Could not load your profile.', onRetry: _retry)
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar + Info
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),

              // Body Stats
              _buildBodyStats(context, user),
              const SizedBox(height: 24),

              // Calculated Body Metrics & Targets
              _buildMetricsCard(context, user),
              const SizedBox(height: 24),

              // Actions
              _buildActionsList(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'N',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatGoal(user.goal),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBodyStats(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _statTile(context, 'Age', '${user.age}', 'years', Icons.cake_outlined, AppColors.warning),
            const SizedBox(width: 10),
            _statTile(context, 'Height', '${user.height.toInt()}', 'cm', Icons.height_rounded, AppColors.info),
            const SizedBox(width: 10),
            _statTile(context, 'Weight', '${user.weight.toStringAsFixed(1)}', 'kg', Icons.monitor_weight_outlined, AppColors.accent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile(context, 'Activity', _shortActivity(user.activityLevel), '', Icons.directions_run_rounded, AppColors.accentPink),
            const SizedBox(width: 10),
            _statTile(context, 'Goal', _formatGoal(user.goal), '', Icons.flag_outlined, AppColors.accent),
            const SizedBox(width: 10),
            _statTile(context, 'Diet Type', user.dietType ?? '--', '', Icons.restaurant_menu_rounded, AppColors.success),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _statTile(BuildContext context, String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: context.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (unit.isNotEmpty)
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context, user) {
    final bmiColor = _bmiStatusColor(context, user.bmiStatus);
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.bar_chart_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Calculated Body Metrics & Targets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _metricItem(context, user.bmi?.toStringAsFixed(1) ?? '--', 'BMI', context.textMain),
                    _metricItem(context, user.bmiStatus ?? '--', 'BMI Status', bmiColor, dotColor: bmiColor),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _metricItem(context, user.bmr != null ? '${user.bmr.round()} kcal' : '--', 'BMR (kcal)', context.textMain),
                    _metricItem(context, user.tdee != null ? '${user.tdee.round()} kcal' : '--', 'TDEE (kcal)', AppColors.purpleAction),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _targetTile(context, '${user.targetCalories.toInt()} kcal', 'Daily Calories', AppColors.calories),
              const SizedBox(width: 10),
              _targetTile(context, '${user.targetProtein.toInt()}g', 'Protein', AppColors.protein),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _targetTile(context, '${user.targetCarbs.toInt()}g', 'Carbs', AppColors.carbs),
              const SizedBox(width: 10),
              _targetTile(context, '${user.targetFat.toInt()}g', 'Fat', AppColors.fat),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Color _bmiStatusColor(BuildContext context, String? status) {
    switch (status?.toLowerCase()) {
      case 'underweight':
        return AppColors.info;
      case 'normal':
      case 'healthy':
        return AppColors.success;
      case 'overweight':
        return AppColors.warning;
      case 'obese':
        return AppColors.error;
      default:
        return context.textMain;
    }
  }

  Widget _metricItem(BuildContext context, String value, String label, Color valueColor, {Color? dotColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ],
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(color: valueColor, fontSize: 17, fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _targetTile(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: context.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsList(BuildContext context) {
    final darkModeEnabled = ref.watch(settingsProvider).darkModeEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _actionItem(
          context,
          Icons.notifications_outlined,
          'Notifications',
          'Meal reminders & updates',
          AppColors.warning,
          () => context.push('/settings'),
        ),
        _actionItem(
          context,
          Icons.color_lens_outlined,
          'Appearance',
          darkModeEnabled ? 'Dark mode enabled' : 'Light mode enabled',
          AppColors.primary,
          () => context.push('/settings'),
        ),
        _actionItem(
          context,
          Icons.info_outline_rounded,
          'About NutriX',
          'Version $kAppVersion',
          AppColors.info,
          () => showAboutDialog(
            context: context,
            applicationName: 'NutriX',
            applicationVersion: kAppVersion,
            applicationIcon: const NxLogo(size: 52),
            applicationLegalese: 'AI-powered diet planning and recipe intelligence.',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.brand),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.brand)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brand, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  Widget _actionItem(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  String _formatGoal(String goal) {
    return goal.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String _shortActivity(String level) {
    switch (level) {
      case 'sedentary': return 'Low';
      case 'lightly_active': return 'Light';
      case 'moderately_active': return 'Medium';
      case 'active': return 'High';
      case 'very_active': return 'V.High';
      default: return level;
    }
  }
}
