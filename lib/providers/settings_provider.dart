import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isLoading;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String? error;

  SettingsState({
    this.isLoading = false,
    this.notificationsEnabled = true,
    this.darkModeEnabled = true,
    this.error,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? error,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _darkModeKey = 'settings_dark_mode_enabled';

  final Ref ref;

  SettingsNotifier(this.ref) : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      darkModeEnabled: prefs.getBool(_darkModeKey) ?? true,
    );
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(darkModeEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
