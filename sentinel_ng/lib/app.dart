import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/splash/splash_page.dart';
import 'features/auth/presentation/onboarding/onboarding_page.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/auth/presentation/register/register_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/reporting/presentation/reporting_wizard_screen.dart';
import 'features/emergency/presentation/sos_page.dart';
import 'features/emergency/presentation/live_emergency_screen.dart';
import 'features/route/presentation/safe_route_screen.dart';
import 'features/report/presentation/report_status_timeline_screen.dart';
import 'features/crime_details/presentation/crime_detail_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/profile/presentation/my_reports_screen.dart';
import 'features/profile/presentation/safety_score_detail_page.dart';
import 'features/profile/presentation/emergency_contacts_page.dart';
import 'features/profile/presentation/saved_locations_page.dart';

/// Main application widget with routing and dependency injection
class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  // GoRouter configuration for declarative navigation
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Auth flow routes
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main app routes (protected)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/reporting-wizard',
        name: 'reporting-wizard',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return ReportingWizardScreen(data: data);
        },
      ),
      GoRoute(
        path: '/sos-emergency',
        name: 'sos-emergency',
        builder: (context, state) => const SOSPage(),
      ),
      GoRoute(
        path: '/live-emergency',
        name: 'live-emergency',
        builder: (context, state) => const LiveEmergencyScreen(),
      ),
      GoRoute(
        path: '/crime-detail',
        name: 'crime-detail',
        builder: (context, state) {
          final reportId = state.uri.queryParameters['id'] as String? ?? '';
          return CrimeDetailScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/safe-route',
        name: 'safe-route',
        builder: (context, state) => const SafeRouteScreen(),
      ),
      GoRoute(
        path: '/my-reports',
        name: 'my-reports',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: '/report-status-timeline',
        name: 'report-status-timeline',
        builder: (context, state) {
          final reportId = state.uri.queryParameters['id'] as String? ?? '';
          return ReportStatusTimelineScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/safety-score-detail',
        name: 'safety-score-detail',
        builder: (context, state) => const SafetyScoreDetailPage(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        name: 'emergency-contacts',
        builder: (context, state) => const EmergencyContactsPage(),
      ),
      GoRoute(
        path: '/saved-locations',
        name: 'saved-locations',
        builder: (context, state) => const SavedLocationsPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: MaterialApp.router(
        title: 'Sentinel NG',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) {
          return SafeArea(child: child!);
        },
      ),
    );
  }
}
