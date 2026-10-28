import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/local_cache.dart';
import '../core/services/widget_service.dart';
import 'auth_provider.dart';

// ==========================
// Barcode Scanning & Lookup State
// ==========================
class BarcodeState {
  final bool isLoading;
  final bool isLogging;
  final Map<String, dynamic>? productData;
  final List<dynamic>? alternatives;
  final String? error;
  final String? logSuccessMessage;

  BarcodeState({
    this.isLoading = false,
    this.isLogging = false,
    this.productData,
    this.alternatives,
    this.error,
    this.logSuccessMessage,
  });

  BarcodeState copyWith({
    bool? isLoading,
    bool? isLogging,
    Map<String, dynamic>? productData,
    List<dynamic>? alternatives,
    String? error,
    String? logSuccessMessage,
  }) {
    return BarcodeState(
      isLoading: isLoading ?? this.isLoading,
      isLogging: isLogging ?? this.isLogging,
      productData: productData ?? this.productData,
      alternatives: alternatives ?? this.alternatives,
      error: error,
      logSuccessMessage: logSuccessMessage,
    );
  }
}

class BarcodeNotifier extends StateNotifier<BarcodeState> {
  final Ref ref;

  BarcodeNotifier(this.ref) : super(BarcodeState());

  Future<void> lookupBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    state = BarcodeState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.barcodeScan(barcode));
      state = BarcodeState(productData: response.data);
    } on DioException catch (e) {
      state = BarcodeState(
        error: apiDetail(e) ?? 'Product lookup failed.',
      );
    } catch (e) {
      state = BarcodeState(error: e.toString());
    }
  }

  Future<void> logScannedMeal({
    required int userId,
    required String mealType,
    required String productName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    state = state.copyWith(isLogging: true, error: null, logSuccessMessage: null);
    try {
      final apiClient = ApiClient();
      // 1. Log Meal to `/api/meal-logs`
      final logBody = {
        'user_id': userId,
        'meal_type': mealType,
        'source': 'barcode',
        'food_name': productName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logBody);
      // Refresh Home's "today" totals immediately — Home's State survives
      // tab switches (IndexedStack), so it won't otherwise refetch until the
      // next cold start.
      unawaited(ref.read(analyticsProvider.notifier).fetchMealLogs(userId));

      // 2. Fetch alternatives from `/api/barcode/alternatives`
      List<dynamic> alternativesList = [];
      try {
        final altResponse = await apiClient.dio.post(
          ApiEndpoints.barcodeAlternatives,
          data: {
            'product_name': productName,
            'meal_type': mealType,
            'protein_g': protein,
            'energy_kcal': calories,
            'sugar_g': 0.0,
            'fat_g': fat,
            'estimated_price': 20.0,
          },
        );
        if (altResponse.data != null && altResponse.data['alternatives'] != null) {
          alternativesList = altResponse.data['alternatives'];
        }
      } catch (e) {
        // Keep alternatives empty if call fails
      }

      state = state.copyWith(
        isLogging: false,
        logSuccessMessage: 'Successfully logged as $mealType!',
        alternatives: alternativesList,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLogging: false,
        error: apiDetail(e) ?? 'Failed to log scanned meal.',
      );
    } catch (e) {
      state = state.copyWith(isLogging: false, error: e.toString());
    }
  }

  Future<void> submitManualBarcode({
    required String barcode,
    required String productName,
    required String brand,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String ingredientsText = 'Manually entered product',
    double fiber = 0.0,
    double sodium = 0.0,
    double sugar = 0.0,
    double saturatedFat = 0.0,
  }) async {
    state = BarcodeState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final body = {
        'barcode': barcode,
        'product_name': productName,
        'brand': brand,
        'ingredients_text': ingredientsText.isEmpty ? 'Manually entered product' : ingredientsText,
        'energy_kcal': calories,
        'protein_g': protein,
        'carb_g': carbs,
        'fat_g': fat,
        'fibre_g': fiber,
        'sodium_mg': sodium,
        'sugar_g': sugar,
        'saturated_fat_g': saturatedFat,
      };

      final response = await apiClient.dio.post(ApiEndpoints.barcodeManual, data: body);
      state = BarcodeState(productData: response.data);
    } on DioException catch (e) {
      state = BarcodeState(
        error: apiDetail(e) ?? 'Failed to submit manual barcode.',
      );
    } catch (e) {
      state = BarcodeState(error: e.toString());
    }
  }

  /// "Upload Photo" mode — detects a barcode and/or reads a nutrition label
  /// from an uploaded product photo via POST /api/barcode/scan-image.
  Future<void> scanBarcodeImage({
    required String filePath,
    required String fileName,
    int? userId,
  }) async {
    state = BarcodeState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (userId != null) 'user_id': userId,
      });
      final response = await apiClient.dio.post(ApiEndpoints.barcodeScanImage, data: formData);
      final data = response.data;
      if (data is Map && (data['type'] == 'barcode' || data['type'] == 'dual') && data['product'] != null) {
        state = BarcodeState(productData: data['product']);
      } else if (data is Map && data['type'] == 'ocr') {
        state = BarcodeState(
          error: 'No barcode found in this photo, but a nutrition label was detected — use the OCR tab to log it.',
        );
      } else {
        state = BarcodeState(error: 'Could not read this photo. Try a clearer image or enter details manually.');
      }
    } on DioException catch (e) {
      state = BarcodeState(
        error: apiDetail(e) ?? 'Could not read this photo.',
      );
    } catch (e) {
      state = BarcodeState(error: e.toString());
    }
  }

  void clear() {
    state = BarcodeState();
  }
}

final barcodeProvider = StateNotifierProvider<BarcodeNotifier, BarcodeState>((ref) {
  return BarcodeNotifier(ref);
});

// ==========================
// Dietary Classifier State
// ==========================
class ClassificationState {
  final bool isLoading;
  final Map<String, dynamic>? classificationData;
  final String? error;

  ClassificationState({this.isLoading = false, this.classificationData, this.error});

  ClassificationState copyWith({bool? isLoading, Map<String, dynamic>? classificationData, String? error}) {
    return ClassificationState(
      isLoading: isLoading ?? this.isLoading,
      classificationData: classificationData ?? this.classificationData,
      error: error,
    );
  }
}

class ClassificationNotifier extends StateNotifier<ClassificationState> {
  final Ref ref;

  ClassificationNotifier(this.ref) : super(ClassificationState());

  Future<void> classifyIngredients(String ingredients) async {
    if (ingredients.isEmpty) return;

    final ingredientsList = ingredients.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ingredientsList.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.classify,
        data: {'ingredients': ingredientsList},
      );
      state = state.copyWith(isLoading: false, classificationData: response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Classification failed.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = ClassificationState();
  }
}

final classificationProvider = StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
  return ClassificationNotifier(ref);
});

// ==========================
// OCR Scanner State
// ==========================
class OcrState {
  final bool isLoading;
  final Map<String, dynamic>? ocrData;
  final String? error;

  OcrState({this.isLoading = false, this.ocrData, this.error});

  OcrState copyWith({bool? isLoading, Map<String, dynamic>? ocrData, String? error}) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      ocrData: ocrData ?? this.ocrData,
      error: error,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  final Ref ref;

  OcrNotifier(this.ref) : super(OcrState());

  Future<void> uploadOcrImage({
    required String filePath,
    required String fileName,
    required String mealType,
    required String foodName,
    required int userId,
  }) async {
    state = OcrState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'user_id': userId,
        'meal_type': mealType,
        'food_name': foodName.isEmpty ? fileName : foodName,
      });

      final response = await apiClient.dio.post(
        ApiEndpoints.ocr,
        data: formData,
      );

      state = OcrState(ocrData: response.data);
      if (response.data is Map && response.data['meal_logged'] == true) {
        unawaited(ref.read(analyticsProvider.notifier).fetchMealLogs(userId));
      }
    } on DioException catch (e) {
      state = OcrState(
        error: apiDetail(e) ?? 'OCR scan failed.',
      );
    } catch (e) {
      state = OcrState(error: e.toString());
    }
  }

  void clear() {
    state = OcrState();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(ref);
});

// ==========================
// Analytics State
// ==========================
// Valid `metricName` values for fetchMetricHistory (persisted by AnalyticsEngine
// on every fetchSummary call): calories_weekly_avg, protein_weekly_avg,
// carbs_weekly_avg, fat_weekly_avg, water_weekly_avg, weight_trend, latest_weight.
class AnalyticsState {
  final bool isLoading;
  final Map<String, dynamic>? summaryData;
  final bool isLoadingMetricHistory;
  final List<dynamic>? metricHistory;
  // "Today" totals, owned exclusively by HomeScreen.
  final List<dynamic>? mealLogs;
  final Map<String, dynamic>? mealLogTotals;
  // Logs for whatever date the user is browsing on the History screen —
  // kept separate so browsing history never clobbers Home's "today" cache.
  final List<dynamic>? browsedDateLogs;
  final Map<String, dynamic>? browsedDateTotals;
  final bool isLoadingBrowsedDate;
  final String? error;

  AnalyticsState({
    this.isLoading = false,
    this.summaryData,
    this.isLoadingMetricHistory = false,
    this.metricHistory,
    this.mealLogs,
    this.mealLogTotals,
    this.browsedDateLogs,
    this.browsedDateTotals,
    this.isLoadingBrowsedDate = false,
    this.error,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? summaryData,
    bool? isLoadingMetricHistory,
    List<dynamic>? metricHistory,
    List<dynamic>? mealLogs,
    Map<String, dynamic>? mealLogTotals,
    List<dynamic>? browsedDateLogs,
    Map<String, dynamic>? browsedDateTotals,
    bool? isLoadingBrowsedDate,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      summaryData: summaryData ?? this.summaryData,
      isLoadingMetricHistory: isLoadingMetricHistory ?? this.isLoadingMetricHistory,
      metricHistory: metricHistory ?? this.metricHistory,
      mealLogs: mealLogs ?? this.mealLogs,
      mealLogTotals: mealLogTotals ?? this.mealLogTotals,
      browsedDateLogs: browsedDateLogs ?? this.browsedDateLogs,
      browsedDateTotals: browsedDateTotals ?? this.browsedDateTotals,
      isLoadingBrowsedDate: isLoadingBrowsedDate ?? this.isLoadingBrowsedDate,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref ref;

  AnalyticsNotifier(this.ref) : super(AnalyticsState());

  /// Fetches the 7-day averages / weight-stats / targets summary from
  /// `GET /api/analytics/{user_id}`. Independent of fetchMetricHistory —
  /// previously these were combined in one try block, so a failure in the
  /// (always-failing, missing-param) history call silently discarded a
  /// perfectly good summary response.
  Future<void> fetchSummary(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final cacheKey = 'analytics_summary_$userId';
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.get(ApiEndpoints.analytics(userId));
      state = state.copyWith(isLoading: false, summaryData: res.data);
      unawaited(LocalCache.save(cacheKey, res.data));
    } on DioException catch (e) {
      final cached = await LocalCache.load(cacheKey);
      if (cached != null) {
        state = state.copyWith(isLoading: false, summaryData: cached as Map<String, dynamic>);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: apiDetail(e) ?? 'Failed to load analytics.',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetches a single metric's daily trend from
  /// `GET /api/analytics/{user_id}/history?metric_name=...` (metric_name is
  /// required server-side).
  Future<void> fetchMetricHistory(int userId, String metricName, {int limit = 30}) async {
    state = state.copyWith(isLoadingMetricHistory: true, error: null);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.get(
        ApiEndpoints.analyticsHistory(userId),
        queryParameters: {'metric_name': metricName, 'limit': limit},
      );
      state = state.copyWith(
        isLoadingMetricHistory: false,
        metricHistory: res.data is List ? res.data : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingMetricHistory: false,
        error: apiDetail(e) ?? 'Failed to load metric history.',
      );
    } catch (e) {
      state = state.copyWith(isLoadingMetricHistory: false, error: e.toString());
    }
  }

  /// Today's meal logs/totals — owned by HomeScreen. Call this after every
  /// successful meal-log action anywhere in the app so Home's cache is fresh
  /// the instant the user returns to it (Home's State survives tab switches
  /// via IndexedStack, so its initState only runs once per app session).
  /// `silent` refreshes in the background (no spinner, errors ignored): used to
  /// pick up meals the smart scale logged on its own.
  Future<void> fetchMealLogs(int userId, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    final cacheKey = 'meal_logs_today_$userId';
    try {
      final apiClient = ApiClient();
      // No date is sent for "today": the server decides the day (India time), the
      // same way it does when a meal is created, so the two can never disagree.
      final response = await apiClient.dio.get(ApiEndpoints.mealLogsToday(userId));
      state = state.copyWith(
        isLoading: false,
        mealLogs: response.data['logs'] is List ? response.data['logs'] : [],
        mealLogTotals: response.data['totals'] is Map ? response.data['totals'] : null,
      );
      unawaited(LocalCache.save(cacheKey, response.data));
      unawaited(_updateMacroWidget(response.data['totals']));
    } on DioException catch (e) {
      if (silent) return;
      final cached = await LocalCache.load(cacheKey);
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          mealLogs: cached['logs'] is List ? cached['logs'] : [],
          mealLogTotals: cached['totals'] is Map ? cached['totals'] as Map<String, dynamic> : null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: apiDetail(e) ?? 'Failed to load meal logs.',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logs for a specific browsed date — owned by the History screen only.
  /// `date == null` means today: no date is sent and the server decides the day.
  Future<void> fetchMealLogsForDate(int userId, String? date) async {
    state = state.copyWith(isLoadingBrowsedDate: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        ApiEndpoints.mealLogsToday(userId),
        queryParameters: date == null ? null : {'log_date': date},
      );
      state = state.copyWith(
        isLoadingBrowsedDate: false,
        browsedDateLogs: response.data['logs'] is List ? response.data['logs'] : [],
        browsedDateTotals: response.data['totals'] is Map ? response.data['totals'] : null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingBrowsedDate: false,
        error: apiDetail(e) ?? 'Failed to load meal logs.',
      );
    } catch (e) {
      state = state.copyWith(isLoadingBrowsedDate: false, error: e.toString());
    }
  }

  /// Home-screen "Today's Macros" widget — refreshed after every meal log
  /// site calls fetchMealLogs, so the launcher widget stays in sync with
  /// whatever just got logged (barcode/OCR/homely/recipe/meal-plan).
  Future<void> _updateMacroWidget(dynamic totals) async {
    if (totals is! Map) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    await WidgetService.updateMacroWidget(
      calories: (totals['calories'] as num?)?.toDouble() ?? 0.0,
      maxCalories: user.targetCalories,
      protein: (totals['protein'] as num?)?.toDouble() ?? 0.0,
      maxProtein: user.targetProtein,
    );
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});
