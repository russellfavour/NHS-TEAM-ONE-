# 🛡️ Sentinel NG — Crime Location Reporting System
## Complete Architecture & Implementation Recommendations

> **Tech Stack**: Flutter (Mobile App) · React/Vue.js (Admin Web Portal) · Node.js + Express (Backend API) · MongoDB (Database)
> **Purpose**: Competition-ready, production-quality crime reporting platform for Nigerian communities.
>
> **TOR Compliance**: Full coverage of all Terms of Reference requirements including admin dashboard, verification workflow, risk tagging, analytics & reports, and security agency dispatch.

---

## 1. 📱 Complete Screen Inventory

### Part A — Mobile App Screens (User-Facing)

| # | Screen Name | Category | Description |
|---|-------------|----------|-------------|
| 1 | Splashscreen | Auth Flow | App branding + loading indicator |
| 2-4 | Onboarding (1/2/3) | Auth Flow | Feature walkthrough: Report Crimes, Safe Routes, Stay Together |
| 5 | Login | Auth Flow | Email/password + Google & Apple OAuth |
| 6 | RegisterScreen | Auth Flow | Full name, phone, email, password with confirmation |
| 7 | HomeDashboard | Core App | Safety score, quick actions, recent alerts |
| 8 | SOS | Emergency | One-tap emergency alert with pulsing red button |
| 9-10 | Liveemergency (1/2) | Emergency | Active emergency state + "Help is on the way" tracking |
| 11 | SafeRoute | Safety | Route planning with AI safety scoring |
| 12 | SelectcrimeType | Reporting Wizard | Crime type selection (Armed Robbery, Theft, Assault, etc.) |
| 13 | Selectlocation | Reporting Wizard | Map-based location pinning + current location |
| 14 | Incidentdescription | Reporting Wizard | Text description with character counter (500 max) |
| 15-16 | WitnessInformation (1/2) | Reporting Wizard | Add witness details, optional multi-witness support |
| 17 | SuspectInformation | Reporting Wizard | Physical description + vehicle info fields |
| 18 | RecordAudio | Evidence Collection | Audio recording with waveform visualization |
| 19-20 | UploadPhotos/Video | Evidence Collection | Photo gallery (up to 6) + video upload |
| 21 | CrimeDetails | Core App | Detailed crime report view with evidence thumbnails |
| 22 | CrimeMap | Core App | Interactive map with heat zones, filters, incident markers |
| 23 | Notification | Core App | Categorized alerts (All, Alerts, Updates, System) |
| 24 | Search | Core App | Location/crime type search with recent & popular searches |
| 25 | SafetyScore | Profile Sub-screen | Detailed safety score breakdown with metrics |
| 26 | Profile | Core App | User profile, reports count, settings, emergency contacts |
| 27 | Reportsubmitted | Reporting Wizard | Success confirmation with report ID (#SR2387) |

### Part B — Mobile Screens for Verification & Tracking (TOR Gap-Fillers)

| # | Screen Name | Category | Description |
|---|-------------|----------|-------------|
| 28 | MyReportsStatus | Profile Sub-screen | List of user's reports with status badges (Submitted/Under Review/Verified/Dismissed) |
| 29 | ReportStatusTimeline | Crime Detail Add-on | Visual progress tracker showing each verification stage with timestamps |
| 30 | SafePlaceMarkers | Map Add-on | User-saved safe locations (police stations, hospitals, churches/mosques) overlaid on map |

### Part C — Admin Web Portal Screens (See [ADMIN-RECOMMENDATIONS.md](./ADMIN-RECOMMENDATIONS.md))

| # | Screen Name | Category | Description |
|---|-------------|----------|-------------|
| A1–A27 | See ADMIN doc | Admin Portal | Complete admin dashboard with verification, analytics, dispatch, and user management |

> **Total System Screens**: 54 (30 mobile + 24 web admin)

**See [ADMIN-RECOMMENDATIONS.md](./ADMIN-RECOMMENDATIONS.md) for the complete admin screen inventory.**

---

## 2. 🏗️ Recommended Flutter Project Structure (Feature-Based)

```
lib/
├── main.dart                          # App entry point + theme config
├── app.dart                           # MaterialApp configuration
│
├── core/                              # Shared infrastructure
│   ├── constants/
│   │   ├── colors.dart                # Primary green (#006400), red, white palette
│   │   ├── strings.dart               # App-wide text constants
│   │   └── routes.dart                # Route names (navigators)
│   ├── theme/
│   │   ├── app_theme.dart             # Light/dark theme definitions
│   │   └── text_styles.dart           # Typography system
│   ├── utils/
│   │   ├── validators.dart            # Form validation helpers
│   │   ├── formatters.dart            # Phone, date formatting
│   │   └── extensions.dart            # String/date extensions
│   ├── services/
│   │   ├── api_service.dart           # HTTP client (Dio/Retrofit)
│   │   ├── location_service.dart      # Geolocation/GPS
│   │   ├── notification_service.dart  # Push notifications
│   │   └── storage_service.dart       # Local cache/Hive
│   ├── widgets/
│   │   ├── custom_button.dart         # Reusable green CTA button
│   │   ├── custom_textfield.dart      # Styled text input
│   │   ├── loading_indicator.dart     # Circular progress widget
│   │   ├── error_view.dart            # Error state display
│   │   └── bottom_nav_bar.dart        # Custom bottom navigation
│   └── errors/
│       ├── exceptions.dart            # Custom exception classes
│       └── failures.dart              # Failure types (equatable)
│
├── data/                              # Data layer
│   ├── models/                        # All data models (JSON ↔ Dart)
│   │   ├── user_model.dart
│   │   ├── crime_report_model.dart
│   │   ├── notification_model.dart
│   │   ├── location_model.dart
│   │   ├── evidence_model.dart
│   │   ├── safety_score_model.dart
│   │   └── report_status_model.dart   # NEW: Status tracking model
│   ├── repositories/                  # Repository interface implementations
│   │   ├── auth_repository_impl.dart
│   │   ├── crime_repository_impl.dart
│   │   ├── notification_repository_impl.dart
│   │   └── map_repository_impl.dart
│   ├── datasources/                   # Remote & local data sources
│   │   ├── remote/
│   │   │   ├── auth_remote_source.dart
│   │   │   ├── crime_remote_source.dart
│   │   │   ├── notification_remote_source.dart
│   │   │   └── admin_remote_source.dart  # NEW: Admin API calls from mobile
│   │   └── local/
│   │       ├── prefs_local_source.dart
│   │       └── hive_adapters.g.dart
│   └── services/                      # Third-party integrations
│       ├── firebase_service.dart      # FCM, Auth (optional)
│       ├── google_maps_service.dart
│       └── cloudinary_service.dart    # Media upload
│
├── features/                          # Feature modules (one per domain)
│   │
│   ├── auth/                          # 🔐 Authentication feature
│   │   ├── data/
│   │   │   ├── models/user_model.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── splash/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   └── splash_bloc.dart
│   │   │   ├── onboarding/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── onboarding_controller.dart
│   │   │   │   └── widgets/onboarding_page_widget.dart
│   │   │   ├── login/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── login_bloc.dart
│   │   │   └── register/
│   │   │       ├── register_screen.dart
│   │   │       └── register_bloc.dart
│   │   └── domain/
│   │       ├── entities/user_entity.dart
│   │       └── repositories/auth_repository.dart
│   │
│   ├── home/                          # 🏠 Home Dashboard feature
│   │   ├── presentation/
│   │   │   ├── home_dashboard_screen.dart
│   │   │   ├── widgets/safety_score_card.dart
│   │   │   ├── widgets/quick_actions_grid.dart
│   │   │   └── widgets/recent_alerts_list.dart
│   │   └── presentation/bloc/home_bloc.dart
│   │
│   ├── reporting/                     # 📝 Crime Reporting Wizard (MAIN FEATURE)
│   │   ├── presentation/
│   │   │   ├── crime_report_wizard.dart         # Multi-step wizard orchestrator
│   │   │   ├── select_crime_type_screen.dart    # Step 1: Crime type picker
│   │   │   ├── select_location_screen.dart      # Step 2: Map location pin
│   │   │   ├── incident_description_screen.dart # Step 3: Text description
│   │   │   ├── witness_information_screen.dart  # Step 4: Witness details
│   │   │   ├── suspect_information_screen.dart  # Step 5: Suspect details
│   │   │   ├── evidence_collection_screen.dart  # Step 6: Photos/audio/video
│   │   │   ├── preview_report_screen.dart       # Step 7: Review & submit
│   │   │   └── report_success_screen.dart       # Step 8: Confirmation (#SR2387)
│   │   └── presentation/bloc/reporting_bloc.dart
│   │
│   ├── emergency/                     # 🚨 SOS / Emergency feature
│   │   ├── presentation/
│   │   │   ├── sos_screen.dart                # Pulsing red button screen
│   │   │   ├── live_emergency_screen.dart     # Active alert + ETA tracking
│   │   │   └── safe_route_screen.dart         # Route planning with safety score
│   │   └── presentation/bloc/emergency_bloc.dart
│   │
│   ├── map/                           # 🗺️ Crime Map feature
│   │   ├── presentation/
│   │   │   ├── crime_map_screen.dart          # Interactive heatmap + markers
│   │   │   ├── widgets/map_filter_bar.dart    # All/Robbery/Theft/Assault tabs
│   │   │   ├── widgets/crime_marker_cluster.dart
│   │   │   └── widgets/safe_place_overlay.dart  # NEW: Safe place markers
│   │   └── presentation/bloc/map_bloc.dart
│   │
│   ├── crime_details/                 # 🔍 Crime Detail feature
│   │   ├── presentation/
│   │   │   ├── crime_detail_screen.dart       # Full report view with evidence
│   │   │   ├── widgets/evidence_gallery.dart  # Photo/video carousel
│   │   │   └── widgets/report_status_timeline.dart  # NEW: Status tracker
│   │   └── presentation/bloc/crime_detail_bloc.dart
│   │
│   ├── notifications/                 # 🔔 Notifications feature
│   │   ├── presentation/
│   │   │   ├── notification_screen.dart       # Categorized alert list
│   │   │   └── widgets/notification_card.dart
│   │   └── presentation/bloc/notification_bloc.dart
│   │
│   ├── search/                        # 🔎 Search feature
│   │   ├── presentation/
│   │   │   ├── search_screen.dart             # Location/crime type search
│   │   │   └── widgets/search_history_list.dart
│   │   └── presentation/bloc/search_bloc.dart
│   │
│   └── profile/                       # 👤 Profile feature
│       ├── presentation/
│       │   ├── profile_screen.dart            # User info, settings entry points
│       │   ├── safety_score_detail_screen.dart # Detailed score breakdown
│       │   ├── my_reports_screen.dart         # List of user's reports
│       │   ├── my_reports_status_screen.dart  # NEW: Status tracking list
│       │   ├── saved_locations_screen.dart    # Saved places
│       │   ├── emergency_contact_screen.dart  # Emergency contact management
│       │   └── settings_screen.dart           # App preferences, privacy
│       └── presentation/bloc/profile_bloc.dart
│
├── navigation/                        # Routing configuration
│   ├── app_router.dart                # GoRouter / AutoRoute setup
│   └── route_guard.dart               # Auth state guard
│
└── di/                                # Dependency injection (if using get_it)
    └── service_locator.dart
```

---

## 3. 🔄 Recommended Screen Flow Order (User Journey)

### Phase A: First-Time User Onboarding (Screens 1–6)

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

**Why this order?**
- Splash establishes brand identity immediately
- Onboarding educates before commitment — critical for trust in a safety app
- Login/Register is the first friction point; keep it simple with social auth options
- Home Dashboard is the natural landing after authentication

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
| ⑤ Profile | Profile | User settings, report history, safety insights, **report status tracking** |

### Phase C: Crime Reporting Wizard (Multi-Step Flow — Screens 12–27)

This is the **heart of your application**. The wizard should feel like a guided conversation, not a form.

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

### Phase D: Emergency Flow (SOS — Screens 8–10)

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

### Phase E: Safety Route Flow (Screen 11)

```
[Triggered from HomeDashboard "Safe Route" or SOS tab]
       ↓
┌─────────────────────────────────────────────┐
│ Safe Route Screen                           │
│   • From/To location inputs                 │
│   • Travel mode: Car / Walking / Bicycle    │
│   • AI Safety Score display (High/Med/Low)  │
│   • "Find Safe Route" button                │
└───────────────────┬─────────────────────────┘
                    ↓
[Route displayed on map with safety overlay]
```

### Phase F: Report Status Tracking Flow (NEW — TOR Gap-Filler)

```
[User navigates to Profile → My Reports or taps a notification about their report]
       ↓
┌─────────────────────────────────────────────┐
│ MyReportsStatus Screen                      │
│   • List of all submitted reports           │
│   • Status badges: Submitted / Under Review │
│     / Verified / Dismissed                  │
│   • Tap any report to see details           │
└───────────────────┬─────────────────────────┘
                    ↓ (tap a report)
┌─────────────────────────────────────────────┐
│ ReportStatusTimeline                        │
│   • Visual progress bar with stages:        │
│     1. Submitted → 2. Under Review          │
│     3. Verified/Dismissed                   │
│   • Timestamps for each stage transition    │
│   • Admin notes (if dismissed)              │
│   • Risk level assigned (High/Med/Low)      │
└─────────────────────────────────────────────┘
```

---

## 4. 🎨 Design System & Theme Guidelines

### Color Palette (from designs)

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

### Typography Hierarchy

```
H1 (Screen Titles):     24px, SemiBold
H2 (Section Headers):   20px, Medium
H3 (Card Titles):       18px, Medium
Body:                   16px, Regular
Caption/Label:          14px, Regular
Small Text:             12px, Regular
```

### Component Reusables

- **`CustomButton`** — Primary green CTA with consistent padding/radius
- **`CustomTextField`** — Outlined text input with label + error state
- **`CrimeTypeChip`** — Colored circular icon + crime name row
- **`AlertCard`** — Notification-style card with type badge + timestamp
- **`SafetyScoreGauge`** — Circular progress indicator for scores
- **`StatusBadge`** — NEW: Color-coded status pill (Submitted=blue, Under Review=yellow, Verified=green, Dismissed=red)

---

## 5. ⚙️ Backend Architecture (Node.js + Express + MongoDB)

### Project Structure

```
backend/
├── server.js                          # Entry point
├── app.js                             # Express app configuration
│
├── config/
│   ├── database.js                    # MongoDB connection
│   ├── jwt.js                         # JWT secret & options
│   └── cloudinary.js                  # Media storage config
│
├── middleware/
│   ├── auth.middleware.js             # JWT verification (user + admin roles)
│   ├── validate.middleware.js         # Request validation
│   ├── upload.middleware.js           # Multer file uploads
│   ├── admin.middleware.js            # NEW: Admin-only access control
│   └── error.middleware.js            # Global error handler
│
├── controllers/
│   ├── auth.controller.js
│   ├── crime.controller.js
│   ├── notification.controller.js
│   ├── map.controller.js
│   ├── evidence.controller.js
│   ├── profile.controller.js
│   ├── admin.controller.js            # NEW: Admin dashboard data aggregation
│   ├── dispatch.controller.js         # NEW: SOS emergency dispatch management
│   └── analytics.controller.js        # NEW: Analytics & report generation
│
├── routes/
│   ├── auth.routes.js                 # POST /register, /login, /forgot-password
│   ├── crime.routes.js                # CRUD + search + stats
│   ├── notification.routes.js         # GET/PUT notifications
│   ├── map.routes.js                  # GET heatmap data, nearby crimes
│   ├── evidence.routes.js             # POST upload, DELETE media
│   ├── profile.routes.js              # GET/PUT user profile
│   ├── admin.routes.js                # NEW: Admin dashboard endpoints
│   └── dispatch.routes.js             # NEW: Emergency dispatch endpoints
│
├── models/                            # Mongoose schemas
│   ├── User.js
│   ├── CrimeReport.js
│   ├── Notification.js
│   ├── Evidence.js
│   ├── SafetyScore.js
│   ├── ResponderLog.js                # NEW: SOS responder tracking
│   └── BroadcastAlert.js              # NEW: Admin broadcast notifications
│
├── services/
│   ├── email.service.js               # Transactional emails
│   ├── push-notification.service.js   # FCM push notifications
│   ├── geolocation.service.js         # Distance/radius calculations
│   ├── ai-safety.service.js           # Route safety scoring logic
│   ├── analytics.service.js           # NEW: Aggregation & trend analysis
│   └── report-export.service.js       # NEW: PDF/CSV report generation
│
├── jobs/                              # Scheduled tasks (node-cron)
│   ├── cleanup-uploads.js             # Remove expired temp files
│   ├── generate-daily-alerts.js       # Compile daily safety digest
│   └── update-safety-scores.js        # NEW: Recalculate user safety scores
│
└── utils/
    ├── logger.js                      # Winston/Pino logging
    ├── response-handler.js            # Standardized API responses
    └── validators.js                  # Joi/Zod validation schemas
```

### Key MongoDB Collections & Schemas

#### `users` Collection
```javascript
{
  _id: ObjectId,
  fullName: String,
  email: { type: String, unique: true },
  phone: { type: String, index: true },
  passwordHash: String,          // bcrypt hashed
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  isVerified: Boolean,           // Email/phone verification
  profilePicture: String,        // Cloudinary URL
  emergencyContacts: [{
    name: String,
    phone: String,
    relationship: String
  }],
  safetyScore: {                 // Computed/aggregated
    overall: Number,             // 0-100
    onlineActivity: Number,
    communityParticipation: Number,
    reportAccuracy: Number,
    responseTime: Number
  },
  createdAt: Date,
  lastLogin: Date
}
```

#### `crime_reports` Collection (Enhanced)
```javascript
{
  _id: ObjectId,
  reportId: { type: String, unique: true },  // e.g., "SR2387"
  reporterId: { type: ObjectId, ref: 'User' },
  status: {
    type: String,
    enum: ['submitted', 'under_review', 'verified', 'dismissed'],
    default: 'submitted'
  },

  // Verification history (NEW)
  verificationHistory: [{
    action: { type: String, enum: ['submitted', 'review_started', 'verified', 'dismissed'] },
    performedBy: ObjectId,       // Admin who took the action
    timestamp: Date,
    notes: String                // Admin comments visible to reporter
  }],

  crimeType: { type: String, enum: [
    'armed_robbery', 'theft', 'assault',
    'vandalism', 'cyber_crime', 'suspicious_activity', 'others'
  ]},

  location: {
    address: String,
    coordinates: { type: [Number], index: '2dsphere' }, // [lng, lat]
    landmark: String
  },

  description: String,
  additionalDetails: String,

  incidentDateTime: Date,

  witnesses: [{
    name: String,           // Can be empty for anonymity
    phone: String,          // Can be empty
    statement: String
  }],

  suspectInfo: {
    description: String,
    vehicleInfo: String,
    numberOfSuspects: Number
  },

  evidence: [{
    type: { type: String, enum: ['photo', 'video', 'audio'] },
    url: String,            // Cloudinary URL
    uploadedAt: Date
  }],

  isAnonymous: Boolean,     // Hide reporter identity publicly

  // Risk tagging (NEW - TOR requirement)
  riskLevel: {
    type: String,
    enum: ['high', 'medium', 'low'],
    default: 'pending'
  },
  riskTaggedBy: ObjectId,   // Admin who assigned risk level
  riskTaggedAt: Date,

  verifiedBy: ObjectId,     // Admin who verified/dismissed
  verificationDate: Date,

  createdAt: Date,
  updatedAt: Date
}
```

#### `notifications` Collection
```javascript
{
  _id: ObjectId,
  userId: { type: ObjectId, ref: 'User', index: true },
  type: { type: String, enum: ['alert', 'update', 'system'] },
  title: String,
  message: String,
  relatedReportId: ObjectId, // Link to crime report if applicable
  isRead: Boolean,
  createdAt: Date
}
```

#### `responder_logs` Collection (NEW — TOR Gap-Filler)
```javascript
{
  _id: ObjectId,
  sosAlertId: { type: String, unique: true }, // e.g., "SOS-2024-001"
  reporterId: { type: ObjectId, ref: 'User' },
  status: { type: String, enum: ['triggered', 'acknowledged', 'en_route', 'on_scene', 'resolved'] },

  location: {
    coordinates: { type: [Number], index: '2dsphere' }, // Reporter's live coords
    address: String
  },

  assignedResponderId: ObjectId,   // Admin/responder who accepted the SOS
  acknowledgedAt: Date,
  enRouteAt: Date,
  onSceneAt: Date,
  resolvedAt: Date,

  createdAt: Date,
  updatedAt: Date
}
```

#### `broadcast_alerts` Collection (NEW — TOR Gap-Filler)
```javascript
{
  _id: ObjectId,
  title: String,
  message: String,
  targetAudience: { type: String, enum: ['all', 'region', 'verified_users'] },
  regionFilter: {                    // Optional: targeted geographic area
    coordinates: [[Number]],         // Polygon for geo-fencing
    radius: Number                   // Or circle radius in km
  },
  priority: { type: String, enum: ['low', 'medium', 'high', 'critical'] },
  isActive: Boolean,                 // Soft delete toggle
  sentAt: Date,                      // When broadcast was pushed via FCM
  deliveredCount: Number,            // Analytics tracking
  createdBy: ObjectId,               // Admin who created it
  createdAt: Date
}
```

---

## 6. 📐 API Endpoints Reference

### Authentication
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/api/auth/register` | Create new user account | Public |
| POST | `/api/auth/login` | Authenticate & return JWT | Public |
| POST | `/api/auth/admin-login` | Admin-specific login (enhanced security) | Public |
| POST | `/api/auth/forgot-password` | Request password reset | Public |
| PUT | `/api/auth/reset-password` | Reset with token | Public |
| GET | `/api/auth/me` | Get current user profile | User/Admin |

### Crime Reports (User-Facing)
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/api/crimes` | Submit new crime report | User |
| GET | `/api/crimes` | List crimes (paginated, filterable) | Public* |
| GET | `/api/crimes/:id` | Get single crime detail | Public* |
| GET | `/api/crimes/my-reports` | List user's submitted reports | User |
| GET | `/api/crimes/:id/status` | Track report status updates | User (own only) |
| GET | `/api/crimes/search` | Search by location/type/date | Public* |
| GET | `/api/crimes/heatmap` | Get heatmap data for map view | Public* |

> *Public*: Verified reports only; unverified hidden from public API.

### Crime Reports (Admin-Facing — NEW)
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| PUT | `/api/crimes/:id/verify` | Approve a report (set status=verified) | Admin |
| PUT | `/api/crimes/:id/dismiss` | Reject a report (set status=dismissed) | Admin |
| PUT | `/api/crimes/:id/review-start` | Mark as under_review | Admin |
| PUT | `/api/crimes/:id/risk-level` | Assign risk level (high/medium/low) | Admin |
| PUT | `/api/crimes/:id/admin-notes` | Add admin notes visible to reporter | Admin |
| GET | `/api/admin/reports/pending` | List all reports awaiting review | Admin |
| GET | `/api/admin/reports/by-status` | Filter by status with pagination | Admin |
| DELETE | `/api/crimes/:id` | Delete report (admin) | Admin |

### User Management (Admin-Facing — NEW)
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/admin/users` | List all registered users | Admin |
| GET | `/api/admin/users/:id` | Get user details + report history | Admin |
| PUT | `/api/admin/users/:id/ban` | Suspend/ban a user account | Admin |
| PUT | `/api/admin/users/:id/unban` | Reactivate a banned user | Admin |
| GET | `/api/admin/users/stats` | User statistics (new users, active, etc.) | Admin |

### Map & Safety
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/map/nearby` | Get crimes within radius | Public* |
| POST | `/api/safety/route` | Calculate safe route + score | User |
| GET | `/api/safety/score/:userId` | Get user's safety score breakdown | User/Admin |
| GET | `/api/map/safe-places` | List saved safe places (police, hospitals) | Public* |

### Evidence
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/api/evidence/upload` | Upload photo/video/audio (multipart) | User |
| DELETE | `/api/evidence/:id` | Remove evidence | User/Admin |

### Notifications
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/notifications` | List user notifications | User |
| PUT | `/api/notifications/:id/read` | Mark as read | User |
| PUT | `/api/notifications/mark-all-read` | Bulk mark all read | User |

### Profile
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/profile` | Get full profile | User |
| PUT | `/api/profile` | Update profile info | User |
| PUT | `/api/profile/emergency-contacts` | Update emergency contacts | User |
| GET | `/api/profile/saved-locations` | List saved locations | User |

### SOS Emergency Dispatch (NEW — TOR Gap-Filler)
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/api/dispatch/sos-trigger` | Trigger emergency SOS alert | User |
| GET | `/api/dispatch/sos/:alertId` | Get SOS alert status + ETA | User (own only) |
| PUT | `/api/dispatch/sos/acknowledge` | Responder acknowledges SOS | Admin |
| PUT | `/api/dispatch/sos/update-status` | Update responder status (en_route, on_scene, resolved) | Admin |

### Analytics & Reports (NEW — TOR Gap-Filler)
| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/admin/analytics/overview` | Dashboard overview stats | Admin |
| GET | `/api/admin/analytics/crime-types` | Crime type distribution (pie chart data) | Admin |
| GET | `/api/admin/analytics/trends/daily` | Daily crime count trend (line chart) | Admin |
| GET | `/api/admin/analytics/trends/weekly` | Weekly crime count trend | Admin |
| GET | `/api/admin/analytics/trends/monthly` | Monthly crime count trend | Admin |
| GET | `/api/admin/analytics/hotspots` | Top 10 crime hotspot locations | Admin |
| GET | `/api/admin/reports/export/csv` | Export filtered reports as CSV | Admin |
| GET | `/api/admin/reports/export/pdf` | Generate PDF analytics report | Admin |

---

## 7. 🏆 Competition-Building Best Practices

### Flutter-Side

1. **State Management**: Use **Bloc/Cubit** pattern (as shown in structure) — demonstrates architectural maturity to judges
2. **Clean Architecture**: Separate `data`, `domain`, and `presentation` layers per feature
3. **Dependency Injection**: Use `get_it` + `injectable` for testable, decoupled code
4. **Error Handling**: Implement proper error states with `Failure` classes (equatable)
5. **Offline Support**: Cache critical data with Hive/Isar for offline access
6. **Accessibility**: Semantic labels, contrast ratios, dynamic text sizing
7. **Animations**: Use `flutter_animate` or Rive for smooth transitions between wizard steps
8. **Testing Strategy**: Unit tests (Bloc + services), Widget tests (key screens), Integration tests (critical flows)

### Backend-Side

1. **Validation**: Joi/Zod on every input — never trust client data
2. **Rate Limiting**: `express-rate-limit` to prevent abuse
3. **Input Sanitization**: Prevent NoSQL injection, XSS
4. **Pagination & Cursor-based**: For crime lists and notifications
5. **Indexing Strategy**: Compound indexes on frequently queried fields (location + date, status + type)
6. **Logging**: Structured logging with Winston for debugging during demo
7. **Environment Variables**: `.env` for all secrets — never hardcode

### Demo-Ready Polish

1. **Seed Data**: Pre-populate MongoDB with realistic Nigerian crime data for the competition demo
2. **Mock GPS**: Ability to simulate different locations for map demonstration
3. **Live SOS Demo**: Show real-time location sharing on a secondary screen (mobile + admin)
4. **Report Flow Speed**: Ensure the reporting wizard completes in under 60 seconds
5. **Error Scenarios**: Prepare graceful error states (no network, invalid input)

---

## 8. 📋 Recommended Development Phases

### Phase 1: Foundation (Days 1–3)
- [ ] Set up Flutter project with Clean Architecture skeleton
- [ ] Configure theme, typography, reusable widgets
- [ ] Build auth screens (Splash → Onboarding → Login → Register)
- [ ] Set up Node.js backend + MongoDB connection
- [ ] Implement auth API endpoints (register/login/JWT)

### Phase 2: Core Features (Days 4–7)
- [ ] Home Dashboard with safety score card + quick actions
- [ ] Bottom navigation with all 5 tabs
- [ ] Crime Reporting Wizard (all 8 steps)
- [ ] Backend crime report CRUD endpoints
- [ ] Evidence upload integration (Cloudinary or local storage)

### Phase 3: Map & Emergency (Days 8–10)
- [ ] Interactive CrimeMap with markers + filters
- [ ] SOS screen with pulsing animation
- [ ] Live Emergency tracking screen
- [ ] Safe Route planning screen
- [ ] Backend map/heatmap endpoints

### Phase 4: Admin Portal — Web Dashboard (Days 11–15)
> **See [ADMIN-RECOMMENDATIONS.md](./ADMIN-RECOMMENDATIONS.md) for full admin development plan**
- [ ] Set up React/Vue.js + Tailwind CSS project
- [ ] Build AdminLogin screen with enhanced security
- [ ] Build AdminDashboard overview (stats cards, mini-charts)
- [ ] Implement ReportReviewList with status filters
- [ ] Build ReportDetailReview for verification workflow
- [ ] Add RiskTaggingPanel to assign risk levels
- [ ] Create AnalyticsDashboard with charts (fl_chart equivalent for web)
- [ ] Implement UserManagement screen

### Phase 5: Verification & Tracking Features (Days 16–18)
- [ ] MyReportsStatus screen in Flutter mobile app
- [ ] ReportStatusTimeline visual tracker
- [ ] Backend verification workflow endpoints
- [ ] Push notification integration for status updates
- [ ] SafePlaceMarkers overlay on CrimeMap

### Phase 6: Analytics, Dispatch & Polish (Days 19–22)
- [ ] Admin analytics charts (crime trends, hotspots)
- [ ] SOS dispatch management in admin portal
- [ ] Broadcast alert system for admins
- [ ] Report export (CSV/PDF generation)
- [ ] Notifications screen with categorization
- [ ] Search functionality
- [ ] Profile + Settings screens

### Phase 7: Competition Prep (Days 23–25)
- [ ] Seed database with demo data
- [ ] End-to-end testing of all flows (mobile + admin)
- [ ] Performance optimization
- [ ] Error handling polish
- [ ] Presentation rehearsal

---

## 9. 📦 Recommended Flutter Packages

| Purpose | Package | Version Note |
|---------|---------|--------------|
| State Management | `flutter_bloc` + `equatable` | Industry standard for Clean Architecture |
| HTTP Client | `dio` | Interceptors, retry logic, multipart support |
| Dependency Injection | `get_it` + `injectable` | Compile-time DI generation |
| Local Storage | `hive` + `hive_flutter` | Fast NoSQL local database |
| Maps | `google_maps_flutter` | Google Maps integration |
| Location | `geolocator` | GPS location services |
| Image Picker | `image_picker` | Camera + gallery access |
| Video Player | `video_player` | Evidence video playback |
| Audio Recording | `record` | Audio waveform recording |
| Routing | `go_router` | Declarative navigation with deep linking |
| Animations | `flutter_animate` or `lottie` | Smooth transitions |
| Form Validation | `formz` + `reactive_forms` | Clean form state management |
| Charts (Safety Score) | `fl_chart` | Circular progress, bar charts |
| Push Notifications | `firebase_messaging` | FCM integration |
| Environment Config | `flutter_dotenv` | .env file support |

### Recommended Web Admin Packages (React/Vue + Tailwind CSS)

| Purpose | Package | Note |
|---------|---------|------|
| Framework | `react` or `vue@3` | Component-based UI |
| Styling | `tailwindcss` | Utility-first CSS framework |
| State Management | `zustand` (React) / `pinia` (Vue) | Lightweight state management |
| Routing | `react-router-dom` / `vue-router` | Client-side routing |
| HTTP Client | `axios` | Request interceptors, error handling |
| Charts | `recharts` or `chart.js` + `vue-chartjs` | Analytics dashboard charts |
| Maps | `leaflet-react` or `@amap/amap-vue` | Interactive map for admin heatmap |
| Data Tables | `ag-grid-react` / `vuetify-data-tables` | Paginated, filterable report tables |
| File Export | `jspdf` + `xlsx` | PDF and CSV report generation |
| Icons | `lucide-react` or `@mdi/font` | Consistent icon system |

---

## 10. 🎯 Key Differentiators for Competition Judges

1. **Multi-Step Reporting Wizard** — Not just a form; it's a guided, conversational experience with progress indication
2. **Safety Score System** — Gamified community engagement metric (unique selling point)
3. **Real-Time SOS + ETA Tracking** — Shows live emergency response capability
4. **AI Safety Route Planning** — Route optimization based on crime data heatmaps
5. **Evidence-Rich Reports** — Photos, video, audio recording directly in the report flow
6. **Anonymous Reporting Option** — Privacy-first design encouraging community participation
7. **Nigerian Context** — Localized for Nigerian cities (Lagos focus), addresses real local needs
8. **Complete Admin Dashboard** — Full TOR compliance with verification workflow, risk tagging, analytics & reports, and security agency dispatch *(NEW)*
9. **Dual-Platform Architecture** — Mobile app for citizens + Web portal for agencies *(NEW)*

---

*Document generated from analysis of 26 UI/UX screen designs + TOR gap analysis.*
*Tech Stack: Flutter (Mobile) · React/Vue.js (Admin Web) · Node.js + Express · MongoDB*
*Architecture Pattern: Clean Architecture with BLoC state management*
*Total Screens: 54 (30 mobile + 24 web admin)*
