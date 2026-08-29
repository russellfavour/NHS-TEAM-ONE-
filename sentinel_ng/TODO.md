# 🔗 Sentinel NG — Harmonized Implementation Plan & TODO

## Executive Summary

This document harmonizes features across both platforms into a single implementation roadmap:

- **Next.js Web Application** (`crime-location-reporting-system/`) — Already has admin portal, API routes, analytics charts, CSV export ✅
- **Flutter Mobile App** (`sentinel_ng/`) — Has UI scaffolding for all screens, needs API integration and enhancement 🟡

### Key Decision: Backend Sharing (Option 4)

Your existing Next.js application serves as the **single backend server**. The Flutter mobile app connects to it via HTTP. No duplication. No database split. One deployment.

---

## Current Status Overview

| Component | Status | Details |
|-----------|--------|---------|
| **Next.js API Routes** | ✅ Complete | 26 routes built (auth, reports, admin, notifications, SOS, user) |
| **Next.js Admin Portal** | ✅ Complete | Dashboard, report review, user management, analytics charts, CSV export |
| **Prisma Schema** | 🟡 Partial | Missing SosAlert & BroadcastAlert models |
| **Flutter Core Infrastructure** | ✅ Complete | Colors, routes, theme, widgets, API service skeleton |
| **Flutter Auth Screens** | 🟡 UI Done | Splash, onboarding, login, register — needs BLoC + API integration |
| **Flutter Home Dashboard** | ✅ Fixed | Nested Scaffold bug resolved — matches design exactly |
| **Flutter Reporting Wizard** | 🟡 UI Done | Multi-step flow complete — needs preview/submit with real API call |
| **Flutter Emergency Features** | 🟡 UI Done | SOS + live tracking screens — needs location sharing + API connection |
| **Flutter Map/Notifications/Profile** | 🔴 Skeleton Only | Basic layouts — need full implementation |

---

## Phase 1: Backend Integration (Next.js) ⏱️ ~3-5 Days

### 1.1 CORS Configuration ✅ (Already in BACKEND-SHARING-ANALYSIS.md)
- [ ] Add `src/middleware.ts` for Flutter requests
- [ ] Test CORS with Flutter app on Chrome

### 1.2 Auth Token Handling ⏱️ ~2 hours
- [ ] Modify NextAuth callbacks to support both cookie-based (browser) and Bearer token (Flutter) auth
- [ ] Ensure JWT tokens are returned in login/register responses for Flutter

```typescript
// In src/app/api/auth/login/route.ts or [...nextauth]/route.ts
export async function POST(req: NextRequest) {
  // ... existing login logic
  
  // Return token for Flutter (browser uses cookies via NextAuth)
  return NextResponse.json({ 
    success: true, 
    user: session.user,
    token: session.token  // ← Add this for Flutter
  });
}
```

### 1.3 Prisma Schema Extension ⏱️ ~1 hour
- [ ] Add `SosAlert` model to `prisma/schema.prisma`
- [ ] Add `BroadcastAlert` model to `prisma/schema.prisma`
- [ ] Run migration: `npx prisma migrate dev --name add_flutter_features`

```prisma
// Add these to your existing prisma/schema.prisma

model SosAlert {
  id            String           @id @default(auto()) @map("_id") @db.ObjectId
  sosAlertId    String           @unique // e.g., "SOS-2024-001"
  reporter      User             @relation(fields: [reporterId], references: [id])
  reporterId    String           @db.ObjectId
  
  status        SosAlertStatus   @default(TRIGGERED)
  
  location      Json // GeoJSON Point { type: "Point", coordinates: [lng, lat] }
  
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

### 1.4 New API Routes for Flutter ⏱️ ~2-3 days
- [ ] Create `/api/admin/analytics` — Analytics aggregation (GET)
- [ ] Create `/api/admin/broadcast` — Broadcast alerts (POST/GET)
- [ ] Create `/api/admin/dispatch/active` — SOS dispatch tracking (GET)

See `BACKEND-SHARING-ANALYSIS.md` for complete implementation code.

---

## Phase 2: Flutter API Integration ⏱️ ~5-7 Days

### 2.1 Auth BLoC + API Connection
- [ ] Update `lib/features/auth/bloc/auth_bloc.dart` to use real API calls
- [ ] Connect login/register to Next.js `/api/auth/login` and `/api/auth/register`
- [ ] Implement secure token storage with `flutter_secure_storage`

```dart
// In auth_bloc.dart
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
```

### 2.2 Reports API Integration
- [ ] Connect reporting wizard to `/api/reports` POST endpoint
- [ ] Implement evidence upload with multipart form data
- [ ] Handle success/error states in wizard screens

### 2.3 Notifications API Integration
- [ ] Connect notifications page to `/api/notifications` GET endpoint
- [ ] Implement mark-as-read functionality
- [ ] Add real-time updates (optional: WebSocket)

### 2.4 SOS API Integration
- [ ] Connect SOS screen to `/api/sos/alert` POST endpoint
- [ ] Implement live location sharing with `geolocator` package
- [ ] Update live emergency screen with real ETA data

---

## Phase 3: Flutter Screen Enhancement ⏱️ ~7-10 Days

### 3.1 Home Dashboard (✅ UI Done, Needs Polish)
- [x] Fix nested Scaffold bug ✅
- [ ] Add circular gauge animation for safety score
- [ ] Connect to real API data (safety score, recent alerts)
- [ ] Add pull-to-refresh functionality

### 3.2 Crime Map (🔴 Skeleton Only)
- [ ] Implement `google_maps_flutter` integration
- [ ] Add crime markers with color coding by risk level
- [ ] Implement filter bar (All, Robbery, Theft, Assault, Safe Places)
- [ ] Add safe place markers overlay (police stations, hospitals)
- [ ] Connect to `/api/reports` for heatmap data

### 3.3 Notifications (🔴 Skeleton Only)
- [x] Fix nested Scaffold bug ✅
- [ ] Connect to real API data
- [ ] Implement notification detail view
- [ ] Add mark-as-read functionality
- [ ] Add push notification handling (optional: Firebase)

### 3.4 Profile & Settings (🔴 Skeleton Only)
- [x] Fix nested Scaffold bug ✅
- [ ] Connect to `/api/user/profile` for user data
- [ ] Implement profile editing
- [ ] Build safety score detail page with breakdown metrics
- [ ] Implement emergency contacts management
- [ ] Add settings screen (notifications, privacy, about)

### 3.5 Reporting Wizard (✅ UI Done, Needs Completion)
- [x] Multi-step wizard orchestrator ✅
- [x] Crime type selection ✅
- [x] Location selection (skeleton) — needs map integration
- [x] Incident description ✅
- [x] Witness information ✅
- [x] Suspect information ✅
- [x] Evidence collection ✅
- [ ] Preview & submit with real API call
- [ ] Success screen with report ID

### 3.6 Additional Features (🔴 Skeleton Only)
- [ ] Search screen enhancement — connect to `/api/reports/search`
- [ ] Crime detail screen enhancement — show evidence gallery, status timeline
- [ ] Report status timeline — visual progress tracker
- [ ] Safe route planner — integrate with safety scoring algorithm

---

## Phase 4: Admin Portal Enhancement (Next.js) ⏱️ ~3-5 Days

### 4.1 SOS Dispatch Management
- [ ] Add ActiveSOSAlerts page to admin portal (`/admin/dispatch`)
- [ ] Implement real-time SOS alert updates with WebSocket
- [ ] Build ResponderAssignment panel for assigning responders
- [ ] Create DispatchStatusBoard (Kanban-style)

### 4.2 Broadcast Alert System
- [ ] Add BroadcastAlertPanel to admin portal (`/admin/broadcast`)
- [ ] Implement create/send broadcast notifications
- [ ] Add target audience selection (all, region, verified_users)
- [ ] Integrate with FCM for push notifications

### 4.3 Analytics Dashboard Enhancement
- [ ] Add HotspotMap view with intensity circles (Leaflet + Recharts)
- [ ] Implement RiskLevelDistribution chart over time
- [ ] Add VerificationEfficiencyMetrics for admin performance
- [ ] Build PDF report generation endpoint (`/api/admin/reports/export/pdf`)

### 4.4 User Management Enhancement
- [ ] Add UserProfileDetail page with full history view
- [ ] Implement BanSuspendPanel with reason field + notification
- [ ] Add user safety score display in profile detail

---

## Phase 5: Polish & Testing ⏱️ ~3-5 Days

### 5.1 Flutter Polish
- [ ] Add loading states to all screens
- [ ] Implement error handling UI (network errors, API errors)
- [ ] Add smooth transitions between wizard steps
- [ ] Test on Android emulator and physical device
- [ ] Optimize performance (lazy loading, caching)

### 5.2 Admin Portal Polish
- [ ] Add keyboard shortcuts (`Ctrl+K` for search, `Esc` to close modals)
- [ ] Implement toast notifications for all actions
- [ ] Add undo last action functionality
- [ ] Test responsive design on different screen sizes

### 5.3 Testing
- [ ] Unit tests for BLoC + services (Flutter)
- [ ] Widget tests for key screens (Flutter)
- [ ] Integration tests for critical flows (Flutter → Next.js API)
- [ ] End-to-end testing of all admin features (Next.js)

---

## Phase 6: Competition Prep ⏱️ ~2-3 Days

### 6.1 Demo Data
- [ ] Seed MongoDB with realistic Nigerian crime data
- [ ] Create sample users (admin + regular users)
- [ ] Pre-populate reports with various statuses and risk levels

### 6.2 Presentation Rehearsal
- [ ] Prepare demo script covering:
  - User onboarding → login → home dashboard
  - Crime reporting wizard flow
  - SOS emergency trigger → admin dispatch board
  - Admin report verification workflow
  - Analytics dashboard with charts
- [ ] Practice transitions between mobile and admin views
- [ ] Prepare backup screenshots in case of demo issues

---

## Priority Order Summary

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| **P0** | Fix nested Scaffold bug ✅ | 1 hour | Critical — app was blank |
| **P0** | Connect auth to real API | 2 hours | Critical — login/register must work |
| **P1** | Complete reporting wizard (API submit) | 3 days | High — core feature |
| **P1** | Implement crime map with markers | 3 days | High — visual impact for demo |
| **P2** | Enhance home dashboard with real data | 2 days | Medium — first impression |
| **P2** | Build notifications screen (real data) | 2 days | Medium — user engagement |
| **P3** | Profile & settings completion | 2 days | Low — nice to have |
| **P3** | Admin SOS dispatch board | 3 days | High — competition differentiator |
| **P4** | Analytics dashboard enhancement | 2 days | Medium — admin value add |
| **P4** | Polish, animations, testing | 5 days | Low — quality of life |

---

## File Structure Reference

### Flutter Files to Focus On

```
sentinel_ng/lib/
├── main.dart                          # Entry point ✅
├── app.dart                           # Routing + BLoC providers ✅
├── core/services/api_service.dart     # API client ✅ (needs testing)
│
├── features/auth/bloc/auth_bloc.dart  # Auth state management 🟡 (needs API integration)
├── features/home/presentation/home_page.dart  # Home dashboard ✅ (fixed!)
├── features/reporting/presentation/reporting_wizard_screen.dart  # Wizard UI ✅ (needs API submit)
│
├── features/emergency/presentation/sos_page.dart  # SOS screen 🟡 (needs API connection)
├── features/map/                      # Map screens 🔴 (skeleton only)
├── features/notifications/            # Notifications 🔴 (skeleton only)
└── features/profile/                  # Profile 🔴 (skeleton only)
```

### Next.js Files to Focus On

```
crime-location-reporting-system/src/
├── app/api/auth/[...nextauth]/route.ts  # Auth routes ✅
├── app/api/reports/route.ts             # Reports CRUD ✅
├── app/api/admin/                       # Admin operations ✅
│   ├── reports/page.tsx                 # Report review list ✅
│   ├── users/page.tsx                   # User management ✅
│   └── settings/page.tsx                # System settings ✅
├── components/admin/charts/             # Analytics charts ✅
│   ├── CrimeTypeChart.tsx               # Pie chart ✅
│   ├── ReportTrendsChart.tsx            # Line chart ✅
│   └── RiskLevelChart.tsx               # Bar chart ✅
└── middleware.ts                        # CORS config 🟡 (needs implementation)
```

---

## Quick Start Commands

### Flutter App
```bash
cd sentinel_ng
flutter pub get          # Get dependencies
flutter run -d chrome    # Run on Chrome for development
```

### Next.js Backend
```bash
cd crime-location-reporting-system
npm install              # Install dependencies
npx prisma migrate dev   # Run migrations
npm run dev              # Start development server
```

### Test Integration
1. Start Next.js: `npm run dev` (runs on http://localhost:3000)
2. Update Flutter API base URL in `lib/core/services/api_service.dart`:
   ```dart
   static const String _defaultBaseUrl = 'http://localhost:3000/api'; // Chrome web
   ```
3. Run Flutter: `flutter run -d chrome`
4. Test login flow → should connect to Next.js API

---

*Last Updated: $(date +%Y-%m-%d)*  
*Status: Core UI complete, API integration in progress*  
*Next Step: Connect auth BLoC to real API endpoints*
