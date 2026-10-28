import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;
  // True right after a brand-new Google sign-in (backend created the user
  // with hardcoded defaults: age 25, 170cm, 70kg, sedentary, maintenance,
  // no diet type). Read by the router's redirect so new users land on
  // /profile-setup regardless of exactly when/whether the login screen is
  // still mounted to push it itself.
  final bool needsProfileSetup;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.needsProfileSetup = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
    bool? needsProfileSetup,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      needsProfileSetup: needsProfileSetup ?? this.needsProfileSetup,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    // Any protected call answered with 401 (expired / invalid token, or the
    // account is gone) sends the user back to the login screen.
    ApiClient.onUnauthorized = () {
      if (mounted && state.status == AuthStatus.authenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    };
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      
      if (canAuthenticate) {
        // Add a slight delay to ensure Flutter has fully attached the Activity on startup
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to unlock NutriX',
            // ignore: deprecated_member_use
            biometricOnly: true,
          );
          if (!didAuthenticate) {
            // Cancelled biometrics. Fall back to login screen but KEEP token so they can try again
            state = const AuthState(status: AuthStatus.unauthenticated);
            return;
          }
        } catch (e) {
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }
      }

      // If biometrics succeed (or are unsupported), validate the token
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        final user = User.fromJson(response.data);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          token: await _api.getToken(),
        );
      } catch (_) {
        await _api.clearToken();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> fetchUserSession() async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        final user = User.fromJson(response.data);
        state = state.copyWith(
          user: user,
        );
      } catch (_) {
        // Silently fail if unable to refresh
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _api.saveToken(authResponse.accessToken);
      
      // Save credentials for biometric login fallback
      await _storage.write(key: 'saved_email', value: email);
      await _storage.write(key: 'saved_password', value: password);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        token: authResponse.accessToken,
      );
    } on DioException catch (e) {
      final message = apiDetail(e) ?? 'Login failed. Please try again.';
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message.toString(),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    List<Map<String, String>>? preferences,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = {
        'name': name,
        'email': email,
        'password': password,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'goal': goal,
        if (preferences != null)
          'preferences': preferences
              .map((p) => {
                    'preference_type': p['preference_type'],
                    'value': p['value'],
                  })
              .toList(),
      };
      final response = await _api.dio.post(ApiEndpoints.register, data: data);
      final authResponse = AuthResponse.fromJson(response.data);
      await _api.saveToken(authResponse.accessToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        token: authResponse.accessToken,
      );
    } on DioException catch (e) {
      final message = apiDetail(e) ?? 'Registration failed.';
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message.toString(),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _storage.delete(key: 'saved_email');
    await _storage.delete(key: 'saved_password');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// The old `GET /users/{email}` lookup was removed from the backend. Registering
  /// an e-mail that already exists is rejected by `POST /auth/register` itself,
  /// and that message is shown to the user, so no pre-check is needed.
  Future<bool> checkEmailExists(String email) async => false;

  Future<bool> loginWithGoogle(String webClientId) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      // Initialize GoogleSignIn (v7+ singleton API)
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: webClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.authenticate();
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception("Failed to get Google ID Token");
      }

      final response = await _api.dio.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _api.saveToken(authResponse.accessToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        token: authResponse.accessToken,
        needsProfileSetup: authResponse.isNewUser,
      );
      return authResponse.isNewUser;
    } on DioException catch (e) {
      final message = apiDetail(e) ?? 'Google Login failed.';
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message.toString(),
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> updateProfile({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    List<Map<String, String>>? preferences,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('Failed to update profile: no signed-in user.');
    }
    try {
      // POST /api/auth/me ignores its request body server-side (it just
      // echoes the unchanged profile back) — /calculate-profile is the
      // endpoint that actually upserts (matched by email) and recalculates
      // BMI/BMR/TDEE/targets from the new metrics.
      final data = {
        'name': currentUser.name,
        'email': currentUser.email,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'goal': goal,
        if (preferences != null)
          'preferences': preferences
              .map((p) => {
                    'preference_type': p['preference_type'],
                    'value': p['value'],
                  })
              .toList(),
      };
      final response = await _api.dio.post(ApiEndpoints.calculateProfile, data: data);
      final updatedUser = User.fromJson(response.data);

      state = state.copyWith(user: updatedUser, needsProfileSetup: false);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<bool> loginWithBiometrics() async {
    try {
      final hasToken = await _api.hasToken();
      final email = await _storage.read(key: 'saved_email');
      final password = await _storage.read(key: 'saved_password');
      
      if (!hasToken && (email == null || password == null)) {
        state = state.copyWith(
          status: AuthStatus.error, 
          errorMessage: 'No saved session found. Please login normally first.'
        );
        return false;
      }

      final LocalAuthentication auth = LocalAuthentication();
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
         state = state.copyWith(
           status: AuthStatus.error, 
           errorMessage: "Biometrics not supported or not set up on this device."
         );
         return false;
      }

      bool didAuthenticate = false;
      try {
        didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access your NutriX account',
          // ignore: deprecated_member_use
          biometricOnly: true,
        );
      } catch (_) { }

      if (didAuthenticate) {
        if (hasToken) {
          // If we have a token (e.g. from Google or email), just validate it!
          state = state.copyWith(status: AuthStatus.loading);
          try {
            final response = await _api.dio.get(ApiEndpoints.me);
            final user = User.fromJson(response.data);
            state = AuthState(
              status: AuthStatus.authenticated,
              user: user,
              token: await _api.getToken(),
            );
            return true;
          } catch (_) {
            await _api.clearToken();
            state = const AuthState(status: AuthStatus.unauthenticated);
            return false;
          }
        } else {
          // Fallback to manual login via email/password
          await login(email!, password!);
          return true;
        }
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: "Authentication failed.");
        return false;
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  bool ignoreNextLifecycleResume = false;

  Future<void> requireBiometricUnlock() async {
    if (ignoreNextLifecycleResume) {
      ignoreNextLifecycleResume = false;
      return;
    }

    // Only lock if we are currently authenticated and the token is valid
    if (state.status == AuthStatus.authenticated && await _api.hasToken()) {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      
      if (canAuthenticate) {
        // Drop them to unauthenticated (Login screen with Biometric button visible)
        // But do NOT clear their token, so they can unlock it easily!
        state = const AuthState(status: AuthStatus.unauthenticated);
        // Automatically attempt to prompt for biometrics
        await loginWithBiometrics();
      }
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
