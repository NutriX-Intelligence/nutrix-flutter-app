import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/common/nx_card.dart';

class _LogChoice {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String route;

  const _LogChoice({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// The Log tab's entry point. Used to host a Scan/Homely `TabBar`, which
/// itself hosted more sub-tabs inside each screen — three levels of tabs
/// stacked under the bottom nav before any content appeared. Replaced with
/// a single chooser, each card pushing one focused screen directly.
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  static const _choices = [
    _LogChoice(
      title: 'Scan a barcode',
      desc: 'Point your camera at a package, or type the number in',
      icon: Icons.qr_code_scanner_rounded,
      color: AppColors.primary,
      route: '/scan',
    ),
    _LogChoice(
      title: 'Snap a label',
      desc: 'Photograph a nutrition facts panel',
      icon: Icons.camera_alt_outlined,
      color: AppColors.blueAction,
      route: '/ocr',
    ),
    _LogChoice(
      title: 'Build a homely meal',
      desc: 'Compose from base dishes and toppings',
      icon: Icons.home_work_rounded,
      color: AppColors.purpleAction,
      route: '/homely-build',
    ),
    _LogChoice(
      title: 'Log from a recipe',
      desc: "Search NutriX's recipe library",
      icon: Icons.menu_book_rounded,
      color: AppColors.calories,
      route: '/recipes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log a meal', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                "Choose how you'd like to add it",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (final choice in _choices) ...[
                NxCard(
                  onTap: () => context.push(choice.route),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: choice.color.withValues(alpha: 0.12),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Icon(choice.icon, color: choice.color, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.title,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: context.textMain),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              choice.desc,
                              style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: context.textDim),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
