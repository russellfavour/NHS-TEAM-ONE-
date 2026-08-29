import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/api_service.dart';
import 'features/auth/bloc/auth_bloc.dart';

// Compile-time constant (required for Flutter Web — String.fromEnvironment
// can only be used in a const context there). Override with:
//   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api', // Android emulator localhost
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Configure API service with environment-based base URL
  ApiService.configure(_apiBaseUrl);
  
  runApp(const SentinelApp());
}
