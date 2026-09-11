# Sentinel NG — Flutter Mobile App Technical Documentation

**Version**: 1.0.0  
**Last Updated**: September 2025  
**Platform**: Android & iOS (via Flutter)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [Architecture](#4-architecture)
5. [API Integration](#5-api-integration)
6. [Data Models](#6-data-models)
7. [Features](#7-features)
8. [Build & Deployment](#8-build--deployment)

---

## 1. Overview

Sentinel NG Flutter app is the citizen-facing mobile application for the crime reporting platform. It provides a comprehensive set of features:

- **Multi-step Reporting Wizard**: Guided wizard with evidence collection (photos, video, audio)
- **Real-time SOS**: Emergency alert system with GPS tracking and contact notifications
- **Crime Map**: Interactive map with crime markers and filtering
- **Safety Score**: Gamified community engagement metric
- **Safe Routes**: Route optimization based on crime data

---

## 2. Tech Stack

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | ^3.x | Flutter SDK |
| `flutter_bloc` | ^9.1.0 | State Management (BLoC pattern) |
| `dio` | ^5.8.0+1 | HTTP Client with interceptors |
| `hive` + `hive_flutter` | ^2.2.3 | Local NoSQL database for offline caching |
| `go_router` | ^16.2.0 | Declarative navigation with deep linking |
| `flutter_secure_storage` | ^9.2.4 | Secure JWT token storage |

### UI & Media

| Package | Version | Purpose |
|---------|---------|---------|
| `google_maps_flutter` | ^2.12.1 | Interactive crime maps |
| `geolocator` | ^13.0.2 | GPS location services |
| `image_picker` | ^1.1.2 | Camera & gallery access for evidence |
| `video_player` | ^2.9.2 | Evidence video playback |
| `fl_chart` | ^0.70.2 | Charts (safety score gauges) |

### Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| `equatable` | ^2.0.7 | Value equality for BLoC states/events |
| `lottie` | ^3.3.1 | Animations (splash, onboarding) |
| `flutter_animate` | ^4.5.2 | Smooth transitions between wizard steps |
| `share_plus` | ^10.1.4 | Share functionality |
| `permission_handler` | ^11.3.1 | Runtime permission management |

---

## 3. Project Structure

```
sentinel_ng/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # MaterialApp + GoRouter configuration
│   │
│   ├── core/                        # Core infrastructure
│   │   ├── constants/               # App-wide constants
│   │   │   ├── app_colors.dart      # Color palette (#006400 primary green)
│   │   │   ├── app_routes.dart      # Route names/constants
│   │   │   └── app_strings.dart     # App text strings
│   │   ├── errors/                  # Error handling
│   │   │   ├── exceptions.dart      # Custom exception classes
│   │   │   └── failures.dart        # Failure types for BLoC
│   │   ├── services/                # Services layer
│   │   │   └── api_service.dart     # Dio client with auth interceptor
│   │   ├── theme/                   # Theme configuration
│   │   │   └── app_theme.dart       # Light/dark themes
│   │   └── widgets/                 # Reusable UI components
│   │       ├── custom_button.dart   # Primary green CTA button
│   │       ├── custom_textfield.dart# Styled text input with validation
│   │       └── loading_indicator.dart# Circular progress widget
│   │
│   ├── data/                        # Data layer
│   │   └── models/                  # JSON serialization models
│   │       ├── crime_report_model.dart
│   │       ├── notification_model.dart
│   │       └── user_model.dart
│   │
│   └── features/                    # Feature modules (Clean Architecture)
│       ├── auth/                    # Authentication feature
│       │   ├── bloc/auth_bloc.dart  # Login, register, logout logic
│       │   └── presentation/        # Auth screens
│       │       ├── splash/splash_page.dart
│       │       ├── onboarding/onboarding_page.dart
│       │       ├── login/login_page.dart
│       │       └── register/register_page.dart
│       │
│       ├── home/                    # Home dashboard
│       │   └── presentation/home_page.dart
│       │
│       ├── reporting/               # Crime reporting wizard
│       │   └── reporting_wizard_screen.dart  # 7-step wizard
│       │
│       ├── emergency/               # SOS & emergency features
│       │   ├── sos_page.dart        # Pulsing SOS button screen
│       │   └── live_emergency_screen.dart  # Active emergency state
│       │
│       ├── notifications/           # Notifications list
│       │   └── notifications_page.dart
│       │
│       ├── profile/                 # User profile & settings
│       │   ├── emergency_contacts_page.dart
│       │   ├── my_reports_screen.dart
│       │   ├── safety_score_detail_page.dart
│       │   └── saved_locations_page.dart
│       │
│       ├── crime_details/           # Report detail view
│       │   └── crime_detail_screen.dart
│       │
│       ├── search/                  # Search functionality
│       │   └── search_screen.dart
│       │
│       ├── route/                   # Safe route planning
│       │   └── safe_route_screen.dart
│       │
│       └── report/                  # Report status tracking
│           └── report_status_timeline_screen.dart
```

---

## 4. Architecture

### Clean Architecture with BLoC Pattern

The app follows **Clean Architecture** principles with the **BLoC (Business Logic Component)** pattern for state management.

#### Layer Separation

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Core** | Shared utilities, constants, widgets | `lib/core/` |
| **Data** | Models, JSON serialization | `lib/data/models/` |
| **Features** | Feature-specific logic and UI | `lib/features/*/` |

#### BLoC Pattern Implementation

```dart
// Event definition
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  
  LoginEvent(this.email, this.password);
  
  @override
  List<Object?> get props => [email, password];
}

// State definition
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final UserModel user;
  AuthSuccess(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC implementation
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  
  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.login(
        email: event.email, 
        password: event.password
      );
      emit(AuthSuccess(UserModel.fromJson(response['user'])));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
```

---

## 5. API Integration

### ApiService (Dio Client)

The `ApiService` is a singleton that wraps Dio with:

1. **Auth Interceptor**: Automatically attaches Bearer token from secure storage
2. **Error Handling**: Converts Dio errors to user-friendly messages
3. **Logging**: Debug logging in development mode

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() : _dio = Dio(BaseOptions(
        baseUrl: 'http://10.0.2.2:3000/api', // Android emulator default
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 30),
      )) {
    // Auth interceptor — attaches Bearer token automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && options.headers['Authorization'] == null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token'); // Clear invalid token
        }
        return handler.next(error);
      },
    ));

    // Debug logging in development
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  // Token management
  Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
```

### API Endpoints Mapped

| Flutter Method | HTTP | Backend Endpoint | Description |
|----------------|------|------------------|-------------|
| `login()` | POST | `/api/auth/login` | Authenticate & receive JWT |
| `register()` | POST | `/api/auth/register` | Create new account |
| `logout()` | — | — | Clear local token |
| `getReports()` | GET | `/api/reports` | Fetch verified reports + alerts |
| `createReport()` | POST | `/api/reports` | Submit crime report |
| `getMyReports()` | GET | `/api/reports/me` | User's submitted reports |
| `triggerSOS()` | POST | `/api/sos-alerts` | Create SOS alert |
| `getNotifications()` | GET | `/api/notifications` | Fetch notifications |
| `markNotificationAsRead()` | PUT | `/api/notifications/[id]` | Mark single as read |
| `markAllNotificationsAsRead()` | POST | `/api/notifications/read-all` | Bulk mark all as read |
| `getSOSContacts()` | GET | `/api/sos-contacts` | List emergency contacts |
| `addSOSContact()` | POST | `/api/sos-contacts` | Add new contact |
| `deleteSOSContact()` | DELETE | `/api/sos-contacts/[id]` | Remove contact |
| `getProfile()` | GET | `/api/user/profile` | User profile + preferences |
| `updateProfile()` | PUT | `/api/user/profile` | Update user name |
| `getAnalytics()` | GET | `/api/admin/analytics` | Analytics data (admin) |

### Error Handling Strategy

```dart
Exception _handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return Exception('Connection timed out. Please check your internet connection.');
    
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final message = error.response?.data['error'] ?? 'Server error occurred';
      
      if (statusCode == 401) {
        return Exception('Session expired. Please log in again.');
      } else if (statusCode == 429) {
        return Exception('Too many requests. Please wait a moment.');
      }
      return Exception(message);
    
    case DioExceptionType.cancel:
      return Exception('Request was cancelled');
    
    default:
      return Exception(error.message ?? 'Network error occurred');
  }
}
```

---

## 6. Data Models

### User Model

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "USER" or "ADMIN"
  final bool isBanned;
  final DateTime? bannedAt;
  final DateTime createdAt;
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      isBanned: json['isBanned'] ?? false,
      bannedAt: json['bannedAt'] != null ? DateTime.parse(json['bannedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### CrimeReport Model

```dart
class CrimeReportModel {
  final String id;
  final String type; // "armed_robbery", "theft", etc.
  final String description;
  final ReportStatus status; // PENDING, VERIFIED, REJECTED
  final RiskLevel riskLevel; // LOW, MEDIUM, HIGH
  final Map<String, dynamic> location; // GeoJSON Point
  final List<String> mediaUrls;
  final bool isAnonymous;
  final DateTime createdAt;
  
  // Flutter-specific fields
  final List<dynamic>? witnesses;
  final Map<String, dynamic>? suspectInfo;
  final List<dynamic>? verificationHistory;
  final List<dynamic>? evidence;
}

enum ReportStatus { PENDING, VERIFIED, REJECTED }
enum RiskLevel { LOW, MEDIUM, HIGH }
```

### Notification Model

```dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
}
```

---

## 7. Features

### Authentication Flow

1. **Splash Screen** → Check auth status → Navigate to Onboarding or Home
2. **Onboarding** (3 screens) → Skip or Complete → Login/Register
3. **Login** → POST /api/auth/login → Store JWT → Navigate to Home
4. **Register** → POST /api/auth/register → Show verification message

### Reporting Wizard (7 Steps)

| Step | Screen | Data Collected |
|------|--------|---------------|
| 1 | Select Crime Type | type (armed_robbery, theft, etc.) |
| 2 | Select Location | GeoJSON coordinates + address |
| 3 | Incident Description | description text (500 char max) |
| 4 | Witness Information | name, phone, statement (optional) |
| 5 | Suspect Information | description, vehicle info (optional) |
| 6 | Evidence Collection | Photos (up to 6), audio, video |
| 7 | Preview & Submit | Review all data → POST /api/reports |

### SOS Emergency Flow

1. **SOS Page** → Large pulsing button with GPS integration
2. **On Tap** → POST /api/sos-alerts with location
3. **Live Emergency Screen** → Shows "Help is on the way!" + live tracking
4. **Cancel/Extend** → Timer options for emergency duration

### Safety Score System

- Overall score gauge (circular progress)
- 4 metric breakdowns: onlineActivity, communityParticipation, reportAccuracy, responseTime
- Weekly trend chart using fl_chart
- Improvement tips section

---

## 8. Build & Deployment

### Environment Configuration

```bash
# Android emulator development
flutter run -d chrome --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

# iOS simulator / local dev
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api

# Production (Render.com backend)
flutter build apk --dart-define=API_BASE_URL=https://crime-location-reporting.onrender.com/api
```

### Build Commands

```bash
# Analyze code for issues
flutter analyze

# Run unit tests
flutter test

# Build APK for Android
flutter build apk --release

# Build App Bundle for Google Play
flutter build appbundle --release

# Build iOS archive
flutter build ios --release
```

### Key Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies & assets configuration |
| `lib/core/constants/app_colors.dart` | Color palette (#006400 primary green) |
| `lib/core/theme/app_theme.dart` | Light/dark theme definitions |
| `lib/app.dart` | GoRouter navigation setup |

### Assets Structure

```
assets/
├── images/          # App branding, illustrations
└── icons/           # Custom icons (if any)
```

---

## Appendix A: Screen Inventory

| Screen | Feature | Description |
|--------|---------|-------------|
| SplashPage | Auth | Animated splash with auto-navigation |
| OnboardingPage | Auth | 3-page swipeable onboarding |
| LoginPage | Auth | Email/password + Google OAuth placeholder |
| RegisterPage | Auth | Full registration form |
| HomePage | Home | Dashboard with safety score, quick actions |
| CrimeMapPage | Map | Interactive map with crime markers |
| ReportingWizardScreen | Reporting | 7-step guided wizard |
| ReportSubmittedScreen | Reporting | Success screen with report ID |
| SOSPage | Emergency | Pulsing SOS button |
| LiveEmergencyScreen | Emergency | Active emergency state |
| NotificationsPage | Notifications | Categorized notification list |
| ProfilePage | Profile | User info, settings |
| EmergencyContactsPage | Profile | Full CRUD for contacts |
| MyReportsPage | Profile | User's reports with filtering |
| SafetyScoreDetailPage | Profile | Detailed score breakdown |
| SavedLocationsPage | Profile | Home/Work/Education locations |
| SafeRouteScreen | Route | Origin/destination route planning |
| CrimeDetailScreen | Details | Full report view with evidence |
| SearchPage | Search | Location/crime type search |
| ReportStatusTimelineScreen | Status | Detailed status change timeline |

---

*Document generated for Sentinel NG Flutter v1.0.0*  
*Mobile Application Technical Reference*
