import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API service handling all HTTP requests to the Next.js backend
class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  
  static String _baseUrl = _defaultBaseUrl;
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() : _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )) {
    // Request interceptor - attach auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null && options.headers['Authorization'] == null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _clearToken();
        }
        return handler.next(error);
      },
    ));

    // Logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  static void configure(String baseUrl) {
    _baseUrl = baseUrl;
  }

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Get stored JWT token
  Future<String?> _getToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (e) {
      return null;
    }
  }

  /// Store JWT token securely
  Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  /// Clear stored token
  Future<void> _clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // HTTP Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Multipart file upload for evidence
  Future<Response> upload(String path, List<MultipartFile> files, Map<String, dynamic> data) async {
    try {
      final formData = FormData();
      int index = 0;
      for (var file in files) {
        formData.files.add(MapEntry('file$index', file));
        index++;
      }
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      return await _dio.post(path, data: formData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to AppException
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['error'] ?? 'Server error occurred';
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      default:
        return Exception(error.message ?? 'Network error occurred');
    }
  }

  // --- Authentication Endpoints ---
  
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await post('/auth/login', data: {'email': email, 'password': password});
    
    if (response.data?['token'] != null) {
      await storeToken(response.data!['token']);
    }
    
    return response.data!;
  }

  Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final response = await post('/auth/register', data: {'name': name, 'email': email, 'password': password});
    
    if (response.data?['token'] != null) {
      await storeToken(response.data!['token']);
    }
    
    return response.data!;
  }

  Future<void> logout() async {
    await _clearToken();
  }

  // --- Reports Endpoints ---
  
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 50,
    String? type,
    double? nearLat,
    double? nearLng,
    double radiusKm = 50,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (nearLat != null) 'nearLat': nearLat,
      if (nearLng != null) 'nearLng': nearLng,
      'radiusKm': radiusKm,
    };
    
    final response = await get('/reports', queryParameters: queryParameters);
    return response.data!;
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    final response = await post('/reports', data: reportData);
    return response.data!;
  }

  Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    final response = await get('/reports/$reportId');
    return response.data!;
  }

  Future<List<dynamic>> getMyReports() async {
    final response = await get('/reports/me');
    return (response.data as List<dynamic>) ?? [];
  }

  // --- Notifications Endpoints ---
  
  Future<List<dynamic>> getNotifications() async {
    final response = await get('/notifications');
    return (response.data as List<dynamic>?) ?? [];
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await put('/notifications/$notificationId', data: {'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    await post('/notifications/read-all');
  }

  // --- SOS Endpoints ---
  
  Future<Map<String, dynamic>> triggerSOS({required Map<String, dynamic> location}) async {
    final response = await post('/sos/alert', data: {'location': location});
    return response.data!;
  }

  // --- User Profile Endpoints ---
  
  Future<Map<String, dynamic>> getProfile() async {
    final response = await get('/user/profile');
    return response.data!;
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    await put('/user/profile', data: profileData);
  }

  // --- SOS Contacts Endpoints ---
  
  Future<List<dynamic>> getSOSContacts() async {
    final response = await get('/sos-contacts');
    return (response.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> addSOSContact({required String name, required String phone}) async {
    final response = await post('/sos-contacts', data: {'name': name, 'phone': phone});
    return response.data!;
  }

  Future<void> deleteSOSContact(String contactId) async {
    await delete('/sos-contacts/$contactId');
  }

  // --- Admin Endpoints (for admin users only) ---
  
  Future<List<dynamic>> getPendingReports({int page = 1, int limit = 20}) async {
    final response = await get('/admin/reports', queryParameters: {'page': page, 'limit': limit, 'status': 'PENDING'});
    return (response.data['reports'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> verifyReport(String reportId) async {
    final response = await put('/admin/reports/$reportId/verify');
    return response.data!;
  }

  // --- Analytics Endpoints (NEW for Flutter) ---
  
  Future<Map<String, dynamic>> getAnalytics({String period = 'daily'}) async {
    final response = await get('/admin/analytics', queryParameters: {'period': period});
    return response.data!;
  }

  // --- Broadcast Alerts Endpoint (NEW for Flutter) ---
  
  Future<List<dynamic>> getBroadcastAlerts() async {
    final response = await get('/broadcast-alerts');
    return (response.data as List<dynamic>?) ?? [];
  }
}

/// Global API service instance
final apiService = ApiService();
