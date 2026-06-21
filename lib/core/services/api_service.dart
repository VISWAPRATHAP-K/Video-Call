import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initDio();
  }

  late Dio _dio;
  static const String _serverUrlKey = 'backend_server_url';
  static const String _tokenKey = 'auth_jwt_token';

  // Default IP: 10.0.2.2 is Android emulator local host loopback, localhost for iOS simulator
  static String get defaultBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Request interceptor to automatically inject JWT authentication header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Dynamically set Base URL based on stored value
        final storedUrl = prefs.getString(_serverUrlKey) ?? defaultBaseUrl;
        options.baseUrl = storedUrl;

        return handler.next(options);
      },
    ));

    // Logging interceptor for debugging network calls
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
  }

  /// Get current configured server base URL
  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? defaultBaseUrl;
  }

  /// Save custom server base URL (useful for testing on physical devices)
  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }

  /// Retrieve the authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save the authentication token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Remove the token (Logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // --- Endpoints ---

  /// Register User (handles optional avatar upload)
  Future<Response> register({
    required String username,
    required String email,
    required String password,
    File? avatarFile,
  }) async {
    try {
      MultipartFile? file;
      if (avatarFile != null) {
        final filename = avatarFile.path.split('/').last;
        file = await MultipartFile.fromFile(avatarFile.path, filename: filename);
      }

      final formData = FormData.fromMap({
        'username': username,
        'email': email,
        'password': password,
        if (file != null) 'avatar': file,
      });

      return await _dio.post('/users/register', data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login User
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _dio.post('/users/login', data: {
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update FCM Push Token
  Future<Response> updateFcmToken(String fcmToken) async {
    try {
      return await _dio.put('/users/fcm-token', data: {'fcmToken': fcmToken});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get Current User Profile
  Future<Response> getProfile() async {
    try {
      return await _dio.get('/users/me');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch All Contacts/Users list
  Future<Response> getAllUsers() async {
    try {
      return await _dio.get('/users');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Initiate Call (FCM Signal + Agora Token generation)
  Future<Response> initiateCall({
    required int receiverId,
    required String channelName,
    required bool isVideo,
  }) async {
    try {
      return await _dio.post('/users/call', data: {
        'receiverId': receiverId,
        'channelName': channelName,
        'isVideo': isVideo,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Accept Call (returns Agora Token for Receiver)
  Future<Response> acceptCall({required String channelName}) async {
    try {
      return await _dio.post('/users/call/accept', data: {
        'channelName': channelName,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    developer.log('ApiService Error: $error');
    if (error.response != null && error.response?.data != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return error.message ?? 'An unknown connection error occurred.';
  }
}
