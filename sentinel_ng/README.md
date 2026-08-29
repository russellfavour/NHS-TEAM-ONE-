# 🛡️ Sentinel NG — Crime Location Reporting System

## A Comprehensive Platform for Community Safety in Nigeria

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Features](#features)
- [Getting Started](#getting-started)
- [Development Guide](#development-guide)
- [API Integration](#api-integration)
- [Design System](#design-system)
- [Screens & User Flow](#screens--user-flow)
- [Admin Portal](#admin-portal)
- [Roadmap](#roadmap)

---

## Overview

**Sentinel NG** is a comprehensive crime reporting and community safety platform designed specifically for Nigerian communities. The system consists of two main components:

1. **Mobile App (Flutter)** — Citizen-facing application for reporting crimes, tracking emergencies, and staying informed about local safety
2. **Admin Web Portal (Next.js)** — Agency-facing dashboard for monitoring reports, verifying submissions, managing dispatches, and generating analytics

### Key Differentiators

- 📝 **Multi-Step Reporting Wizard** — Guided, conversational crime reporting experience
- 🛡️ **Safety Score System** — Gamified community engagement metric
- 🚨 **Real-Time SOS + ETA Tracking** — Live emergency response capability
- 🗺️ **AI Safety Route Planning** — Route optimization based on crime data heatmaps
- 📸 **Evidence-Rich Reports** — Photos, video, audio recording directly in the report flow
- 🔒 **Anonymous Reporting Option** — Privacy-first design encouraging community participation
- 🇳🇬 **Nigerian Context** — Localized for Nigerian cities (Lagos focus), addresses real local needs
- 👥 **Dual-Platform Architecture** — Mobile app for citizens + Web portal for agencies

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SENTINEL NG PLATFORM                      │
├──────────────────────────┬──────────────────────────────────┤
│                          │                                  │
│  Flutter Mobile App      │    Next.js Web Application       │
│  (Citizen-Facing)        │    (Admin + Existing Frontend)   │
│                          │                                  │
│  • Home Dashboard        │    • Admin Dashboard             │
│  • Crime Reporting       │    • Report Review List          │
│  • SOS Emergency         │    • User Management             │
│  • Safety Routes         │    • Analytics Charts            │
│  • Notifications         │    • Audit Logs                  │
│  • Profile & Settings    │    • System Settings             │
│                          │                                  │
└──────────────┬───────────┴──────────────┬───────────────────┘
               │                          │
               ▼                          ▼
        ┌─────────────────────────────────────────┐
        │         Next.js API Routes              │
        │    (Single Backend for Both Apps)       │
        │                                         │
        │  • /api/auth/*     Authentication       │
        │  • /api/reports/*  Crime Reports        │
        │  • /api/admin/*    Admin Operations     │
        │  • /api/notifications/* Notifications   │
        │  • /api/sos/*      SOS Emergency        │
        │  • /api/user/*     User Management      │
        └──────────────┬──────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   MongoDB       │
              │   (Single DB)   │
              └─────────────────┘
```

### Why This Architecture?

- ✅ **Zero risk to existing app** — All current API routes remain untouched
- ✅ **Single database** — No data duplication, no sync issues
- ✅ **One deployment** — Deploy Next.js once; both Flutter and web apps share it
- ✅ **Leverages existing admin pages** — Our Next.js already has `src/app/admin/` with reports, users, logs, settings!
- ✅ **Prisma schema is shared** — Both Flutter and Next.js use the same ORM definitions

---

## Tech Stack

### Mobile App (Flutter)

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Flutter | 3.x |
| State Management | flutter_bloc + equatable | ^9.1.0 |
| HTTP Client | dio | ^5.8.0+1 |
| Routing | go_router | ^16.2.0 |
| Local Storage | hive_flutter | ^1.1.0 |
| Secure Storage | flutter_secure_storage | ^9.2.4 |
| Maps | google_maps_flutter | ^2.12.1 |
| Location | geolocator | ^13.0.2 |
| Image Picker | image_picker | ^1.1.2 |
| Video Player | video_player | ^2.9.2 |
| Audio Recording | record | ^5.2.1 |
| Charts | fl_chart | ^0.70.2 |
| Animations | flutter_animate | ^4.5.2 |

### Web Application (Next.js)

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Next.js | 16.x (App Router) |
| UI Library | React | 19.x |
| Styling | Tailwind CSS | 4.x |
| ORM | Prisma | 6.x |
| Database | MongoDB | Latest |
| Authentication | NextAuth v5 | Latest |
| Charts | Recharts | Latest |
| File Storage | Cloudinary | Latest |
| Rate Limiting | @upstash/ratelimit | Latest |

---

## Project Structure

### Flutter Mobile App (`sentinel_ng/`)

```
sentinel_ng/
├── lib/
│   ├── main.dart                          # App entry point + theme config
│   ├── app.dart                           # MaterialApp configuration + GoRouter
│   │
│   ├── core/                              # Shared infrastructure
│   │   ├── constants/
│   │   │   ├── colors.dart                # Primary green (#006400), red, white palette
│   │   │   ├── strings.dart               # App-wide text constants
│   │   │   └── routes.dart                # Route names (navigators)
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Light/dark theme definitions
│   │   ├── utils/
│   │   │   ├── validators.dart            # Form validation helpers
│   │   │   └── formatters.dart            # Phone, date formatting
│   │   ├── services/
│   │   │   └── api_service.dart           # HTTP client (Dio) + auth token handling
│   │   ├── widgets/
│   │   │   ├── custom_button.dart         # Reusable green CTA button
│   │   │   ├── custom_textfield.dart      # Styled text input
│   │   │   └── loading_indicator.dart     # Circular progress widget
│   │   └── errors/
│   │       ├── exceptions.dart            # Custom exception classes
│   │       └── failures.dart              # Failure types (equatable)
│   │
│   ├── data/                              # Data layer
│   │   ├── models/                        # All data models (JSON ↔ Dart)
│   │   │   ├── user_model.dart
│   │   │   ├── crime_report_model.dart
│   │   │   └── notification_model.dart
│   │   └── repositories/                  # Repository interface implementations
│   │       ├── auth_repository_impl.dart
│   │       └── crime_repository_impl.dart
│   │
│   ├── features/                          # Feature modules (one per domain)
│   │   ├── auth/                          # 🔐 Authentication feature
│   │   │   ├── bloc/auth_bloc.dart        # Auth state management
│   │   │   └── presentation/
│   │   │       ├── splash/splash_page.dart
│   │   │       ├── onboarding/onboarding_page.dart
│   │   │       ├── login/login_page.dart
│   │   │       └── register/register_page.dart
│   │   │
│   │   ├── home/                          # 🏠 Home Dashboard feature
│   │   │   └── presentation/home_page.dart  # Bottom nav + dashboard + map + alerts + profile
│   │   │
│   │   ├── reporting/                     # 📝 Crime Reporting Wizard (MAIN FEATURE)
│   │   │   └── presentation/
│   │   │       └── reporting_wizard_screen.dart  # Multi-step wizard orchestrator
│   │   │
│   │   ├── emergency/                     # 🚨 SOS / Emergency feature
│   │   │   └── presentation/
│   │   │       ├── sos_page.dart          # Pulsing red button screen
│   │   │       └── live_emergency_screen.dart  # Active alert + ETA tracking
│   │   │
│   │   ├── map/                           # 🗺️ Crime Map feature (skeleton)
│   │   │   └── presentation/crime_map_page.dart
│   │   │
│   │   ├── notifications/                 # 🔔 Notifications feature (skeleton)
│   │   │   └── presentation/notifications_page.dart
│   │   │
│   │   ├── profile/                       # 👤 Profile feature (skeleton)
│   │   │   └── presentation/
│   │   │       ├── my_reports_screen.dart
│   │   │       ├── safety_score_detail_page.dart
│   │   │       ├── emergency_contacts_page.dart
│   │   │       └── saved_locations_page.dart
│   │   │
│   │   ├── crime_details/                 # 🔍 Crime Detail feature (skeleton)
│   │   │   └── presentation/crime_detail_screen.dart
│   │   │
│   │   ├── search/                        # 🔎 Search feature (skeleton)
│   │   │   └── presentation/search_screen.dart
│   │   │
│   │   ├── route/                         # 🛣️ Safe Route feature (skeleton)
│   │   │   └── presentation/safe_route_screen.dart
│   │   │
│   │   └── report/                        # 📊 Report Status Timeline (skeleton)
│   │       └── presentation/report_status_timeline_screen.dart
│   │
│   ├── navigation/                        # Routing configuration
│   │   └── app_router.dart                # GoRouter setup + route guards
│   │
│   └── di/                                # Dependency injection (if using get_it)
│       └── service_locator.dart
│
├── assets/                                # Static assets
│   ├── images/                            # App logos, illustrations
│   └── icons/                             # Custom icons
│
├── test/                                  # Unit and widget tests
│   └── widget_test.dart
│
├── pubspec.yaml                           # Dependencies + configuration
├── README.md                              # This file
└── TODO.md                                # Implementation roadmap
```

### Next.js Web Application (`crime-location-reporting-system/`)

```
crime-location-reporting-system/
├── src/
│   ├── app/                               # App Router pages
│   │   ├── api/                           # API routes (backend)
│   │   │   ├── auth/[...nextauth]/        # NextAuth session management
│   │   │   ├── auth/register/             # User registration
│   │   │   ├── reports/                   # Crime report CRUD
│   │   │   ├── admin/                     # Admin operations
│   │   │   ├── notifications/             # Notification endpoints
│   │   │   ├── sos/                       # SOS emergency endpoints
│   │   │   └── user/                      # User profile endpoints
│   │   │
│   │   ├── (auth)/                        # Auth pages (login, register)
│   │   ├── admin/                         # Admin portal pages
│   │   │   ├── page.tsx                   # Dashboard overview
│   │   │   ├── reports/page.tsx           # Report review list
│   │   │   ├── users/page.tsx             # User management
│   │   │   ├── logs/page.tsx              # Audit log viewer
│   │   │   └── settings/page.tsx          # System settings
│   │   │
│   │   ├── (app)/                         # Main app pages
│   │   ├── layout.tsx                     # Root layout
│   │   └── page.tsx                       # Home page
│   │
│   ├── components/                        # Shared UI components
│   │   ├── admin/                         # Admin-specific components
│   │   │   ├── charts/                    # Recharts chart components
│   │   │   ├── data-tables/               # Paginated report tables
│   │   │   └── modals/                    # Verification/risk tagging modals
│   │   ├── layout/                        # Header, sidebar, footer
│   │   └── ui/                            # Reusable UI primitives
│   │
│   ├── lib/                               # Utilities + configuration
│   │   ├── prisma.ts                      # Prisma client instance
│   │   ├── auth.ts                        # NextAuth configuration
│   │   └── utils.ts                       # Helper functions
│   │
│   ├── middleware.ts                      # CORS + auth middleware
│   └── types/                             # TypeScript type definitions
│
├── prisma/                                # Database schema
│   └── schema.prisma                      # Prisma models (User, Report, etc.)
│
├── .env                                   # Environment variables
├── next.config.js                         # Next.js configuration
├── package.json                           # Dependencies + scripts
└── README.md                              # Web app documentation
```

---

## Features

### Mobile App Features (Flutter)

| Feature | Status | Description |
|---------|--------|-------------|
| **Splash Screen** | ✅ UI Done | Animated branding with shield icon and tagline |
| **Onboarding** | ✅ UI Done | 3-page carousel explaining app features |
| **Login/Register** | ✅ UI Done | Form-based auth with validation (needs API integration) |
| **Home Dashboard** | ✅ UI Done | Safety score card, quick actions, recent alerts |
| **Bottom Navigation** | ✅ UI Done | 5 tabs: Home, Map, FAB, Alerts, Profile |
| **Crime Reporting Wizard** | ✅ UI Done | Multi-step wizard (crime type → location → description → witnesses → suspect → evidence) |
| **SOS Emergency** | ✅ UI Done | Pulsing red button with live emergency tracking |
| **Safety Routes** | 🟡 Skeleton | Route planning with safety scoring |
| **Crime Map** | 🟡 Skeleton | Interactive map with markers and filters |
| **Notifications** | 🟡 Skeleton | Categorized alert list (All, Alerts, Updates, System) |
| **Profile** | 🟡 Skeleton | User info, settings, report history |
| **Search** | 🟡 Skeleton | Location/crime type search with history |
| **Crime Details** | 🟡 Skeleton | Detailed report view with evidence thumbnails |
| **Report Status Timeline** | 🟡 Skeleton | Visual progress tracker for submitted reports |

### Admin Portal Features (Next.js)

| Feature | Status | Description |
|---------|--------|-------------|
| **Admin Login** | ✅ Built | Dual-factor admin login with role verification |
| **Dashboard Overview** | ✅ Built | Stats cards, recent activity, quick actions |
| **Report Review List** | ✅ Built | Paginated table with status filters and search |
| **User Management** | ✅ Built | User list, profile details, ban/suspend controls |
| **Audit Logs** | ✅ Built | Admin action history viewer |
| **System Settings** | ✅ Built | Configuration for distance threshold, decay days, crowd threshold |
| **Analytics Charts** | ✅ Built | Crime type distribution, temporal trends, risk levels (Recharts) |
| **CSV Export** | ✅ Built | Filterable export of reports to CSV file download |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.8+
- Node.js 18+ (for Next.js backend)
- MongoDB instance (local or Atlas)
- Git

### Mobile App Setup

```bash
# Navigate to the Flutter project
cd sentinel_ng

# Get dependencies
flutter pub get

# Run on Chrome (for development)
flutter run -d chrome

# Or run on Android emulator/device
flutter run -d <device-id>
```

### Web Application Setup

```bash
# Navigate to the Next.js project
cd crime-location-reporting-system

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your MongoDB URL, JWT secret, etc.

# Run Prisma migrations
npx prisma migrate dev

# Start development server
npm run dev
```

### Environment Variables

**Flutter (`lib/core/services/api_service.dart`):**
```dart
// Android emulator localhost
static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api';

// iOS simulator / Chrome web
static const String _defaultBaseUrl = 'http://localhost:3000/api';
```

**Next.js (`.env.local`):**
```bash
DATABASE_URL="mongodb+srv://..."
NEXTAUTH_SECRET="your-secret-key"
NEXTAUTH_URL="http://localhost:3000"
CLOUDINARY_CLOUD_NAME="your-cloud-name"
CLOUDINARY_API_KEY="your-api-key"
CLOUDINARY_API_SECRET="your-api-secret"
```

---

## Development Guide

### Running the App

The Flutter app uses **GoRouter** for declarative navigation. Routes are defined in `lib/app.dart`:

```dart
// Auth flow routes
GoRoute(path: '/', name: 'splash', builder: (context, state) => const SplashPage()),
GoRoute(path: '/onboarding', name: 'onboarding', builder: (context, state) => const OnboardingPage()),
GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterPage()),

// Main app routes (protected)
GoRoute(path: '/home', name: 'home', builder: (context, state) => const HomePage()),
GoRoute(path: '/reporting-wizard', name: 'reporting-wizard', builder: ...),
```

### State Management

The app uses **flutter_bloc** for state management. Each feature has its own BLoC:

```dart
// Example: Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();

  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }
}
```

### API Integration

The `ApiService` class handles all HTTP requests to the Next.js backend:

```dart
// Singleton pattern with Dio client
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Auth endpoints
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await post('/auth/login', data: {'email': email, 'password': password});
    if (response.data?['token'] != null) {
      await storeToken(response.data!['token']);
    }
    return response.data!;
  }

  // Reports endpoints
  Future<Map<String, dynamic>> getReports({int page = 1, int limit = 50}) async {
    final response = await get('/reports', queryParameters: {'page': page, 'limit': limit});
    return response.data!;
  }
}
```

### Adding New Features

1. Create a new feature folder under `lib/features/`
2. Add presentation layer (screens/widgets)
3. Add domain layer (entities, repositories interface)
4. Add data layer (models, repository implementations)
5. Register routes in `lib/app.dart`
6. Wire up BLoC providers in `lib/app.dart`

---

## API Integration

### Backend Sharing Strategy

Our existing Next.js application serves as the **single backend server** for both the Flutter mobile app and the web admin portal. This approach:

- ✅ Preserves all existing functionality
- ✅ Uses a single database (MongoDB)
- ✅ Requires minimal changes to existing code
- ✅ Enables rapid development

### API Endpoints Used by Flutter

| Endpoint | Method | Description | Access |
|----------|--------|-------------|--------|
| `/api/auth/login` | POST | User login | Public |
| `/api/auth/register` | POST | User registration | Public |
| `/api/reports` | GET | Fetch verified reports | Public* |
| `/api/reports` | POST | Create new report | User |
| `/api/reports/me` | GET | Get user's reports | User |
| `/api/notifications` | GET | Get notifications | User |
| `/api/sos/alert` | POST | Trigger SOS emergency | User |
| `/api/user/profile` | GET/PUT | Get/update profile | User |

> *Public: Verified reports only; unverified hidden from public API.

### CORS Configuration

For Flutter to call the Next.js API during development, ensure CORS is configured in `src/middleware.ts`:

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Allow Flutter app to make requests during development
  const allowedOrigins = [
    'http://localhost:3000',   // Next.js dev server
    'http://127.0.0.1:3000',
  ];

  const origin = request.headers.get('origin');
  if (origin && allowedOrigins.includes(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin);
  }

  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  return response;
}

export const config = {
  matcher: '/api/:path*',
};
```

---

## Design System

### Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| **Primary Green** | `#006400` | Buttons, active states, headers, FAB |
| **Success Green** | `#2E7D32` | Cards, positive indicators |
| **Alert Red** | `#DC143C` | SOS button, emergency, crime type badges |
| **Warning Yellow** | `#FFD700` | Safety alerts, medium risk |
| **Background White** | `#FFFFFF` | Main backgrounds |
| **Surface Light** | `#F5F5F5` | Card backgrounds, input fields |
| **Text Primary** | `#1A1A1A` | Headings, body text |
| **Text Secondary** | `#757575` | Subtitles, placeholders |

### Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| Submitted | Blue | `#1976D2` |
| Under Review | Amber/Yellow | `#FFA000` |
| Verified | Green | `#388E3C` |
| Dismissed | Red | `#D32F2F` |

### Typography Hierarchy

```
H1 (Screen Titles):     24px, SemiBold
H2 (Section Headers):   20px, Medium
H3 (Card Titles):       18px, Medium
Body:                   16px, Regular
Caption/Label:          14px, Regular
Small Text:             12px, Regular
```

---

## Screens & User Flow

### Phase A: First-Time User Onboarding

```
Splashscreen (2-3s brand intro)
       ↓
Onboarding Carousel (3 swipable screens, skip available)
   ├─ "Report Crimes In Real-time"
   ├─ "Get Safe Routes and Alerts"
   └─ "Stay Together Safer Together"
       ↓
Login OR RegisterScreen
   ├─ Login → HomeDashboard (returning user)
   └─ Register → Login → HomeDashboard (new user)
```

### Phase B: Core App Navigation (Bottom Bar — 5 Tabs)

```
HomeDashboard ←→ CrimeMap ←→ [FAB] Reporting Wizard ←→ Notifications ←→ Profile
     (1)           (2)              (3)                    (4)            (5)
```

**Tab Breakdown:**

| Tab | Screen | Purpose |
|-----|--------|---------|
| ① Home | HomeDashboard | Central hub — safety score, quick actions, recent alerts |
| ② Map | CrimeMap | Interactive heatmap with filterable crime markers + safe places overlay |
| ③ FAB (Center) | Reporting Wizard / SOS | Two modes: Report Crime OR Emergency SOS |
| ④ Alerts | Notifications | Categorized notification feed |
| ⑤ Profile | Profile | User settings, report history, safety insights |

### Phase C: Crime Reporting Wizard (Multi-Step Flow)

```
[Triggered from HomeDashboard "Report Crime" or FAB]
       ↓
┌─────────────────────────────────────────────┐
│ Step 1: Select Crime Type                   │
│   • Armed Robbery, Theft, Assault           │
│   • Vandalism, Cyber Crime                  │
│   • Suspicious Activity, Others             │
│   → Each with colored icon + letter badge   │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 2: Select Location                     │
│   • Interactive map with pin drop           │
│   • "Use Current Location" button           │
│   → Auto-fills address                      │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 3: Incident Description                │
│   • Main description (500 char limit)       │
│   • Additional details (optional)           │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 4: Witness Information                 │
│   • Name, Phone (both optional)             │
│   • "Add Another Witness" button            │
│   → Can skip entirely                       │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 5: Suspect Information                 │
│   • Physical description (optional)         │
│   • Vehicle info (optional)                 │
│   → Can skip entirely                       │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 6: Evidence Collection                 │
│   • Upload Photos (up to 6)                 │
│   • Record Audio (waveform UI)              │
│   • Upload Video                            │
│   → All optional, can skip                  │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 7: Preview Report                      │
│   • Review all entered data                 │
│   • Edit any section                        │
│   • Submit button                           │
└───────────────────┬─────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Step 8: Report Submitted ✅                  │
│   • Success message                         │
│   • Report ID: #SR2387                      │
│   • "Back to Home" CTA                      │
└─────────────────────────────────────────────┘
```

### Phase D: Emergency Flow (SOS)

```
[Triggered from FAB or SOS Quick Action]
       ↓
┌─────────────────────────────────────────────┐
│ SOS Screen                                  │
│   • Large pulsing red button                │
│   • "Tap to send alert"                     │
│   • Location sharing notice                 │
└───────────────────┬─────────────────────────┘
                    ↓ (user taps)
┌─────────────────────────────────────────────┐
│ Live Emergency Screen                       │
│   • "Help is on the way!"                   │
│   • Map with live location sharing          │
│   • Emergency Team ETA display              │
│   • Cancel/Extend timer options             │
└─────────────────────────────────────────────┘
```

---

## Admin Portal

### Overview

The admin portal is built into the existing Next.js application at `/admin/*` routes. It provides security agencies with tools to:

- Monitor and verify crime reports
- Manage users and assign roles
- Generate analytics and export reports
- Track emergency SOS dispatches
- Configure system settings

### Admin Screens (Already Built)

| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/admin` | Overview stats, recent activity, quick actions |
| Report Review List | `/admin/reports` | Paginated table with status filters and search |
| User Management | `/admin/users` | User list, profile details, ban/suspend controls |
| Audit Logs | `/admin/logs` | Admin action history viewer |
| System Settings | `/admin/settings` | Configuration for distance threshold, decay days, crowd threshold |

### Analytics Charts (Already Built)

- Crime type distribution (pie/donut chart)
- Temporal trends (line charts: daily/weekly/monthly)
- Risk level distribution (bar chart)
- Status distribution (stacked bar chart)

All charts use **Recharts** and connect to existing API endpoints.

### Admin Development Phases

| Phase | Description | Status |
|-------|-------------|--------|
| A: Foundation | Setup, routing, layout shell, auth guard | ✅ Complete |
| B: Dashboard & Reports | Overview stats, report review list | ✅ Complete |
| C: User Management | User list, profile details, ban/suspend | ✅ Complete |
| D: Analytics | Charts for crime types, trends, hotspots | ✅ Complete |
| E: Export | CSV export of reports | ✅ Complete |

---

## Roadmap

### Current Status

- ✅ **Core infrastructure** — Colors, routes, theme, widgets, API service
- ✅ **Auth screens** — Splash, onboarding, login, register (UI done)
- ✅ **Home dashboard** — Safety score card, quick actions, recent alerts (UI done)
- ✅ **Reporting wizard** — Multi-step flow UI (UI done)
- ✅ **Emergency features** — SOS screen + live tracking (UI done)
- 🟡 **Map/notifications/profile** — Skeleton screens only
- 🟡 **API integration** — Auth, reports, notifications need real API calls

### Next Steps (Priority Order)

1. **Fix nested Scaffold bug** ✅ (Completed — `home_page.dart` fixed)
2. **Connect auth to real API** — Login/register BLoC → Next.js endpoints
3. **Enhance home dashboard** — Match design exactly with circular gauge + gradient card
4. **Complete reporting wizard** — Full flow to API submission
5. **Implement map** — Google Maps with crime markers and filters
6. **Build notifications screen** — Real data display from API
7. **Profile & Settings** — Complete user management screens
8. **Polish & animations** — Transitions, loading states

### Future Enhancements

- [ ] Push notifications (FCM integration)
- [ ] Offline support with Hive caching
- [ ] Dark mode toggle
- [ ] Accessibility improvements
- [ ] Unit tests for BLoC + services
- [ ] Widget tests for key screens
- [ ] Integration tests for critical flows
- [ ] Production deployment (Vercel + App Store/Play Store)

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License — see the LICENSE file for details.

---

*Sentinel NG — Safer Communities, Together*  
*Built with Flutter + Next.js + MongoDB*  
*Architecture: Clean Architecture with BLoC state management*
