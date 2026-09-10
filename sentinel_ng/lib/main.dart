import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'core/services/api_service.dart';
import 'features/auth/bloc/auth_bloc.dart';

// Compile-time constant (required for Flutter Web — String.fromEnvironment
// can only be used in a const context there). Override with:
//   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Platform-aware default API base URL.
///
/// - Web: the Next.js backend is expected on port 3000 of the same host the app
///   is served from (e.g. http://localhost:8080 → http://localhost:3000/api).
///   CORS for localhost:* / 127.0.0.1:* origins is enabled in the backend proxy.
/// - Android emulator: 10.0.2.2 maps to the host machine's localhost.
/// - iOS simulator / physical devices: use --dart-define=API_BASE_URL=...
String _defaultBaseUrl() {
  if (kIsWeb) {
    try {
      final host = web.window.location.hostname;
      if (host.isNotEmpty) return 'http://$host:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }
  return 'http://10.0.2.2:3000/api'; // Android emulator localhost
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Configure API service with environment-based base URL
  final baseUrl = _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : _defaultBaseUrl();
  ApiService.configure(baseUrl);
  debugPrint('[Sentinel] API base URL: $baseUrl');

  runApp(const SentinelApp());
}
