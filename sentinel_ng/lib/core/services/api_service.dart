import 'dart:io' show File, Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API service handling all HTTP requests to the Next.js backend.
class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator

  static String _baseUrl = _defaultBaseUrl;

  final Dio _dio;
  late final FlutterSecureStorage _storage;

  ApiService._internal() : _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )) {
    // FlutterSecureStorage is not available on all web browsers in every context;
    // fall back gracefully (token simply won't persist across reloads).
    _storage = const FlutterSecureStorage();

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
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ));
    }
  }

  static void configure(String baseUrl) {
    _baseUrl = baseUrl;
  }

  /// Base URL (e.g. http://localhost:3000/api) — exposed for building absolute media URLs.
  String get baseUrl => _baseUrl;

  /// Origin of the backend without the /api suffix (e.g. http://localhost:3000).
  String get origin {
    final b = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    return b.endsWith('/api') ? b.substring(0, b.length - 4) : b;
  }

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Get stored JWT token
  Future<String?> _getToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (e) {
      debugPrint('[ApiService] Token read failed: $e');
      return null;
    }
  }

  /// Store JWT token securely
  Future<void> storeToken(String token) async {
    try {
      await _storage.write(key: 'jwt_token', value: token);
    } catch (e) {
      debugPrint('[ApiService] Token write failed: $e');
    }
  }

  /// Clear stored token
  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (_) {}
  }

  /// Check if user is authenticated (token present)
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

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
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

  /// Upload a single media file (photo/video/audio) to POST /api/uploads.
  /// Returns the stored URL (relative in dev, absolute from Cloudinary in prod).
  Future<String> uploadMediaFile(File file, {String? fileName}) async {
    final bytes = await file.readAsBytes();
    return uploadMediaBytes(bytes, fileName ?? file.path.split(Platform.pathSeparator).last);
  }

  /// Upload raw media bytes (preferred on web where XFile paths are blob URLs).
  Future<String> uploadMediaBytes(List<int> bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(
        '/uploads',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final url = (response.data is Map<String, dynamic>) ? response.data!['url'] : null;
      if (url is String && url.isNotEmpty) return url;
      throw Exception('Upload succeeded but no URL was returned.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert a possibly-relative media URL (e.g. /uploads/xyz.jpg in dev) to an absolute one.
  String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (!url.startsWith('/')) return url; // already relative or data URI
    return '$origin$url';
  }

  String? _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    return null;
  }

  /// Handle Dio errors and convert to a user-friendly Exception.
  ///
  /// IMPORTANT: response bodies are not always JSON — error pages can be HTML or
  /// plain text. Indexing a String with a String key in Dart throws
  /// `TypeError: "error": type 'String' is not a subtype of type 'int'`, which was
  /// the cause of the web login crash. We therefore guard every data access.
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final dynamic data = error.response?.data;
        String message;
        if (data is Map<String, dynamic>) {
          message = (data['error'] ?? data['message'] ?? 'Server error occurred').toString();
        } else {
          // Non-JSON body (HTML/text). Never surface raw markup to the user.
          message = statusCode != null ? 'Request failed ($statusCode)' : 'Server error occurred';
        }
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception(
            'Unable to reach the server. Make sure the backend is running and your connection is stable.');
      default:
        final msg = error.message;
        if (msg != null && msg.isNotEmpty) {
          // Avoid leaking raw stack/URI noise into UI strings.
          if (msg.contains('SocketException') || msg.contains('Connection refused')) {
            return Exception('Unable to reach the server. Please try again.');
          }
          return Exception(msg);
        }
        return Exception('Network error occurred');
    }
  }

  // --- Authentication Endpoints ---

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await post('/auth/login', data: {'email': email, 'password': password});

    if (response.data is Map<String, dynamic> && response.data!['token'] != null) {
      await storeToken(response.data!['token'] as String);
    }

    return response.data! as Map<String, dynamic>;
  }

  /// Registers a new account. The backend does NOT return a token (email
  /// verification is required first), so callers should handle the
  /// "check your email" flow and then send the user to login.
  Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final response = await post('/auth/register', data: {'name': name, 'email': email, 'password': password});

    if (response.data is Map<String, dynamic> && response.data!['token'] != null) {
      await storeToken(response.data!['token'] as String);
    }

    return response.data! as Map<String, dynamic>;
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
    return response.data! as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    final response = await post('/reports', data: reportData);
    return response.data! as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    final response = await get('/reports/$reportId');
    return response.data! as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyReports() async {
    final response = await get('/reports/me');
    return (response.data is List<dynamic>) ? response.data! : [];
  }

  // --- Notifications Endpoints ---

  /// Returns `{notifications: [...], pagination: {...}}`.
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
  }) async {
    final response = await get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
      if (isRead != null) 'isRead': isRead.toString(),
      if (type != null) 'type': type,
    });
    return response.data! as Map<String, dynamic>;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await patch('/notifications/$notificationId');
  }

  Future<void> markAllNotificationsAsRead() async {
    await post('/notifications/read-all');
  }

  // --- Notification Preferences Endpoints ---

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await get('/notifications/preferences');
    return response.data! as Map<String, dynamic>;
  }

  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    await put('/notifications/preferences', data: preferences);
  }

  // --- SOS Endpoints ---

  Future<Map<String, dynamic>> triggerSOS({required Map<String, dynamic> location}) async {
    final response = await post('/sos/alert', data: {'location': location});
    return response.data! as Map<String, dynamic>;
  }

  // --- User Profile Endpoints ---

  /// Returns `{user: {...}, preferences: {...}|null}`.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await get('/user/profile');
    return response.data! as Map<String, dynamic>;
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    await put('/user/profile', data: profileData);
  }

  // --- SOS Contacts Endpoints ---

  Future<List<dynamic>> getSOSContacts() async {
    final response = await get('/sos-contacts');
    return (response.data is List<dynamic>) ? response.data! : [];
  }

  Future<Map<String, dynamic>> addSOSContact({required String name, required String phone}) async {
    final response = await post('/sos-contacts', data: {'name': name, 'phone': phone});
    return response.data! as Map<String, dynamic>;
  }

  Future<void> deleteSOSContact(String contactId) async {
    await delete('/sos-contacts/$contactId');
  }

  // --- Admin Endpoints (for admin users only) ---

  Future<List<dynamic>> getPendingReports({int page = 1, int limit = 20}) async {
    final response = await get('/admin/reports', queryParameters: {'page': page, 'limit': limit, 'status': 'PENDING'});
    return (response.data is Map<String, dynamic> && response.data!['reports'] is List<dynamic>)
        ? response.data!['reports'] as List<dynamic>
        : [];
  }

  Future<Map<String, dynamic>> verifyReport(String reportId) async {
    final response = await put('/admin/reports/$reportId/verify');
    return response.data! as Map<String, dynamic>;
  }

  // --- Analytics Endpoints (NEW for Flutter) ---

  Future<Map<String, dynamic>> getAnalytics({String period = 'daily'}) async {
    final response = await get('/admin/analytics', queryParameters: {'period': period});
    return response.data! as Map<String, dynamic>;
  }

  // --- Broadcast Alerts Endpoint (NEW for Flutter) ---

  Future<List<dynamic>> getBroadcastAlerts() async {
    final response = await get('/broadcast-alerts');
    return (response.data is List<dynamic>) ? response.data! : [];
  }
}

/// Global API service instance
final apiService = ApiService();
