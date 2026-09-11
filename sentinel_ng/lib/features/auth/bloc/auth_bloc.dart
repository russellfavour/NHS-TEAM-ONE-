import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterEvent({required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

/// Registration succeeded but the backend requires email verification before a
/// token is issued. UI should show "check your email" and route to login.
class AuthRegistered extends AuthState {
  final String? message;
  const AuthRegistered({this.message});
  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final Failure failure;
  const AuthError({required this.failure});
  @override
  List<Object?> get props => [failure];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();

  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(
        email: event.email,
        password: event.password,
      );
      
      // Parse user from response (adapt to your actual API response structure)
      final userData = response['user'] ?? response;
      final user = UserModel.fromJson(userData);
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(failure: AuthFailure(message: e.toString())));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      // The backend only returns a token when it can issue one immediately.
      // Normally registration requires email verification first, so there is no
      // token — surface that instead of faking an authenticated session.
      if (response['token'] != null) {
        final userData = response['user'] ?? response;
        final user = UserModel.fromJson(userData as Map<String, dynamic>);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthRegistered(
          message: 'Registration successful. Please check your email to verify your account.',
        ));
      }
    } catch (e) {
      emit(AuthError(failure: AuthFailure(message: e.toString())));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _apiService.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final isAuthenticated = await _apiService.isAuthenticated();
    if (isAuthenticated) {
      try {
        // Try to fetch user profile to verify token is valid.
        // Response shape: { user: {...}, preferences: {...}|null }
        final response = await _apiService.getProfile();
        final dynamic rawUser = response['user'] ?? response;
        if (rawUser is Map<String, dynamic> && rawUser['id'] != null) {
          emit(AuthAuthenticated(user: UserModel.fromJson(rawUser)));
        } else {
          // Token present but profile unusable — treat as unauthenticated so the
          // user can log in again rather than getting stuck with an empty profile.
          await _apiService.logout();
          emit(AuthUnauthenticated());
        }
      } catch (_) {
        // Network hiccup: keep the token (user may be offline) but don't claim
        // we know who they are. Splash will route to login; a stored token lets
        // them retry without re-entering credentials on next launch.
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
