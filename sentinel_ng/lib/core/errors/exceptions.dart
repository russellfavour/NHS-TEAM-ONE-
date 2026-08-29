/// Base exception class for all app exceptions
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({super.message = 'Network error occurred', super.statusCode});
}

class TimeoutException extends AppException {
  TimeoutException({super.message = 'Request timed out', super.statusCode});
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException({required super.message, super.statusCode});
  
  static const String invalidCredentials = 'Invalid email or password';
  static const String accountNotFound = 'Account not found';
  static const String emailNotVerified = 'Please verify your email first';
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({required super.message, this.fieldErrors});
}

/// Server-related exceptions
class ServerException extends AppException {
  ServerException({super.message = 'Server error occurred', super.statusCode});
}

/// File upload exceptions
class UploadException extends AppException {
  UploadException({required super.message, super.statusCode});
}

/// Location-related exceptions
class LocationException extends AppException {
  LocationException({super.message = 'Location service unavailable', super.statusCode});
}
