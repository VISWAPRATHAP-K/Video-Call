import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/fcm_service.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    required this.isLoading,
    this.user,
    this.error,
  });

  factory AuthState.initial() => AuthState(isLoading: false);
  factory AuthState.loading() => AuthState(isLoading: true);
  factory AuthState.authenticated(UserModel user) => AuthState(isLoading: false, user: user);
  factory AuthState.unauthenticated() => AuthState(isLoading: false);
  factory AuthState.error(String error) => AuthState(isLoading: false, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState.initial());

  /// Check if user has an active session on app startup
  Future<void> checkAuth() async {
    state = AuthState.loading();
    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final user = UserModel.fromJson(userData);
        state = AuthState.authenticated(user);
        
        // Sync FCM token automatically after profile loads
        syncFcmToken();
      } else {
        await _apiService.clearAuth();
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      await _apiService.clearAuth();
      state = AuthState.error(e.toString());
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    state = AuthState.loading();
    try {
      final response = await _apiService.login(email: email, password: password);
      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        await _apiService.setToken(token);
        final user = UserModel.fromJson(userData);
        state = AuthState.authenticated(user);

        // Sync FCM token
        syncFcmToken();
        return true;
      }
      state = AuthState.error(response.data['message'] ?? 'Login failed');
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Register user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    File? avatarFile,
  }) async {
    state = AuthState.loading();
    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        avatarFile: avatarFile,
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final userData = response.data['user'];

        await _apiService.setToken(token);
        final user = UserModel.fromJson(userData);
        state = AuthState.authenticated(user);

        // Sync FCM token
        syncFcmToken();
        return true;
      }
      state = AuthState.error(response.data['message'] ?? 'Registration failed');
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _apiService.clearAuth();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sync current device FCM Token with the backend
  Future<void> syncFcmToken() async {
    try {
      final fcmToken = await FCMService().getFCMToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final response = await _apiService.updateFcmToken(fcmToken);
        if (response.statusCode == 200) {
          print('FCM Token successfully synchronized with backend.');
        }
      }
    } catch (e) {
      print('FCM Token sync error: $e');
    }
  }
}

// Global Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
