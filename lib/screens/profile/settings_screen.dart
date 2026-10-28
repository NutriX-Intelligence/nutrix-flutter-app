import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/app_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/nx_card.dart';
import '../../widgets/common/nx_logo.dart';

/// Was 2 toggles and nothing else — the actual account/data/about actions
/// a settings screen normally holds either didn't exist or lived
/// elsewhere. Sectioned to match what a settings screen is expected to
/// contain, without inventing controls the app can't actually back (no
/// fake "Units" toggle — there's no imperial support anywhere in the app
/// to switch to).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: AppRadius.mdAll),
                child: Text(state.error!, style: const TextStyle(color: AppColors.error)),
              ),

            _sectionLabel(context, 'Account'),
            NxCard(
              onTap: () => context.push('/edit-profile'),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '—', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textMain)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: context.textMuted)),
                      ],
                    ),
                  ),
                  Text('Edit Profile', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: context.textDim),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel(context, 'Appearance'),
            _toggleRow(
              context,
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Toggle application theme',
              value: state.darkModeEnabled,
              onChanged: (val) => ref.read(settingsProvider.notifier).toggleDarkMode(val),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel(context, 'Notifications'),
            _toggleRow(
              context,
              icon: Icons.notifications_active_rounded,
              title: 'Push Notifications',
              subtitle: 'Receive meal reminders and goals',
              value: state.notificationsEnabled,
              onChanged: (val) => ref.read(settingsProvider.notifier).toggleNotifications(val),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel(context, 'Units'),
            NxCard(
              child: Row(
                children: [
                  Icon(Icons.straighten_rounded, color: context.textMuted, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Weight and height are tracked in kilograms and centimeters.', style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel(context, 'Data'),
            NxCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navRow(context, icon: Icons.history_rounded, label: 'Meal History', onTap: () => context.push('/history')),
                  Divider(height: 1, color: context.borderColor),
                  _navRow(context, icon: Icons.manage_search_rounded, label: 'Search History', onTap: () => context.push('/search-history')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel(context, 'About'),
            NxCard(
              child: Row(
                children: [
                  const NxLogo(size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NutriX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.textMain)),
                        const SizedBox(height: 2),
                        Text('Version $kAppVersion', style: TextStyle(fontSize: 12, color: context.textMuted)),
                      ],
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

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textMuted, letterSpacing: 0.5),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NxCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppRadius.mdAll),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textMain)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: context.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textMain))),
            Icon(Icons.chevron_right_rounded, size: 18, color: context.textDim),
          ],
        ),
      ),
    );
  }
}
