import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/nx_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onItemTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name ?? 'User';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    // Pushed screens (barcode, homely, meal-plan, recipe detail, etc.) sit
    // above this shell in the nav stack, so system back already pops them
    // to whatever presented them by default — this PopScope only fires when
    // MainShell itself is the topmost route, i.e. the user is on one of the
    // 4 bottom tabs directly. From any tab but Home, back returns to Home;
    // from Home, back exits the app.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onItemTapped(context, 0);
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.cardBg,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              const NxLogo(size: 30),
              const SizedBox(width: 8),
              const Text(
                'NutriX',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: IconButton(
                icon: Icon(
                  ref.watch(settingsProvider).darkModeEnabled ? Icons.light_mode : Icons.nightlight_round,
                  size: 18,
                  color: context.textMuted,
                ),
                onPressed: () {
                  final current = ref.read(settingsProvider).darkModeEnabled;
                  ref.read(settingsProvider.notifier).toggleDarkMode(!current);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _onItemTapped(context, 3),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blueAction.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blueAction.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: AppColors.blueAction,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: context.borderColor, height: 1),
          ),
        ),
        body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border(top: BorderSide(color: context.borderColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: AppColors.blueAction,
          unselectedItemColor: context.textDim,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home, color: AppColors.blueAction)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.explore_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.explore, color: AppColors.blueAction)),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_box_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_box, color: AppColors.blueAction)),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded, color: AppColors.blueAction)),
              label: 'Profile',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
