import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/scanner_provider.dart';
import 'providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A one-time light-mode default here is fine — it's overwritten the
  // instant the widget tree builds and knows the real theme (see
  // _applySystemUiOverlay below). Without that follow-up call this stayed
  // a permanently white Android nav bar even in dark mode.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDarkCardSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: NutriXApp()));
}

class NutriXApp extends ConsumerStatefulWidget {
  const NutriXApp({super.key});

  @override
  ConsumerState<NutriXApp> createState() => _NutriXAppState();
}

class _NutriXAppState extends ConsumerState<NutriXApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Plugins that request Android permissions (notifications, exact alarms,
    // battery optimization) need a live, attached Activity — calling them
    // from main() before runApp() mounts crashes on some OEM builds because
    // the Activity isn't bound to the engine yet. Run after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await WidgetService.init();
      } catch (_) {
        // Non-fatal — home-screen widgets are a nice-to-have.
      }
      try {
        await NotificationService.instance.init();
        await NotificationService.instance.scheduleDailyReminders();
      } catch (_) {
        // Non-fatal — app must still work if notification setup fails
        // (e.g. permission permanently denied).
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Taking a screenshot, pulling down the notification shade, or opening the
  // recent-apps switcher all pass the app through `inactive` only — it stays
  // visible the whole time. Actually leaving (home button, screen off,
  // switching apps) additionally passes through `hidden` (the view is no
  // longer visible at all) before eventually reaching `paused`. Android's
  // return-to-foreground sequence unwinds back through hidden -> inactive ->
  // resumed, so checking only the single state immediately before `resumed`
  // (as an earlier version of this did) almost always sees `inactive` —
  // never `hidden`/`paused` — even for a real backgrounding. Track whether
  // the app went to background at ANY point during the trip, not just the
  // last hop before returning.
  bool _wentToBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _wentToBackground = true;
    } else if (state == AppLifecycleState.resumed && _wentToBackground) {
      _wentToBackground = false;
      ref.read(authProvider.notifier).requireBiometricUnlock();
    }
  }

  // Home-screen widgets were previously only refreshed when the user
  // specifically opened the Home tab, so they could sit stale for an entire
  // session if a user's flow never landed there. Refresh the moment auth
  // resolves (covers both a fresh login and an already-logged-in cold
  // start), regardless of which screen is shown first.
  void _refreshHomeWidgets(int userId) {
    ref.read(analyticsProvider.notifier).fetchSummary(userId);
    ref.read(analyticsProvider.notifier).fetchMealLogs(userId);
    ref.read(profileProvider.notifier).fetchWeightHistory();
    final user = ref.read(authProvider).user;
    if (user != null) {
      WidgetService.updateContributionWidgetFromBackend(
        userId: userId,
        targetCalories: user.targetCalories,
        targetProtein: user.targetProtein,
      );
    }
  }

  void _applySystemUiOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.bgDarkCardSurface : AppColors.bgLightCard,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        _refreshHomeWidgets(next.user!.id);
      }
    });

    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.darkModeEnabled != next.darkModeEnabled) {
        _applySystemUiOverlay(next.darkModeEnabled);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySystemUiOverlay(settings.darkModeEnabled);
    });

    return MaterialApp.router(
      title: 'NutriX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
