import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrix_app/providers/auth_provider.dart';
import 'package:nutrix_app/screens/auth/login_screen.dart';
import 'package:nutrix_app/screens/auth/register_screen.dart';
import 'package:nutrix_app/screens/home/home_screen.dart';
import 'package:nutrix_app/screens/home/analytics_history_screen.dart';
import 'package:nutrix_app/screens/discover/discover_screen.dart';
import 'package:nutrix_app/screens/recipes/recipe_search_screen.dart';
import 'package:nutrix_app/screens/recipes/recipe_detail_screen.dart';
import 'package:nutrix_app/screens/meal_plan/meal_plan_screen.dart';
import 'package:nutrix_app/screens/barcode/scan_screen.dart';
import 'package:nutrix_app/screens/barcode/manual_entry_screen.dart';
import 'package:nutrix_app/screens/barcode/ocr_screen.dart';
import 'package:nutrix_app/screens/log/log_screen.dart';
import 'package:nutrix_app/screens/homely/homely_build_screen.dart';
import 'package:nutrix_app/screens/homely/homely_custom_screen.dart';
import 'package:nutrix_app/screens/homely/homely_community_screen.dart';
import 'package:nutrix_app/screens/homely/homely_meal_detail_screen.dart';
import 'package:nutrix_app/screens/profile/profile_screen.dart';
import 'package:nutrix_app/screens/profile/profile_setup_screen.dart';
import 'package:nutrix_app/screens/profile/edit_profile_screen.dart';
import 'package:nutrix_app/screens/profile/settings_screen.dart';
import 'package:nutrix_app/screens/shell/main_shell.dart';
import 'package:nutrix_app/screens/recipes/ai_recipe_gen_screen.dart';
import 'package:nutrix_app/screens/meal_plan/ai_diet_plan_screen.dart';
import 'package:nutrix_app/screens/ai_coach/ai_coach_screen.dart';
import 'package:nutrix_app/screens/discover/browse_recipes_screen.dart';
import 'package:nutrix_app/screens/discover/search_history_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      // A brand-new Google sign-in gets created server-side with hardcoded
      // defaults (25yo, 170cm, 70kg, sedentary, no diet type) — send them to
      // fill in real details before anywhere else. Driven from auth state
      // (not a one-shot push from the login screen) because the login
      // screen's own context/mounted state is unreliable here: this same
      // login->authenticated transition is what triggers the isLoggedIn
      // redirect above, which can dispose the login screen before a
      // separately-scheduled push from it ever fires.
      if (isLoggedIn && authState.needsProfileSetup && state.matchedLocation != '/profile-setup') {
        return '/profile-setup';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                builder: (context, state) => const LogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/meal-plan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealPlanScreen(),
      ),
      GoRoute(
        path: '/ai-diet-plan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiDietPlanScreen(),
      ),
      GoRoute(
        path: '/ai-recipe-gen',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiRecipeGenScreen(),
      ),
      GoRoute(
        path: '/recipes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RecipeSearchScreen(),
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/manual-entry',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ManualEntryScreen(prefilledBarcode: state.extra as String?),
      ),
      GoRoute(
        path: '/ocr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OcrScreen(),
      ),
      GoRoute(
        path: '/homely-build',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HomelyBuildScreen(
            initialBaseMealCode: extra?['baseMealCode'] as String?,
            initialQuantity: extra?['quantity'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/homely-custom',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HomelyCustomScreen(),
      ),
      GoRoute(
        path: '/homely-community',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HomelyCommunityScreen(),
      ),
      GoRoute(
        path: '/ai-coach',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiCoachScreen(),
      ),
      GoRoute(
        path: '/browse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BrowseRecipesScreen(initialQuery: state.extra as String?),
      ),
      GoRoute(
        path: '/search-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchHistoryScreen(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsHistoryScreen(),
      ),
      GoRoute(
        path: '/recipe/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeDetailScreen(
          recipeCode: state.pathParameters['code']!,
        ),
      ),
      GoRoute(
        path: '/homely-meal/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => HomelyMealDetailScreen(
          mealId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
