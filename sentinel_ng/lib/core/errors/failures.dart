import 'package:equatable/equatable.dart';

/// Base failure class for error handling (BLoC pattern)
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network error occurred'});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  
  const ValidationFailure({required super.message, this.fieldErrors});
}

class UploadFailure extends Failure {
  const UploadFailure({super.message = 'Upload failed'});
}

class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Location service unavailable'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred'});
}
