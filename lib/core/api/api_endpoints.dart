/// All backend paths. Every call goes through the NutriX API gateway and uses the
/// versioned `/api/v1` namespace (see nutrix_app_handoff/API_CONTRACT.md).
class ApiEndpoints {
  /// Backend address. Set per build with
  ///   flutter build apk --dart-define=API_BASE_URL=https://your-backend
  /// It can still be overridden at runtime from the login screen
  /// (core/network/api_config.dart), which is useful while the backend
  /// address is a temporary tunnel.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://comedy-timeline-else-surgeon.trycloudflare.com',
  );
  static String baseUrl = defaultBaseUrl;

  static const String _v1 = '/api/v1';

  // Auth (public: register, login, google, reset-password)
  static const String register = '$_v1/auth/register';
  static const String login = '$_v1/auth/login';
  static const String googleLogin = '$_v1/auth/google';
  static const String me = '$_v1/auth/me';
  static const String resetPassword = '$_v1/auth/reset-password';

  // Profile & Targets
  static const String calculateProfile = '$_v1/user/profile';
  static const String userTargets = '$_v1/user/targets';

  // Dashboard
  static String dailySummary({String? date}) => date == null ? '$_v1/user/daily-summary' : '$_v1/user/daily-summary?date=$date';
  static const String history = '$_v1/user/history';
  static const String stream = '$_v1/user/stream';

  // Recommendations
  static const String recommendFoods = '$_v1/foods/recommend';

  // Meal Plan
  static const String generateMealPlan = '$_v1/meal-plans/generate';
  static String mealPlanHistory(int id) => '$_v1/users/$id/meal-plans';

  // Weight
  static const String trackWeight = '$_v1/weight-logs';
  static String weightHistory(int id) => '$_v1/users/$id/weight-history';

  // Water
  static const String waterLogs = '$_v1/water-logs';
  static String waterToday(int userId) => '$_v1/water-logs/today/$userId';
  static String waterHistory(int userId) => '$_v1/water-logs/history/$userId';
  static String waterLogDelete(int logId) => '$_v1/water-logs/$logId';

  // Meal Logs
  static const String mealLogs = '$_v1/meal-logs';
  static String mealLogsToday(int id) => '$_v1/meal-logs/today/$id';

  // Recipes
  static const String topRecipes = '$_v1/recipes/top';
  static const String searchRecipes = '$_v1/recipes/search';
  static String recipeDetail(String code) => '$_v1/recipes/$code';
  static const String recommendRecipes = '$_v1/recipes/recommend';
  static const String filterRecipes = '$_v1/recipes/filter';
  static const String generateInstructions = '$_v1/recipes/generate-instructions';

  // Fast food
  static const String fastFoodChains = '$_v1/fast-food/chains';
  static const String fastFoodGrouped = '$_v1/fast-food/grouped';

  // Barcode
  static String barcodeScan(String barcode) => '$_v1/barcode/$barcode';
  static const String barcodeManual = '$_v1/barcode/manual';
  static const String barcodeAlternatives = '$_v1/barcode/alternatives';
  static const String barcodeScanImage = '$_v1/barcode/scan-image';

  // OCR (photo of a nutrition label)
  static const String ocr = '$_v1/ocr/upload';

  // Classify
  static const String classify = '$_v1/classify';
  static const String substitutions = '$_v1/classify/substitutions';

  // Analytics
  static String analytics(int id) => '$_v1/analytics/$id';
  static String analyticsHistory(int id) => '$_v1/analytics/$id/history';

  // Homely Meals
  static const String homelyCalculate = '$_v1/homely-meals/calculate';
  static const String homelyCreate = '$_v1/homely-meals/create';
  static const String homelySearch = '$_v1/homely-meals/search';
  static const String homelyPending = '$_v1/homely-meals/pending';
  static const String homelyBuilderDefaults = '$_v1/homely/builder-defaults';
  static String homelyDetail(int id) => '$_v1/homely-meals/$id';
  static String homelyReview(int mealId) => '$_v1/homely-meals/review/$mealId';
  static String homelyUserMeals(int userId) => '$_v1/homely-meals/user/$userId';

  // AI
  static const String aiCoach = '$_v1/ai/coach';
  static const String aiDietPlan = '$_v1/ai/diet-plan';
  static const String aiRecipeGenerator = '$_v1/ai/recipe-generator';

  // Search History
  static const String searchHistory = '$_v1/search-history';

  // Settings
  static const String settings = '$_v1/settings';

  // Health (gateway: all services)
  static const String health = '/health/all';
}
