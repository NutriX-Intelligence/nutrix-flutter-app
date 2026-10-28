import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/local_cache.dart';

// ==========================
// Water Tracking State
// ==========================
class WaterState {
  final bool isLoading;
  final bool isLogging;
  final double totalMl;
  final double targetMl;
  final double progressPct;
  final List<dynamic> logs;
  final List<dynamic>? historyData;
  final String? error;

  WaterState({
    this.isLoading = false,
    this.isLogging = false,
    this.totalMl = 0.0,
    this.targetMl = 2500.0,
    this.progressPct = 0.0,
    this.logs = const [],
    this.historyData,
    this.error,
  });

  WaterState copyWith({
    bool? isLoading,
    bool? isLogging,
    double? totalMl,
    double? targetMl,
    double? progressPct,
    List<dynamic>? logs,
    List<dynamic>? historyData,
    String? error,
  }) {
    return WaterState(
      isLoading: isLoading ?? this.isLoading,
      isLogging: isLogging ?? this.isLogging,
      totalMl: totalMl ?? this.totalMl,
      targetMl: targetMl ?? this.targetMl,
      progressPct: progressPct ?? this.progressPct,
      logs: logs ?? this.logs,
      historyData: historyData ?? this.historyData,
      error: error,
    );
  }
}

class WaterNotifier extends StateNotifier<WaterState> {
  final Ref ref;

  WaterNotifier(this.ref) : super(WaterState());

  Future<void> fetchToday(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final cacheKey = 'water_today_$userId';
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.waterToday(userId));
      final data = response.data;
      state = state.copyWith(
        isLoading: false,
        totalMl: double.tryParse(data['total_ml'].toString()) ?? 0.0,
        targetMl: double.tryParse(data['target_ml'].toString()) ?? 2500.0,
        progressPct: double.tryParse(data['progress_pct'].toString()) ?? 0.0,
        logs: data['logs'] is List ? data['logs'] : [],
      );
      unawaited(LocalCache.save(cacheKey, data));
    } on DioException catch (e) {
      final cached = await LocalCache.load(cacheKey);
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          totalMl: double.tryParse(cached['total_ml'].toString()) ?? 0.0,
          targetMl: double.tryParse(cached['target_ml'].toString()) ?? 2500.0,
          progressPct: double.tryParse(cached['progress_pct'].toString()) ?? 0.0,
          logs: cached['logs'] is List ? cached['logs'] : [],
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: apiDetail(e) ?? 'Failed to load today\'s water intake.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchHistory(int userId, {int days = 30}) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        ApiEndpoints.waterHistory(userId),
        queryParameters: {'days': days},
      );
      final data = response.data;
      state = state.copyWith(
        historyData: data['history'] is List ? data['history'] : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: apiDetail(e) ?? 'Failed to load water history.',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> addWater(int userId, double amountMl) async {
    state = state.copyWith(isLogging: true, error: null);
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post(
        ApiEndpoints.waterLogs,
        data: {'user_id': userId, 'amount_ml': amountMl},
      );
      state = state.copyWith(isLogging: false);
      await fetchToday(userId);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLogging: false,
        error: apiDetail(e) ?? 'Failed to log water intake.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLogging: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteLog(int userId, int logId) async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.delete(ApiEndpoints.waterLogDelete(logId));
      await fetchToday(userId);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: apiDetail(e) ?? 'Failed to delete water log.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref);
});
