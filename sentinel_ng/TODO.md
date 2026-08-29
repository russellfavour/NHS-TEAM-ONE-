# 🛡️ Sentinel NG — Complete Implementation Plan & TODO

> **Tech Stack**: Flutter (Mobile App) · Next.js 16 + React 19 (Admin Web Portal) · Node.js API Routes · MongoDB (Prisma ORM)
> **Purpose**: Production-ready crime reporting platform for Nigerian communities. Competition-ready, full TOR compliance.
>
> **Architecture Decision**: Hybrid approach — existing Next.js app serves as the single backend server. Flutter mobile app calls the same API routes. Existing `src/app/admin/` pages serve as the admin portal (no need to rebuild from scratch).

---

## 📋 Table of Contents

1. [Current State Assessment](#1-current-state-assessment)
2. [Backend Changes — Next.js Project](#2-backend-changes--nextjs-project)
3. [New API Routes to Implement](#3-new-api-routes-to-implement)
4. [Prisma Schema Extensions](#4-prisma-schema-extensions)
5. [Flutter App Implementation Phases](#5-flutter-app-implementation-phases)
6. [Admin Portal — Reuse Existing Next.js Pages](#6-admin-portal--reuse-existing-nextjs-pages)
7. [Integration & Testing](#7-integration--testing)
8. [Competition Prep](#8-competition-prep)

---

## 1. Current State Assessment

### ✅ What Already Exists (Next.js Project: `crime-location-reporting-system`)

| Component | Status | Details |
|-----------|--------|---------|
| **Frontend** | ✅ Working | Next.js 16 App Router + React 19 + Tailwind CSS 4 |
| **Backend API** | ✅ Working | Server Routes in `src/app/api/` (26 routes) |
| **Database ORM** | ✅ Working | Prisma Client v6 with MongoDB |
| **Authentication** | ✅ Working | NextAuth v5 (Google OAuth + Credentials, JWT strategy) |
| **File Storage** | ✅ Configured | Cloudinary integration |
| **Rate Limiting** | ✅ Configured | `@upstash/ratelimit` (Redis-backed) |
| **Logging** | ✅ Configured | Pino logger |

### Existing API Routes (26 — Already Built, No Changes Needed)

#### Authentication (`/api/auth/*`)
- `POST /api/auth/register` — User registration with password hashing
- `GET/POST /api/auth/[...nextauth]` — NextAuth session management, OAuth callbacks
- `POST /api/auth/forgot-password` — Password reset token generation
- `POST /api/auth/reset-password/[token]` — Reset password with token validation
- `POST /api/auth/verify-email/send` — Resend email verification
- `GET /api/auth/verify-email/[token]` — Verify email address

#### Reports (`/api/reports/*`)
- `POST /api/reports` — Create new crime report (with similarity engine)
- `GET /api/reports` — Fetch verified reports + community alerts (paginated, filterable, geo-search)
- `GET /api/reports/[id]` — Get single report detail
- `GET /api/reports/me` — Get current user's submitted reports

#### Admin (`/api/admin/*`)
- `GET /api/admin/reports` — Admin report list with filters (status, riskLevel, type, search)
- `POST /api/admin/reports/bulk` — Bulk operations on reports
- `GET /api/admin/users` — User management list
- `GET /api/admin/logs` — Admin action audit log
- `GET/PUT /api/admin/settings` — System settings (distance threshold, decay days, crowd threshold)
- `GET /api/admin/export` — CSV export of reports with filters

#### Notifications (`/api/notifications/*`)
- `GET/POST /api/notifications` — User notifications list + create
- `PUT /api/notifications/[id]` — Mark notification as read
- `POST /api/notifications/read-all` — Bulk mark all as read
- `GET/PUT /api/notifications/preferences` — Notification preferences

#### SOS (`/api/sos/*`)
- `POST /api/sos/alert` — Send emergency SOS emails to contacts via GikpsMail

#### User (`/api/user/*`)
- `GET/PUT /api/user/profile` — Get/update user profile
- `GET/DELETE /api/user/account` — Account info + delete account
- `POST /api/user/change-password` — Change password

#### SOS Contacts (`/api/sos-contacts/*`)
- `GET/POST /api/sos-contacts` — List/add emergency contacts
- `PUT/DELETE /api/sos-contacts/[id]` — Update/delete contact

### Existing Admin Pages (Already Built in Next.js)
- `src/app/admin/page.tsx` — Dashboard with stats cards
- `src/app/admin/reports/page.tsx` — Report review list with filters
- `src/app/admin/users/page.tsx` — User management
- `src/app/admin/logs/page.tsx` — Audit log viewer
- `src/app/admin/settings/page.tsx` — System settings
- `src/components/admin/charts/` — CrimeTypeChart, ReportTrendsChart, RiskLevelChart, StatusDistributionChart (Recharts)

### Existing Prisma Models (8)
```
User ──┬── Report          (reporterId → User.id)
       ├── AdminLog        (adminId → User.id, reportId → Report.id)
       ├── Notification    (userId → User.id)
       ├── SosEmergencyContact (userId → User.id)
       ├── NotificationPreference (userId → User.id)
       ├── Account         (NextAuth OAuth accounts)
       └── Session         (NextAuth sessions)

PasswordResetToken  (standalone, userId → User.id)
EmailVerificationToken (standalone, userId → User.id)
SystemSetting       (standalone key-value pairs)
```

### Key Features Already Implemented
- ✅ Similarity Engine — Detects duplicate reports within configurable distance/time thresholds
- ✅ Community Alert Clustering — Groups nearby pending reports into crowd alerts
- ✅ Data Decay — Verified reports older than N days hidden from public view
- ✅ Geo-spatial Queries — Haversine distance calculations for proximity search
- ✅ Rate Limiting — Per-IP rate limits on auth and report submission
- ✅ Admin Audit Logging — Every admin action logged with timestamp and reason
- ✅ CSV Export — Filterable export of reports to CSV file download
- ✅ System Settings — Dynamic configuration stored in DB

### ❌ What Is Missing (Needs Implementation)

| Area | Gap | Priority |
|------|-----|----------|
| **Prisma Schema** | Missing `SosAlert`, `BroadcastAlert` models; Report model missing witness/suspect/verification fields | High |
| **API Routes** | No broadcast alerts endpoint, no analytics aggregation endpoint, no SOS dispatch tracking endpoint | High |
| **CORS/Auth** | NextAuth only supports cookie-based auth (browser); Flutter needs Bearer token support | Medium |
| **Flutter App** | Entire mobile app not yet built — all screens, features, API client | High |
| **Admin Portal** | Existing pages need enhancement: risk tagging UI, SOS dispatch board, broadcast panel, analytics aggregation endpoint | Medium |

---

## 2. Backend Changes — Next.js Project

> **Location**: `/home/angelis/NodeProjects/crime-location-reporting-system` (or wherever your existing project lives)
> **Goal**: Extend the existing backend to support Flutter mobile app + admin portal enhancements. Zero risk to current functionality.

### Step 2.1: CORS Middleware

**Create file**: `src/middleware.ts`

```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Allow Flutter app to make requests during development
  const allowedOrigins = [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    // Add your Flutter app's origin if hosted separately
  ];

  const origin = request.headers.get('origin');
  if (origin && allowedOrigins.includes(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin);
  }

  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.headers.set('Access-Control-Allow-Credentials', 'true');

  return response;
}

export const config = {
  matcher: '/api/:path*',
};
```

### Step 2.2: Auth Token Handling (Bearer + Cookie)

**Modify file**: `src/auth.ts` — Add Bearer token support alongside cookie-based auth for Flutter requests.

```typescript
// In your existing NextAuth config, add this helper:
import { NextRequest } from 'next/server';

export async function auth(request?: NextRequest) {
  // Try cookie-based auth first (browser requests)
  const session = await _auth();
  
  if (session?.user) return session;

  // If no cookie, try Bearer token (Flutter/mobile requests)
  if (request) {
    const authHeader = request.headers.get('authorization');
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.slice(7);
      return await _auth({ 
        req: request,
        cookies: new Map([['next-auth.session.token', token]])
      });
    }
  }

  return null;
}
```

### Step 2.3: Run Prisma Migration (After Schema Changes — See Section 4)

```bash
npx prisma migrate dev --name add_flutter_features
npx prisma generate
```

---

## 3. New API Routes to Implement

These are the **new endpoints** that don't exist yet and must be created for Flutter + admin portal enhancements.

### 3.1 Broadcast Alerts (`/api/admin/broadcast`)

**Create file**: `src/app/api/admin/broadcast/route.ts`

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/api/admin/broadcast` | Create & send broadcast notification to users | Admin |
| GET | `/api/admin/broadcast` | List all broadcasts | Admin |
| PUT | `/api/admin/broadcast/[id]/deactivate` | Deactivate a broadcast | Admin |

**Request Body (POST)**:
```json
{
  "title": "Safety Alert",
  "message": "Avoid the area around...",
  "targetAudience": "all" | "region" | "verified_users",
  "priority": "low" | "medium" | "high" | "critical",
  "regionFilter": { "type": "Point", "coordinates": [lng, lat], "radiusKm": 5 } // optional
}
```

**Implementation**:
- Validate admin role via `auth()` from NextAuth
- Create broadcast in Prisma (`BroadcastAlert` model)
- Trigger FCM push notification to targeted users (integrate with existing notification system)
- Return created broadcast object

### 3.2 Analytics Aggregation (`/api/admin/analytics`)

**Create file**: `src/app/api/admin/analytics/route.ts`

| Method | Endpoint | Description | Query Params | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/analytics` | Full analytics aggregation | `?period=daily\|weekly\|monthly&dateFrom=&dateTo=` | `{ overview, byType, byRiskLevel, byStatus, temporalTrends }` |

**Response Structure**:
```json
{
  "overview": {
    "totalReports": 1247,
    "verifiedCount": 892,
    "pendingCount": 355,
    "highRiskCount": 120
  },
  "byType": [
    { "type": "armed_robbery", "count": 398 },
    { "type": "theft", "count": 349 }
  ],
  "byRiskLevel": [
    { "level": "high", "count": 120 },
    { "level": "medium", "count": 500 },
    { "level": "low", "count": 627 }
  ],
  "byStatus": [
    { "status": "VERIFIED", "count": 892 },
    { "status": "PENDING", "count": 355 }
  ],
  "temporalTrends": [
    { "period": "2024-01-01", "count": 45 },
    { "period": "2024-01-02", "count": 52 }
  ]
}
```

**Implementation**:
- Validate admin role via `auth()` from NextAuth
- Fetch reports in date range using Prisma
- Aggregate server-side: by type, risk level, status, temporal trends
- Return aggregated JSON (no need for client-side aggregation)

### 3.3 SOS Dispatch Tracking (`/api/admin/dispatch`)

**Create file**: `src/app/api/admin/dispatch/route.ts`

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/admin/dispatch/active` | List all active SOS alerts with reporter location | Admin |
| PUT | `/api/admin/dispatch/[id]/acknowledge` | Acknowledge an SOS alert (assign responder) | Admin |
| PUT | `/api/admin/dispatch/[id]/update-status` | Update SOS status: en_route → on_scene → resolved | Admin |

**Response Structure (GET)**:
```json
{
  "alerts": [
    {
      "sosAlertId": "SOS-2024-001",
      "reporterName": "John D.",
      "status": "triggered",
      "location": { "type": "Point", "coordinates": [3.3911, 6.5244] },
      "address": "Ikeja, Lagos",
      "createdAt": "2024-01-15T14:30:00Z"
    }
  ]
}
```

**Implementation**:
- Validate admin role via `auth()` from NextAuth
- Query `SosAlert` model for active alerts (status in triggered/acknowledged/en_route)
- Include reporter info and location data
- For acknowledge/update-status: update SosAlert status, set timestamps

### 3.4 Report Verification Endpoints (Enhance Existing Admin Routes)

**Modify file**: `src/app/api/admin/reports/[id]/route.ts` or create new route files.

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| PUT | `/api/admin/reports/[id]/verify` | Approve a report (set status=verified) | `{ adminNotes?: string }` | `{ success, report }` |
| PUT | `/api/admin/reports/[id]/dismiss` | Reject a report (set status=dismissed) | `{ reason: string, adminNotes?: string }` | `{ success, report }` |
| PUT | `/api/admin/reports/[id]/review-start` | Mark as under_review | `{}` | `{ success, report }` |
| PUT | `/api/admin/reports/[id]/risk-level` | Assign risk level (high/medium/low) | `{ riskLevel: 'high'\|'medium'\|'low', reason?: string }` | `{ success, report }` |

**Implementation**:
- Validate admin role via `auth()` from NextAuth
- Update Report status/riskLevel in Prisma
- Add entry to verificationHistory array (with performedBy, timestamp, notes)
- Create notification for the reporter about status change
- Log action in AdminLog model (audit trail)

### 3.5 User Management Endpoints (Enhance Existing Admin Routes)

**Modify file**: `src/app/api/admin/users/[id]/route.ts` or create new route files.

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| PUT | `/api/admin/users/[id]/ban` | Suspend a user account | `{ reason: string }` | `{ success, user }` |
| PUT | `/api/admin/users/[id]/unban` | Reactivate a banned user | `{}` | `{ success, user }` |

**Implementation**:
- Validate admin role via `auth()` from NextAuth
- Update User.isBanned flag in Prisma
- Create notification for the user about ban/unban action
- Log action in AdminLog model (audit trail)

---

## 4. Prisma Schema Extensions

Add these to your existing `prisma/schema.prisma` file. These are **non-breaking** — all new fields are optional, and new tables don't affect existing data.

### 4.1 New Models: SosAlert & BroadcastAlert

```prisma
model SosAlert {
  id            String           @id @default(auto()) @map("_id") @db.ObjectId
  sosAlertId    String           @unique // e.g., "SOS-2024-001"
  reporter      User             @relation(fields: [reporterId], references: [id])
  reporterId    String           @db.ObjectId
  
  status        SosAlertStatus   @default(TRIGGERED)
  
  location      Json // GeoJSON Point { type: "Point", coordinates: [lng, lat] }
  address       String?
  
  assignedTo    User?            @relation("SOSResponder", fields: [assignedResponderId], references: [id])
  assignedResponderId String?    @db.ObjectId
  
  acknowledgedAt DateTime?
  enRouteAt     DateTime?
  onSceneAt     DateTime?
  resolvedAt    DateTime?
  
  createdAt     DateTime         @default(now())
  updatedAt     DateTime         @updatedAt
}

enum SosAlertStatus {
  TRIGGERED
  ACKNOWLEDGED
  EN_ROUTE
  ON_SCENE
  RESOLVED
}

model BroadcastAlert {
  id             String           @id @default(auto()) @map("_id") @db.ObjectId
  title          String
  message        String
  targetAudience String           @default("all") // "all", "region", "verified_users"
  regionFilter   Json?            // GeoJSON polygon or radius
  priority       BroadcastPriority @default(MEDIUM)
  isActive       Boolean          @default(true)
  sentAt         DateTime?        // When broadcast was pushed via FCM
  deliveredCount Int              @default(0)
  createdBy      User             @relation(fields: [createdById], references: [id])
  createdById    String           @db.ObjectId
  
  createdAt      DateTime         @default(now())
}

enum BroadcastPriority {
  LOW
  MEDIUM
  HIGH
  CRITICAL
}
```

### 4.2 Enhanced Report Model Fields

Add these optional fields to your existing `Report` model:

```prisma
model Report {
  // ... existing fields ...

  // NEW: Verification history (audit trail)
  verificationHistory Json? @default("[]") // Array of { action, performedBy, timestamp, notes }

  // NEW: Witness information
  witnesses Json? @default("[]") // Array of { name, phone, statement }

  // NEW: Suspect information
  suspectInfo Json? @default("{}") // Object with { description, vehicleInfo, numberOfSuspects }

  // NEW: Risk level (if not already present)
  riskLevel String? @default("pending") // "high", "medium", "low", "pending"

  // NEW: Anonymous reporting flag
  isAnonymous Boolean @default(false)

  // NEW: Evidence array (if not already a separate model)
  evidence Json? @default("[]") // Array of { type, url, uploadedAt }
}
```

### 4.3 Run Migration

```bash
npx prisma migrate dev --name add_flutter_features
npx prisma generate
```

---

## 5. Flutter App Implementation Phases

> **Location**: New Flutter project (or existing `sentinel_ng` directory)
> **Architecture**: Clean Architecture with BLoC state management
> **State Management**: `flutter_bloc` + `equatable`
> **HTTP Client**: `dio` with interceptors for auth tokens
> **Dependency Injection**: `get_it` + `injectable`

### Phase 5.1: Foundation (Days 1–2)

- [ ] Create Flutter project with Clean Architecture skeleton (`lib/core/`, `lib/data/`, `lib/features/`)
- [ ] Configure theme, typography, reusable widgets
- [ ] Set up routing with `go_router`
- [ ] Install dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dio: ^5.4.0
  get_it: ^7.6.7
  injectable: ^2.3.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  google_maps_flutter: ^2.5.3
  geolocator: ^11.0.0
  image_picker: ^1.0.7
  video_player: ^2.8.2
  record: ^5.0.4
  go_router: ^13.2.0
  flutter_animate: ^4.5.0
  fl_chart: ^0.66.2
  firebase_messaging: ^14.7.10
  flutter_dotenv: ^5.1.0
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  build_runner: ^2.4.8
  injectable_generator: ^2.4.1
  hive_generator: ^2.0.1
```

- [ ] Create `core/constants/colors.dart` — Primary green (#006400), red, white palette
- [ ] Create `core/constants/strings.dart` — App-wide text constants
- [ ] Create `core/constants/routes.dart` — Route names
- [ ] Create `core/theme/app_theme.dart` — Light/dark theme definitions
- [ ] Create `core/utils/validators.dart` — Form validation helpers
- [ ] Create `core/widgets/custom_button.dart` — Reusable green CTA button
- [ ] Create `core/widgets/custom_textfield.dart` — Styled text input with label + error state
- [ ] Create `core/widgets/loading_indicator.dart` — Circular progress widget
- [ ] Create `data/services/api_client.dart` — Dio client with auth interceptor + secure storage

### Phase 5.2: Auth Feature (Days 3–4)

Screens: Splash → Onboarding (3 pages) → Login → Register

- [ ] **Splash Screen** (`features/auth/presentation/splash/`)
  - App branding + loading indicator (2-3s brand intro)
  - Check if user is logged in; navigate to HomeDashboard or Onboarding
  
- [ ] **Onboarding Screens** (`features/auth/presentation/onboarding/`)
  - 3 swipable screens with skip button:
    - "Report Crimes In Real-time"
    - "Get Safe Routes and Alerts"
    - "Stay Together Safer Together"
  - Save `hasSeenOnboarding` to SharedPreferences
  
- [ ] **Login Screen** (`features/auth/presentation/login/`)
  - Email/password form + Google & Apple OAuth buttons
  - Call existing `/api/auth/[...nextauth]` endpoint (credentials login)
  - Store JWT token in `FlutterSecureStorage` after successful login
  - Navigate to HomeDashboard on success
  
- [ ] **Register Screen** (`features/auth/presentation/register/`)
  - Full name, phone, email, password with confirmation
  - Call existing `/api/auth/register` endpoint
  - Navigate to Login screen after registration

### Phase 5.3: Core Features (Days 5–7)

Screens: HomeDashboard, CrimeMap, SOS, Notifications, Profile + Bottom Navigation

- [ ] **Bottom Navigation Bar** (`core/widgets/bottom_nav_bar.dart`)
  - 5 tabs: Home | Map | FAB (Report/SOS) | Alerts | Profile
  
- [ ] **Home Dashboard** (`features/home/presentation/`)
  - Safety score card with circular gauge
  - Quick actions grid (Report Crime, Safe Route, SOS)
  - Recent alerts list
  - Call `/api/reports` for recent verified reports

- [ ] **Crime Map** (`features/map/presentation/crime_map_screen.dart`)
  - Interactive Google Maps with markers + filters
  - Filter tabs: All / Robbery / Theft / Assault
  - Heat zone visualization
  - Safe place markers overlay (police stations, hospitals)
  - Call `/api/reports` with geo-search params

- [ ] **SOS Screen** (`features/emergency/presentation/sos_screen.dart`)
  - Large pulsing red button animation
  - "Tap to send alert" text
  - Location sharing notice
  - On tap: call `/api/sos/alert` + navigate to LiveEmergency screen

- [ ] **Live Emergency Screen** (`features/emergency/presentation/live_emergency_screen.dart`)
  - "Help is on the way!" message
  - Map with live location sharing
  - Emergency Team ETA display (placeholder until SOS dispatch backend is built)
  - Cancel/Extend timer options

- [ ] **Notifications Screen** (`features/notifications/presentation/`)
  - Categorized alert list: All / Alerts / Updates / System
  - Mark as read functionality
  - Call `/api/notifications` endpoints

- [ ] **Profile Screen** (`features/profile/presentation/`)
  - User info display, settings entry points
  - Report count badge
  - Safety score link
  - Emergency contacts management
  - Settings (app preferences, privacy)

### Phase 5.4: Reporting Wizard (Days 8–10)

This is the **heart of your application**. Multi-step guided conversation flow.

- [ ] **Wizard Orchestrator** (`features/reporting/presentation/crime_report_wizard.dart`)
  - Multi-step wizard controller with progress indicator
  - State management for form data across steps
  
- [ ] **Step 1: Select Crime Type** (`features/reporting/presentation/select_crime_type_screen.dart`)
  - Grid of crime types with colored icons + letter badges:
    - Armed Robbery, Theft, Assault, Vandalism, Cyber Crime, Suspicious Activity, Others
  - Store selected type in wizard state

- [ ] **Step 2: Select Location** (`features/reporting/presentation/select_location_screen.dart`)
  - Interactive map with pin drop
  - "Use Current Location" button (geolocator)
  - Auto-fill address from coordinates (reverse geocoding)
  - Store coordinates + address in wizard state

- [ ] **Step 3: Incident Description** (`features/reporting/presentation/incident_description_screen.dart`)
  - Main description text field with character counter (500 max)
  - Additional details field (optional)
  - Store description in wizard state

- [ ] **Step 4: Witness Information** (`features/reporting/presentation/witness_information_screen.dart`)
  - Name, Phone fields (both optional)
  - Statement text area
  - "Add Another Witness" button for multi-witness support
  - Can skip entirely — store empty array if skipped

- [ ] **Step 5: Suspect Information** (`features/reporting/presentation/suspect_information_screen.dart`)
  - Physical description field (optional)
  - Vehicle info fields: make, model, color, plate number (optional)
  - Number of suspects input
  - Can skip entirely

- [ ] **Step 6: Evidence Collection** (`features/reporting/presentation/evidence_collection_screen.dart`)
  - Upload Photos (up to 6) via `image_picker` — camera + gallery access
  - Record Audio with waveform visualization via `record` package
  - Upload Video via `video_player` integration
  - All optional, can skip entirely

- [ ] **Step 7: Preview Report** (`features/reporting/presentation/preview_report_screen.dart`)
  - Review all entered data in sections
  - Edit any section (back-navigation)
  - Submit button

- [ ] **Step 8: Report Submitted Success** (`features/reporting/presentation/report_success_screen.dart`)
  - Success message with report ID (#SR2387 format)
  - "Back to Home" CTA button
  - Call `/api/reports` POST endpoint with all wizard data

### Phase 5.5: Additional Features (Days 11–12)

- [ ] **Crime Detail Screen** (`features/crime_details/presentation/`)
  - Full report view with evidence thumbnails (photo/video carousel)
  - Report status timeline visual tracker
  - Status badges: Submitted / Under Review / Verified / Dismissed
  
- [ ] **My Reports Status Screen** (`features/profile/presentation/my_reports_screen.dart`)
  - List of user's submitted reports from `/api/reports/me`
  - Status badges per report
  - Tap any report to see details

- [ ] **Report Status Timeline** (component in `crime_details/`)
  - Visual progress bar with stages: Submitted → Under Review → Verified/Dismissed
  - Timestamps for each stage transition
  - Admin notes display (if dismissed)
  - Risk level assigned display

- [ ] **Search Screen** (`features/search/presentation/`)
  - Location/crime type search with recent & popular searches
  - Call `/api/reports` with search params

- [ ] **Safety Score Detail Screen** (`features/profile/presentation/safety_score_detail_screen.dart`)
  - Detailed score breakdown with metrics: onlineActivity, communityParticipation, reportAccuracy, responseTime
  - Circular progress gauges for each metric

### Phase 5.6: API Client Implementation

Create `lib/services/api_client.dart` — Dio client that calls your existing Next.js API routes:

```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api'; // or production URL
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    // Auth interceptor — automatically attaches Bearer token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.delete(key: 'jwt_token');
          // Navigate to login screen
        }
        return handler.next(error);
      },
    ));
  }

  // --- Authentication ---
  Future<Map<String, dynamic>> login({required String email, required String password}) async { ... }
  
  // --- Reports (reuse existing /api/reports) ---
  Future<Map<String, dynamic>> getReports({...}) async => _dio.get('/reports', queryParameters: {...});
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async => _dio.post('/reports', data: reportData);
  Future<List<dynamic>> getMyReports() async => _dio.get('/reports/me');
  
  // --- Admin (reuse existing /api/admin/* + new endpoints) ---
  Future<List<dynamic>> getPendingReports({...}) async => _dio.get('/admin/reports', queryParameters: {...});
  Future<Map<String, dynamic>> verifyReport(String reportId) async => _dio.put('/admin/reports/$reportId/verify');
  Future<Map<String, dynamic>> dismissReport(String reportId, String reason) async => _dio.put('/admin/reports/$reportId/dismiss', data: {reason});
  Future<Map<String, dynamic>> assignRiskLevel(String reportId, String level) async => _dio.put('/admin/reports/$reportId/risk-level', data: {riskLevel: level});
  Future<Map<String, dynamic>> getAnalytics({...}) async => _dio.get('/admin/analytics', queryParameters: {...});
  Future<Map<String, dynamic>> createBroadcast(Map<String, dynamic> data) async => _dio.post('/admin/broadcast', data: data);
  Future<List<dynamic>> getActiveSOSAlerts() async => _dio.get('/admin/dispatch/active');
}
```

### Phase 5.7: Data Models

Create all data models in `lib/data/models/` — JSON ↔ Dart serialization for every API response:

- [ ] `user_model.dart` — User entity with safetyScore, emergencyContacts, role
- [ ] `crime_report_model.dart` — Report entity with verificationHistory, witnesses, suspectInfo, evidence, riskLevel
- [ ] `notification_model.dart` — Notification entity with type (alert/update/system), relatedReportId
- [ ] `evidence_model.dart` — Evidence entity with type (photo/video/audio), url
- [ ] `safety_score_model.dart` — SafetyScore entity with overall + breakdown metrics
- [ ] `sos_alert_model.dart` — SosAlert entity with status, location, assignedResponder
- [ ] `broadcast_alert_model.dart` — BroadcastAlert entity with targetAudience, priority

---

## 6. Admin Portal — Reuse Existing Next.js Pages

> **Location**: Your existing Next.js project (`src/app/admin/`)
> **Goal**: Enhance existing admin pages with new features from RECOMMENDATIONS.md and ADMIN-RECOMMENDATIONS.md. No need to rebuild from scratch.

### 6.1 Existing Admin Pages (Already Built — Verify They Work)

| Page | File | Status |
|------|------|--------|
| Dashboard | `src/app/admin/page.tsx` | ✅ Exists — verify stats cards work with new data |
| Report Review List | `src/app/admin/reports/page.tsx` | ✅ Exists — verify filters/search work |
| User Management | `src/app/admin/users/page.tsx` | ✅ Exists — verify user list works |
| Audit Logs | `src/app/admin/logs/page.tsx` | ✅ Exists — verify log viewer works |
| System Settings | `src/app/admin/settings/page.tsx` | ✅ Exists — verify settings CRUD works |

### 6.2 New Admin Pages to Create/Enhance

#### A1–A2: Admin Login & Session Management (Verify Existing)
- [ ] Verify existing NextAuth admin login flow works with Bearer token auth for Flutter
- [ ] Add session timeout warning component if not present

#### A3–A4: Dashboard Overview (Enhance Existing)
- [ ] Enhance `src/app/admin/page.tsx` to show new stats: active SOS alerts, broadcast count
- [ ] Add real-time counter widgets using polling or WebSocket for SOS alerts

#### A5–A9: Report Management & Verification (Enhance Existing)
- [ ] **ReportReviewList** (`src/app/admin/reports/page.tsx`) — Enhance with new filters: riskLevel, verificationStatus
- [ ] **ReportDetailReview** — Create detail view page at `src/app/admin/reports/[id]/page.tsx` showing full report data including evidence gallery, witness info, suspect details, location map
- [ ] **RiskTaggingPanel** — Add inline risk level assignment dropdown in ReportReviewList + modal for detailed tagging with reason notes
- [ ] **VerificationDecisionModal** — Create approve/reject dialog component at `src/components/admin/modals/VerificationModal.tsx` with mandatory reason field and internal notes
- [ ] **ReportHistoryTimeline** — Create timeline component showing report lifecycle: submitted → reviewed → verified/dismissed with admin actions

#### A10–A15: Analytics Dashboard (Enhance Existing Charts)
- [ ] **AnalyticsDashboard** (`src/app/admin/analytics/page.tsx`) — New page with tabbed views (Daily / Weekly / Monthly) using new `/api/admin/analytics` endpoint
- [ ] **CrimeTypeDistributionChart** — Enhance existing CrimeTypeChart to use new API data
- [ ] **TemporalTrendCharts** — Line charts for crimes per day/week/month with trend indicators
- [ ] **HotspotMap** — Interactive map highlighting top 10 crime hotspots (use existing Google Maps or Leaflet)
- [ ] **RiskLevelDistributionChart** — Bar chart showing high/medium/low risk distribution over time
- [ ] **VerificationEfficiencyMetrics** — Admin performance: avg review time, verification rate, dismissal rate

#### A16–A19: Emergency Dispatch & Response Management (NEW)
- [ ] **ActiveSOSAlerts** (`src/app/admin/dispatch/page.tsx`) — Real-time list of active SOS alerts with reporter location on mini-map. Poll `/api/admin/dispatch/active` every 30 seconds or use WebSocket.
- [ ] **SOSAlertDetail** — Full SOS detail view: live tracker, ETA calculation, responder assignment dropdown
- [ ] **ResponderAssignmentPanel** — Assign available responders to SOS alerts; view responder availability
- [ ] **DispatchStatusBoard** — Kanban-style board showing SOS alerts by status (Triggered → Acknowledged → En Route → On Scene → Resolved)

#### A20–A22: User Management (Enhance Existing)
- [ ] **UserManagementList** (`src/app/admin/users/page.tsx`) — Enhance with ban/unban buttons, search/filter improvements
- [ ] **UserProfileDetail** — Create user detail page at `src/app/admin/users/[id]/page.tsx` showing full profile + report history + safety score
- [ ] **BanSuspendPanel** — Add modal for suspending/banning users with required reason field

#### A23–A24: Content & Configuration Management (NEW)
- [ ] **CrimeClassificationManager** (`src/app/admin/crime-types/page.tsx`) — CRUD interface for crime type categories (add/edit/delete types). Uses existing SystemSetting model or create new CrimeType model.
- [ ] **BroadcastAlertPanel** (`src/app/admin/broadcast/page.tsx`) — Create and send push notifications to users: target audience, message, priority, geo-fencing. Calls `/api/admin/broadcast` endpoint.

#### A25–A26: Reports & Export (Enhance Existing)
- [ ] **ReportExportCenter** (`src/app/admin/export/page.tsx`) — Enhance existing CSV export with date range and filter options. Add PDF export option using `jspdf` or server-side generation.
- [ ] **PDFReportPreview** — Preview generated analytics report before download

#### A27: Admin Settings (Enhance Existing)
- [ ] **AdminSettings** (`src/app/admin/settings/page.tsx`) — Enhance with admin profile, password change, notification preferences, API key management

### 6.3 Admin Design System (Use Tailwind CSS Classes)

| Role | Hex | Tailwind Class | Usage |
|------|-----|----------------|-------|
| Sidebar Primary | `#1E293B` | `bg-slate-800` | Left navigation background |
| Sidebar Active | `#3B82F6` | `bg-blue-500` | Active menu item highlight |
| Content Background | `#F8FAFC` | `bg-slate-50` | Main content area background |
| Card Surface | `#FFFFFF` | `bg-white` | Dashboard cards, panels |
| Primary Accent | `#006400` | Custom class | Primary buttons, links |
| Success | `#10B981` | `bg-green-500` | Verified status, success actions |
| Warning | `#F59E0B` | `bg-amber-500` | Under review, medium risk |
| Danger | `#EF4444` | `bg-red-500` | Dismissed, high risk, SOS alerts |

### Status Badge Colors (Tailwind)

| Status | Color | Tailwind Class |
|--------|-------|----------------|
| Submitted | Blue | `text-blue-600 bg-blue-100` |
| Under Review | Amber/Yellow | `text-amber-600 bg-amber-100` |
| Verified | Green | `text-green-600 bg-green-100` |
| Dismissed | Red | `text-red-600 bg-red-100` |

### Risk Level Colors (Tailwind)

| Risk | Color | Tailwind Class | Usage |
|------|-------|----------------|-------|
| High | Red + Bold | `text-red-700 font-bold bg-red-100` | Urgent attention, top of list |
| Medium | Amber | `text-amber-600 bg-amber-100` | Standard review queue |
| Low | Green | `text-green-600 bg-green-100` | Routine processing |

### Admin Navigation Structure (Sidebar)

```
┌─────────────────────────────────────┐
│  🛡️ SENTINEL NG ADMIN               │ ← Logo + Brand
├─────────────────────────────────────┤
│                                     │
│  📊 DASHBOARD                       │ → src/app/admin/page.tsx
│                                     │
│  ─── REPORTS                        │
│  📋 All Reports                     │ → src/app/admin/reports/page.tsx
│  ⏳ Pending Review                  │ → Filtered view of above
│  🔍 Report Detail                   │ → src/app/admin/reports/[id]/page.tsx
│  ⚠️ Risk Tagging                    │ → Inline in report list + modal
│                                     │
│  ─── ANALYTICS                      │
│  📈 Overview                        │ → src/app/admin/analytics/page.tsx
│  🗺️ Hotspot Map                     │ → In analytics page or separate
│  📊 Crime Trends                    │ → Tab in analytics page
│  🏷️ Risk Distribution               │ → Chart in analytics page
│                                     │
│  ─── EMERGENCY DISPATCH             │
│  🚨 Active SOS Alerts               │ → src/app/admin/dispatch/page.tsx
│  👥 Responder Assignment            │ → In dispatch detail view
│  📋 Dispatch Board                  │ → Kanban in dispatch page
│                                     │
│  ─── USERS                          │
│  👤 User Management                 │ → src/app/admin/users/page.tsx
│                                     │
│  ─── CONTENT                        │
│  🏷️ Crime Categories                │ → src/app/admin/crime-types/page.tsx
│  🔔 Broadcast Alerts                │ → src/app/admin/broadcast/page.tsx
│                                     │
│  ─── EXPORTS                        │
│  📥 Report Export                   │ → src/app/admin/export/page.tsx
│                                     │
│  ⚙️ SETTINGS                        │ → src/app/admin/settings/page.tsx
├─────────────────────────────────────┤
│  👤 [Admin Name] ▼                  │ → User dropdown: Profile, Logout
└─────────────────────────────────────┘
```

---

## 7. Integration & Testing

### Step 7.1: Connect Flutter to Next.js Backend

- [ ] Ensure CORS middleware is working (Step 2.1)
- [ ] Test Bearer token auth from Flutter (Step 2.2)
- [ ] Verify all existing API routes work from Flutter (`/api/reports`, `/api/auth/*`, etc.)
- [ ] Verify new API routes work: `/api/admin/broadcast`, `/api/admin/analytics`, `/api/admin/dispatch`

### Step 7.2: End-to-End Testing Checklist

| Flow | Mobile (Flutter) | Admin (Next.js) | Status |
|------|------------------|-----------------|--------|
| User Registration & Login | ✅ Test register + login flow | — | ☐ |
| Submit Crime Report | ✅ Full wizard → POST /api/reports | — | ☐ |
| View Reports on Map | ✅ Fetch + display markers | — | ☐ |
| SOS Emergency Alert | ✅ Trigger SOS → POST /api/sos/alert | ✅ See alert in dispatch board | ☐ |
| Admin Review Report | — | ✅ View report detail, verify/dismiss | ☐ |
| Risk Tagging | — | ✅ Assign risk level via API | ☐ |
| Analytics Dashboard | — | ✅ View charts from /api/admin/analytics | ☐ |
| Broadcast Alert | — | ✅ Create broadcast → users receive notification | ☐ |
| User Ban/Unban | — | ✅ Suspend user account | ☐ |
| Report Export | — | ✅ Download CSV/PDF export | ☐ |

### Step 7.3: Error Handling & Edge Cases

- [ ] Test offline mode (Hive caching for critical data)
- [ ] Test invalid token handling (401 → redirect to login)
- [ ] Test network timeout scenarios with loading states
- [ ] Test form validation on all screens
- [ ] Test file upload limits (6 photos, video size constraints)

---

## 8. Competition Prep

### Phase 8.1: Seed Database with Demo Data

- [ ] Create seed script to populate MongoDB with realistic Nigerian crime data
- [ ] Include reports in Lagos areas: Ikeja, Victoria Island, Lekki, Surulere, Yaba
- [ ] Mix of statuses: verified, pending, dismissed
- [ ] Mix of risk levels: high, medium, low
- [ ] Add sample users (regular + admin)

### Phase 8.2: Demo Preparation

- [ ] **Report Flow Speed** — Ensure reporting wizard completes in under 60 seconds
- [ ] **Live SOS Demo** — Show real-time location sharing on secondary screen (mobile + admin)
- [ ] **Mock GPS** — Ability to simulate different locations for map demonstration
- [ ] **Error Scenarios** — Prepare graceful error states (no network, invalid input)
- [ ] **Admin Dashboard Walkthrough** — Verify all charts load, filters work, export generates

### Phase 8.3: Polish & Optimization

- [ ] Performance optimization (lazy loading, pagination, caching)
- [ ] Animation polish between wizard steps and screen transitions
- [ ] Accessibility check (contrast ratios, semantic labels, dynamic text sizing)
- [ ] Presentation rehearsal with full end-to-end flow

---

## 📦 Quick Reference: Flutter Packages Summary

| Purpose | Package | Version |
|---------|---------|---------|
| State Management | `flutter_bloc` + `equatable` | Industry standard for Clean Architecture |
| HTTP Client | `dio` | Interceptors, retry logic, multipart support |
| Dependency Injection | `get_it` + `injectable` | Compile-time DI generation |
| Local Storage | `hive` + `hive_flutter` | Fast NoSQL local database for offline |
| Maps | `google_maps_flutter` | Google Maps integration |
| Location | `geolocator` | GPS location services |
| Image Picker | `image_picker` | Camera + gallery access |
| Video Player | `video_player` | Evidence video playback |
| Audio Recording | `record` | Audio waveform recording |
| Routing | `go_router` | Declarative navigation with deep linking |
| Animations | `flutter_animate` or `lottie` | Smooth transitions between wizard steps |
| Charts (Safety Score) | `fl_chart` | Circular progress, bar charts |
| Push Notifications | `firebase_messaging` | FCM integration |
| Secure Storage | `flutter_secure_storage` | JWT token storage |
| Environment Config | `flutter_dotenv` | .env file support |

---

## 📦 Quick Reference: Admin Web Packages Summary (React + Tailwind CSS)

Your existing Next.js project already has most of these. Verify versions match:

| Purpose | Package | Note |
|---------|---------|------|
| Framework | `react@18` + `next@16` | Already installed |
| Styling | `tailwindcss@3` + `@headlessui/react` | Utility CSS + accessible components |
| State Management | `zustand` or React Context | Lightweight state management |
| Routing | `next/navigation` (App Router) | Already built-in |
| HTTP Client | `axios` or Next.js `fetch` | Request interceptors, error handling |
| Charts | `recharts` | Analytics dashboard charts — already installed! |
| Maps | `google-maps-react` or `@amap/amap-vue` | Interactive map for admin heatmap |
| Data Tables | `@tanstack/react-table` or custom | Paginated, filterable report tables |
| File Export | `jspdf` + `xlsx` | PDF and CSV report generation — CSV already works! |
| Icons | `lucide-react` or `@mdi/font` | Consistent icon system |

---

## 🎯 Key Differentiators for Competition Judges

1. **Multi-Step Reporting Wizard** — Guided, conversational experience with progress indication
2. **Safety Score System** — Gamified community engagement metric (unique selling point)
3. **Real-Time SOS + ETA Tracking** — Live emergency response capability
4. **AI Safety Route Planning** — Route optimization based on crime data heatmaps
5. **Evidence-Rich Reports** — Photos, video, audio recording directly in report flow
6. **Anonymous Reporting Option** — Privacy-first design encouraging participation
7. **Nigerian Context** — Localized for Nigerian cities (Lagos focus)
8. **Complete Admin Dashboard** — Full TOR compliance with verification workflow, risk tagging, analytics & reports, and emergency dispatch
9. **Dual-Platform Architecture** — Mobile app for citizens + Web portal for agencies

---

## 📊 Implementation Timeline Summary

| Phase | Days | Deliverable |
|-------|------|-------------|
| Backend Changes (CORS, Auth, New Routes) | 1–3 | Extended Next.js API ready for Flutter |
| Prisma Schema Extension + Migration | 1 | New models: SosAlert, BroadcastAlert; enhanced Report model |
| Admin Portal Enhancements | 4–7 | All new admin pages and components built/enhanced |
| Flutter Foundation (Phase 5.1) | 8–9 | Project skeleton, theme, reusable widgets, API client |
| Flutter Auth (Phase 5.2) | 10–11 | Splash → Onboarding → Login → Register screens |
| Flutter Core Features (Phase 5.3) | 12–14 | HomeDashboard, CrimeMap, SOS, Notifications, Profile |
| Flutter Reporting Wizard (Phase 5.4) | 15–17 | Full multi-step reporting flow with evidence collection |
| Flutter Additional Features (Phase 5.5) | 18–19 | Crime detail, My Reports, Search, Safety Score Detail |
| Integration & Testing (Phase 7) | 20–22 | End-to-end testing of all flows |
| Competition Prep (Phase 8) | 23–25 | Seed data, demo polish, presentation rehearsal |

**Total Estimated Timeline: ~25 Days**

---

*This TODO.md harmonizes RECOMMENDATIONS.md, ADMIN-RECOMMENDATIONS.md, BACKEND-SHARING-ANALYSIS.md, and the original README into a single actionable implementation guide.*
*Tech Stack: Flutter (Mobile) · Next.js 16 + React 19 (Admin Web) · Prisma ORM · MongoDB*
*Architecture Pattern: Clean Architecture with BLoC state management (Flutter) · App Router (Next.js)*
*Total Screens: 54 (30 mobile + 24 web admin)*
