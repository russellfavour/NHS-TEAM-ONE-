# 🛡️ Sentinel NG — Admin Web Portal
## Complete Architecture & Implementation Recommendations

> **Tech Stack**: React.js (or Vue.js) · Tailwind CSS · Node.js + Express API · MongoDB
> **Purpose**: Full-featured admin dashboard for security agencies to monitor, verify, and respond to crime reports.
>
> **TOR Compliance**: Covers all missing TOR requirements — admin dashboard, report verification, risk tagging, analytics & reports, user management, emergency dispatch, and broadcast alerts.

---

## 1. 📱 Complete Admin Screen Inventory (24 Screens)

### Part A — Authentication & Access Control

| # | Screen Name | Description |
|---|-------------|-------------|
| A1 | AdminLogin | Dual-factor admin login with role verification |
| A2 | AdminSessionExpired | Session timeout warning with re-authentication prompt |

### Part B — Dashboard & Overview

| # | Screen Name | Description |
|---|-------------|-------------|
| A3 | AdminDashboard | Main overview: total reports, pending verifications, active SOS alerts, today's stats |
| A4 | QuickStatsPanel | Inline widget showing real-time counters (reports today, verified today, high-risk pending) |

### Part C — Report Management & Verification (CORE)

| # | Screen Name | Description |
|---|-------------|-------------|
| A5 | ReportReviewList | Paginated table of all submitted reports with status filters and search |
| A6 | ReportDetailReview | Full report view for admin verification: evidence gallery, witness info, suspect details, location map |
| A7 | RiskTaggingPanel | Assign risk level (High/Medium/Low) with reasoning notes; bulk tagging option |
| A8 | VerificationDecisionModal | Approve/Reject dialog with mandatory reason field and optional internal notes |
| A9 | ReportHistoryTimeline | Visual timeline of a report's lifecycle: submitted → reviewed → verified/dismissed, with admin actions |

### Part D — Analytics & Intelligence Dashboard

| # | Screen Name | Description |
|---|-------------|-------------|
| A10 | AnalyticsDashboard | Main analytics hub with tabbed views (Daily / Weekly / Monthly) |
| A11 | CrimeTypeDistributionChart | Pie/donut chart showing breakdown by crime type |
| A12 | TemporalTrendCharts | Line charts: crimes per day/week/month with trend indicators |
| A13 | HotspotMap | Interactive map highlighting top 10 crime hotspots with intensity circles |
| A14 | RiskLevelDistributionChart | Bar chart showing distribution of high/medium/low risk reports over time |
| A15 | VerificationEfficiencyMetrics | Admin performance: avg. review time, verification rate, dismissal rate |

### Part E — Emergency Dispatch & Response Management

| # | Screen Name | Description |
|---|-------------|-------------|
| A16 | ActiveSOSAlerts | Real-time list of active SOS alerts with reporter location on mini-map |
| A17 | SOSAlertDetail | Full SOS detail: live tracker, ETA calculation, responder assignment dropdown |
| A18 | ResponderAssignmentPanel | Assign available responders to SOS alerts; view responder availability |
| A19 | DispatchStatusBoard | Kanban-style board showing SOS alerts by status (Triggered → Acknowledged → En Route → On Scene → Resolved) |

### Part F — User Management

| # | Screen Name | Description |
|---|-------------|-------------|
| A20 | UserManagementList | Paginated table of all registered users with search and filters |
| A21 | UserProfileDetail | Full user profile: personal info, report history, safety score, ban status |
| A22 | BanSuspendPanel | Toggle to suspend/ban a user; reason field required; notification sent on action |

### Part G — Content & Configuration Management

| # | Screen Name | Description |
|---|-------------|-------------|
| A23 | CrimeClassificationManager | CRUD interface for crime type categories (add/edit/delete types) |
| A24 | BroadcastAlertPanel | Create and send push notifications to users: target audience, message, priority, geo-fencing |

### Part H — Reports & Export

| # | Screen Name | Description |
|---|-------------|-------------|
| A25 | ReportExportCenter | Configure and generate export reports (CSV/JSON/PDF) with date range and filter options |
| A26 | PDFReportPreview | Preview generated analytics report before download |

### Part I — System Settings

| # | Screen Name | Description |
|---|-------------|-------------|
| A27 | AdminSettings | Admin profile, password change, notification preferences, API key management |

> **Total Admin Screens**: 27 (including sub-panels and modals)

---

## 2. 🏗️ Recommended Web Project Structure (React + Tailwind CSS)

```
admin-web/
├── public/
│   └── index.html
├── src/
│   ├── main.jsx                         # App entry point
│   ├── App.jsx                          # Router configuration + layout shell
│   │
│   ├── assets/                          # Static assets (logos, icons)
│   │   ├── logo.svg
│   │   └── placeholder-avatar.png
│   │
│   ├── components/                      # Shared UI components
│   │   ├── layout/
│   │   │   ├── Sidebar.jsx              # Left navigation sidebar
│   │   │   ├── TopBar.jsx               # Header with user info + notifications
│   │   │   └── MainContent.jsx          # Content wrapper with padding/margins
│   │   ├── data-table/
│   │   │   ├── DataTable.jsx            # Paginated, sortable table component
│   │   │   ├── FilterBar.jsx            # Search + filter controls row
│   │   │   └── StatusBadge.jsx          # Color-coded status pill
│   │   ├── charts/
│   │   │   ├── CrimeTypePieChart.jsx    # Donut chart for crime types
│   │   │   ├── TrendLineChart.jsx       # Line chart for temporal trends
│   │   │   └── RiskBarChart.jsx         # Bar chart for risk distribution
│   │   ├── maps/
│   │   │   ├── AdminMap.jsx             # Interactive map with heatmap layer
│   │   │   ├── HotspotOverlay.jsx       # Intensity circles on hotspots
│   │   │   └── SOSLiveTracker.jsx       # Live reporter location marker
│   │   ├── modals/
│   │   │   ├── VerificationModal.jsx    # Approve/Reject decision dialog
│   │   │   ├── RiskTaggingModal.jsx     # Risk level assignment dialog
│   │   │   └── BroadcastModal.jsx       # Create broadcast notification
│   │   ├── widgets/
│   │   │   ├── StatCard.jsx             # Summary stat card (icon + number + label)
│   │   │   ├── ActivityFeed.jsx         # Recent admin activity log
│   │   │   └── QuickActionsGrid.jsx     # Shortcut buttons for common tasks
│   │   └── loading/
│   │       ├── SkeletonTable.jsx        # Table skeleton loader
│   │       └── PageLoader.jsx           # Full-page spinner overlay
│   │
│   ├── pages/                           # Route-level page components
│   │   ├── auth/
│   │   │   ├── AdminLogin.jsx           # A1: Admin login screen
│   │   │   └── SessionExpired.jsx       # A2: Session timeout screen
│   │   ├── dashboard/
│   │   │   ├── AdminDashboard.jsx       # A3: Main overview dashboard
│   │   │   └── QuickStatsPanel.jsx      # A4: Inline stats widget
│   │   ├── reports/
│   │   │   ├── ReportReviewList.jsx     # A5: Paginated report list
│   │   │   ├── ReportDetailReview.jsx   # A6: Full review view
│   │   │   ├── RiskTaggingPanel.jsx     # A7: Risk assignment panel
│   │   │   ├── VerificationDecision.jsx # A8: Approve/Reject modal wrapper
│   │   │   └── ReportHistoryTimeline.jsx# A9: Lifecycle timeline
│   │   ├── analytics/
│   │   │   ├── AnalyticsDashboard.jsx   # A10: Main analytics hub
│   │   │   ├── CrimeTypeDistribution.jsx# A11: Pie chart view
│   │   │   ├── TemporalTrends.jsx       # A12: Line charts tabbed by period
│   │   │   ├── HotspotMapView.jsx       # A13: Heatmap + hotspot markers
│   │   │   ├── RiskLevelDistribution.jsx# A14: Risk bar chart
│   │   │   └── VerificationEfficiency.jsx# A15: Admin performance metrics
│   │   ├── dispatch/
│   │   │   ├── ActiveSOSAlerts.jsx      # A16: Real-time SOS list
│   │   │   ├── SOSAlertDetail.jsx       # A17: Full SOS detail view
│   │   │   ├── ResponderAssignment.jsx  # A18: Assign responders
│   │   │   └── DispatchStatusBoard.jsx  # A19: Kanban board
│   │   ├── users/
│   │   │   ├── UserManagementList.jsx   # A20: Users table
│   │   │   ├── UserProfileDetail.jsx    # A21: Full user profile
│   │   │   └── BanSuspendPanel.jsx      # A22: Suspend/ban controls
│   │   ├── content/
│   │   │   ├── CrimeClassificationManager.jsx# A23: CRUD crime types
│   │   │   └── BroadcastAlertPanel.jsx  # A24: Push notification creator
│   │   ├── exports/
│   │   │   ├── ReportExportCenter.jsx   # A25: Export configuration
│   │   │   └── PDFReportPreview.jsx     # A26: Preview before download
│   │   └── settings/
│   │       └── AdminSettings.jsx        # A27: Admin profile & preferences
│   │
│   ├── services/                        # API service layer
│   │   ├── apiClient.js                 # Axios instance with interceptors
│   │   ├── authService.js               # Login/logout/session management
│   │   ├── reportService.js             # Report CRUD + verification endpoints
│   │   ├── analyticsService.js          # Analytics data fetching
│   │   ├── dispatchService.js           # SOS alert management
│   │   ├── userService.js               # User management endpoints
│   │   └── exportService.js             # CSV/PDF generation triggers
│   │
│   ├── store/                           # State management (Zustand)
│   │   ├── authStore.js                 # Auth state + token management
│   │   ├── reportStore.js               # Report list, filters, selected report
│   │   ├── analyticsStore.js            # Analytics data caching
│   │   └── dispatchStore.js             # Active SOS alerts real-time updates
│   │
│   ├── hooks/                           # Custom React hooks
│   │   ├── useAuth.js                   # Auth context + token refresh
│   │   ├── useReports.js                # Report fetching with pagination
│   │   ├── useAnalytics.js              # Analytics data aggregation
│   │   └── useWebSocket.js              # Real-time SOS alert updates
│   │
│   ├── utils/                           # Helper functions
│   │   ├── formatters.js                # Date, number, currency formatting
│   │   ├── validators.js                # Form validation helpers
│   │   ├── constants.js                 # API base URL, status enums, crime types
│   │   └── exportHelpers.js             # CSV generation, PDF config
│   │
│   ├── styles/                          # Global styles
│   │   ├── globals.css                  # Tailwind imports + custom overrides
│   │   └── variables.css                # CSS custom properties (colors, spacing)
│   │
│   └── routes/                          # Route definitions
│       └── AppRoutes.jsx                # React Router configuration with guards
```

---

## 3. 🎨 Admin Design System & Theme Guidelines

### Color Palette (Admin-Specific — Dark Sidebar + Light Content)

| Role | Hex | Usage |
|------|-----|-------|
| **Sidebar Primary** | `#1E293B` (Slate-800) | Left navigation background |
| **Sidebar Active** | `#3B82F6` (Blue-500) | Active menu item highlight |
| **Sidebar Hover** | `#334155` (Slate-700) | Menu item hover state |
| **Content Background** | `#F8FAFC` (Slate-50) | Main content area background |
| **Card Surface** | `#FFFFFF` | Dashboard cards, panels |
| **Primary Accent** | `#006400` (Sentinel Green) | Primary buttons, links |
| **Success** | `#10B981` (Green-500) | Verified status, success actions |
| **Warning** | `#F59E0B` (Amber-500) | Under review, medium risk |
| **Danger** | `#EF4444` (Red-500) | Dismissed, high risk, SOS alerts |
| **Info** | `#3B82F6` (Blue-500) | Submitted status, info badges |
| **Text Primary** | `#1E293B` (Slate-800) | Headings, table text |
| **Text Secondary** | `#64748B` (Slate-500) | Labels, timestamps |

### Status Badge Colors

| Status | Color | Hex |
|--------|-------|-----|
| Submitted | Blue | `#3B82F6` |
| Under Review | Amber/Yellow | `#F59E0B` |
| Verified | Green | `#10B981` |
| Dismissed | Red | `#EF4444` |

### Risk Level Colors

| Risk | Color | Hex | Usage |
|------|-------|-----|-------|
| High | Red + Bold | `#DC143C` | Urgent attention, top of list |
| Medium | Amber | `#F59E0B` | Standard review queue |
| Low | Green | `#10B981` | Routine processing |

### Typography Hierarchy (Admin)

```
Page Title:           24px, SemiBold, Slate-800
Section Header:       20px, Medium, Slate-700
Card Title:           16px, Medium, Slate-700
Table Header:         13px, Semibold, Slate-500 (uppercase)
Body Text:            14px, Regular, Slate-700
Caption/Meta:         12px, Regular, Slate-500
```

### Layout Specifications

| Element | Specification |
|---------|--------------|
| Sidebar Width | 260px (collapsible to 80px) |
| TopBar Height | 64px |
| Content Padding | 24px horizontal, 20px vertical |
| Card Border Radius | 12px |
| Card Shadow | `0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)` |
| Table Row Height | 56px (compact) / 72px (comfortable) |

---

## 4. 🔄 Admin User Journey & Navigation Flow

### Primary Navigation Structure (Sidebar)

```
┌─────────────────────────────────────┐
│  🛡️ SENTINEL NG ADMIN               │ ← Logo + Brand
├─────────────────────────────────────┤
│                                     │
│  📊 DASHBOARD                       │ ← AdminDashboard (A3)
│                                     │
│  ─── REPORTS                        │
│  📋 All Reports                     │ ← ReportReviewList (A5)
│  ⏳ Pending Review                  │ ← Filtered view of A5
│  🔍 Report Detail                   │ ← ReportDetailReview (A6)
│  ⚠️ Risk Tagging                    │ ← RiskTaggingPanel (A7)
│                                     │
│  ─── ANALYTICS                      │
│  📈 Overview                        │ ← AnalyticsDashboard (A10)
│  🗺️ Hotspot Map                     │ ← HotspotMapView (A13)
│  📊 Crime Trends                    │ ← TemporalTrends (A12)
│  🏷️ Risk Distribution               │ ← RiskLevelDistribution (A14)
│                                     │
│  ─── EMERGENCY DISPATCH             │
│  🚨 Active SOS Alerts               │ ← ActiveSOSAlerts (A16)
│  👥 Responder Assignment            │ ← ResponderAssignment (A18)
│  📋 Dispatch Board                  │ ← DispatchStatusBoard (A19)
│                                     │
│  ─── USERS                          │
│  👤 User Management                 │ ← UserManagementList (A20)
│                                     │
│  ─── CONTENT                        │
│  🏷️ Crime Categories                │ ← CrimeClassificationManager (A23)
│  🔔 Broadcast Alerts                │ ← BroadcastAlertPanel (A24)
│                                     │
│  ─── EXPORTS                        │
│  📥 Report Export                   │ ← ReportExportCenter (A25)
│                                     │
│  ⚙️ SETTINGS                        │ ← AdminSettings (A27)
├─────────────────────────────────────┤
│  👤 [Admin Name] ▼                  │ ← User dropdown: Profile, Logout
└─────────────────────────────────────┘
```

### Report Verification Workflow (Core Admin Flow)

```
[Admin logs in → Dashboard shows "X reports pending review"]
       ↓
┌───────────────────────────────────────────────────┐
│ ReportReviewList (A5)                             │
│                                                   │
│  Filter: [All ▼] [Status: Pending ▼] [Risk: All▼]│
│  Search: [🔍 Search reports...]                   │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │ #SR2387 | Armed Robbery | Lagos, Ikeja      │  │
│  │ Status: ⏳ Pending | Risk: ? Untagged       │  │
│  │ Submitted: 2 hours ago | Reporter: Anonymous│  │
│  └─────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────┐  │
│  │ #SR2386 | Theft | Lagos, Victoria Island    │  │
│  │ Status: ⏳ Pending | Risk: ? Untagged       │  │
│  │ Submitted: 5 hours ago | Reporter: John D.  │  │
│  └─────────────────────────────────────────────┘  │
│                                                   │
│  [← 1 2 3 ... 47 →]                              │
└───────────────────┬───────────────────────────────┘
                    ↓ (click a report)
┌───────────────────────────────────────────────────┐
│ ReportDetailReview (A6)                           │
│                                                   │
│  ┌─ Report Info ───────────────────────────────┐ │
│  │ Crime Type: Armed Robbery                   │ │
│  │ Date/Time: 2024-01-15 14:30                 │ │
│  │ Location: 6.6018°N, 3.3515°E (Map)          │ │
│  │ Description: Two masked men...              │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─ Evidence Gallery ──────────────────────────┐ │
│  │ [📷 Photo 1] [📷 Photo 2] [🎵 Audio]        │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─ Witness Info ──────────────────────────────┐ │
│  │ Name: Maria O. | Phone: +234...             │ │
│  │ Statement: I saw them running towards...    │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─ Suspect Info ──────────────────────────────┐ │
│  │ Description: Tall, dark skin, red cap       │ │
│  │ Vehicle: Black Toyota Camry, ABC-123XY      │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─ Actions ───────────────────────────────────┐ │
│  │ [⚠️ Assign Risk Level]                      │ │
│  │                                             │ │
│  │ [✅ VERIFY & APPROVE]   [❌ DISMISS]        │ │
│  │ Reason for dismissal: [_________________]    │ │
│  │ Internal notes:     [_________________]    │ │
│  └─────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘
```

### Analytics Dashboard Flow

```
[Admin clicks "Analytics" in sidebar]
       ↓
┌───────────────────────────────────────────────────┐
│ AnalyticsDashboard (A10)                          │
│                                                   │
│  Period: [Today ▼] [This Week ▼] [This Month ▼]  │
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ 📊 Total │ │ ✅       │ │ ⚠️ High  │          │
│  │ 1,247    │ │ Verified │ │ Risk     │          │
│  │ +12% ↑   │ │ 892      │ │ Pending  │          │
│  └──────────┘ └──────────┘ └──────────┘          │
│                                                   │
│  Tabs: [Crime Types] [Temporal Trends] [Hotspots] │
│                                                   │
│  ── Crime Types Tab ─────────────────────────────│
│  ┌─────────────────┐ ┌───────────────────────┐   │
│  │                 │ │ Armed Robbery  32%    │   │
│  │   [Donut Chart] │ │ Theft         28%     │   │
│  │                 │ │ Assault       18%     │   │
│  │                 │ │ Vandalism      9%     │   │
│  └─────────────────┘ │ Cyber Crime    7%     │   │
│                      │ Others           6%   │   │
│                      └───────────────────────┘   │
│                                                   │
│  ── Temporal Trends Tab ─────────────────────────│
│  ┌─────────────────────────────────────────────┐ │
│  │ Crimes per Day (Line Chart)                 │ │
│  │     /\      /\    /\                        │ │
│  │    /  \    /  \  /  \                       │ │
│  │   /    \/    \/    \______                  │ │
│  │  Jan  Feb  Mar  Apr  May                    │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ── Hotspots Tab ────────────────────────────────│
│  ┌─────────────────────────────────────────────┐ │
│  │ [Interactive Map with intensity circles]     │ │
│  │   Top 5: Ikeja, Victoria Island, Lekki,      │ │
│  │          Surulere, Yaba                      │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  [📥 Export CSV]  [📄 Generate PDF Report]        │
└───────────────────────────────────────────────────┘
```

---

## 5. ⚙️ Admin-Specific Backend Integration Patterns

### Real-Time SOS Alert Updates (WebSocket)

The admin portal needs **live updates** for active SOS alerts. Use Socket.io:

```javascript
// Frontend: src/hooks/useWebSocket.js
import { useEffect, useRef } from 'react';
import io from 'socket.io-client';

export function useSOSAlerts(callback) {
  const socketRef = useRef(null);

  useEffect(() => {
    socketRef.current = io(process.env.REACT_APP_WS_URL, {
      auth: { token: localStorage.getItem('adminToken') }
    });

    socketRef.current.on('sos-alert:new', (alert) => {
      callback(alert); // Trigger UI update / notification sound
    });

    socketRef.current.on('sos-alert:status-update', (update) => {
      callback(update);
    });

    return () => socketRef.current?.disconnect();
  }, [callback]);
}
```

### Analytics Data Aggregation Service

```javascript
// Backend: services/analytics.service.js
const CrimeReport = require('../models/CrimeReport');

class AnalyticsService {
  // Get overview stats for dashboard
  static async getOverviewStats(filters = {}) {
    const matchStage = this.buildMatchStage(filters);

    const [totalReports, verifiedCount, pendingCount, highRiskCount] =
      await Promise.all([
        CrimeReport.countDocuments(matchStage),
        CrimeReport.countDocuments({ ...matchStage, status: 'verified' }),
        CrimeReport.countDocuments({ ...matchStage, status: { $in: ['submitted', 'under_review'] } }),
        CrimeReport.countDocuments({ ...matchStage, riskLevel: 'high' })
      ]);

    return { totalReports, verifiedCount, pendingCount, highRiskCount };
  }

  // Get crime type distribution for pie chart
  static async getCrimeTypeDistribution(filters = {}) {
    const matchStage = this.buildMatchStage(filters);

    return CrimeReport.aggregate([
      { $match: matchStage },
      { $group: { _id: '$crimeType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
  }

  // Get temporal trends (daily counts)
  static async getTemporalTrends(filters = {}) {
    const matchStage = this.buildMatchStage(filters);

    return CrimeReport.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: {
            year: { $year: '$incidentDateTime' },
            month: { $month: '$incidentDateTime' },
            day: { $dayOfMonth: '$incidentDateTime' }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ]);
  }

  // Get top crime hotspots (by coordinate proximity)
  static async getHotspotData(filters = {}) {
    const matchStage = this.buildMatchStage(filters);

    return CrimeReport.aggregate([
      { $match: { ...matchStage, status: 'verified', 'location.coordinates': { $exists: true } } },
      {
        $geoNear: {
          near: { type: 'Point', coordinates: [3.3911, 6.5244] }, // Lagos center
          distanceField: 'dist.calculated',
          maxDistance: 50000, // 50km radius
          spherical: true
        }
      },
      {
        $group: {
          _id: '$location.address',
          count: { $sum: 1 },
          avgCoordinates: { $avg: '$location.coordinates' },
          topCrimeType: { $first: '$crimeType' }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);
  }

  static buildMatchStage(filters) {
    const stage = {};

    if (filters.dateFrom) stage.incidentDateTime = { ...stage.incidentDateTime, $gte: filters.dateFrom };
    if (filters.dateTo)   stage.incidentDateTime = { ...stage.incidentDateTime, $lte: filters.dateTo };
    if (filters.status)   stage.status = filters.status;
    if (filters.riskLevel) stage.riskLevel = filters.riskLevel;

    return stage;
  }
}

module.exports = AnalyticsService;
```

### Report Export Service (CSV + PDF)

```javascript
// Backend: services/report-export.service.js
const csv = require('csv-stringify/sync');
const PDFDocument = require('pdfkit');
const CrimeReport = require('../models/CrimeReport');

class ReportExportService {
  // Generate CSV export
  static async generateCSV(filters = {}) {
    const reports = await CrimeReport.find(this.buildFilter(filters))
      .sort({ createdAt: -1 })
      .limit(10000);

    const records = reports.map(r => ({
      'Report ID': r.reportId,
      'Crime Type': r.crimeType,
      'Status': r.status,
      'Risk Level': r.riskLevel,
      'Date/Time': r.incidentDateTime?.toISOString(),
      'Location': r.location.address || 'N/A',
      'Description': r.description?.substring(0, 200),
      'Reporter': r.isAnonymous ? 'Anonymous' : r.reporterId?.fullName || 'Unknown',
      'Verified By': r.verifiedBy ? 'Yes' : 'No',
      'Created At': r.createdAt?.toISOString()
    }));

    return csv.stringify(records, { header: true });
  }

  // Generate PDF analytics report
  static async generatePDF(filters = {}) {
    const doc = new PDFDocument({ margin: 50 });
    const chunks = [];

    doc.on('data', chunk => chunks.push(chunk));

    // Title
    doc.fontSize(24).fillColor('#1E293B').text('Sentinel NG — Crime Analytics Report', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).fillColor('#64748B')
       .text(`Generated: ${new Date().toLocaleString()} | Period: ${filters.dateFrom || 'All'} to ${filters.dateTo || 'Present'}`, { align: 'center' });
    doc.moveDown();

    // Summary stats
    const stats = await AnalyticsService.getOverviewStats(filters);
    doc.fontSize(16).fillColor('#006400').text('Summary Statistics', { underline: true });
    doc.moveDown(0.5);
    doc.fontSize(12).fillColor('#1E293B')
       .text(`Total Reports: ${stats.totalReports}`)
       .text(`Verified: ${stats.verifiedCount}`)
       .text(`Pending Review: ${stats.pendingCount}`)
       .text(`High Risk: ${stats.highRiskCount}`);
    doc.moveDown();

    // Crime type breakdown
    const types = await AnalyticsService.getCrimeTypeDistribution(filters);
    if (types.length > 0) {
      doc.fontSize(16).fillColor('#006400').text('Crime Type Distribution', { underline: true });
      doc.moveDown(0.5);
      types.forEach(t => {
        doc.fontSize(12).fillColor('#1E293B')
           .text(`${this.formatCrimeType(t._id)}: ${t.count} (${((t.count / stats.totalReports) * 100).toFixed(1)}%)`);
      });
    }

    // Hotspot summary
    const hotspots = await AnalyticsService.getHotspotData(filters);
    if (hotspots.length > 0) {
      doc.moveDown();
      doc.fontSize(16).fillColor('#006400').text('Top Crime Hotspots', { underline: true });
      doc.moveDown(0.5);
      hotspots.forEach((h, i) => {
        doc.fontSize(12).fillColor('#1E293B')
           .text(`${i + 1}. ${h._id} — ${h.count} incidents`);
      });
    }

    doc.end();

    return new Promise((resolve) => {
      doc.on('end', () => resolve(Buffer.concat(chunks)));
    });
  }

  static formatCrimeType(type) {
    return type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }
}

module.exports = ReportExportService;
```

---

## 6. 📐 Admin API Integration Reference (Expanded)

### Authentication & Session Management

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/auth/admin-login` | Admin login with enhanced security | `{ email, password }` | `{ token, adminProfile }` |
| POST | `/api/auth/admin-verify-session` | Verify session validity (for SPA) | Header: `Authorization: Bearer <token>` | `{ valid: true, role: 'admin' }` |
| POST | `/api/auth/admin-refresh` | Refresh JWT token | `{ refreshToken }` | `{ token }` |

### Report Verification Endpoints

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/reports/pending` | Get reports awaiting review | Query: `?page=1&limit=20&status=pending` | `{ reports: [...], total, page }` |
| GET | `/api/admin/reports/by-status` | Filter by status | Query: `?status=verified&dateFrom=...` | `{ reports: [...] }` |
| PUT | `/api/crimes/:id/verify` | Approve a report | `{ adminNotes?: string }` | `{ success, report }` |
| PUT | `/api/crimes/:id/dismiss` | Reject a report | `{ reason: string, adminNotes?: string }` | `{ success, report }` |
| PUT | `/api/crimes/:id/review-start` | Mark as under review | `{}` | `{ success, report }` |
| PUT | `/api/crimes/:id/risk-level` | Assign risk level | `{ riskLevel: 'high' \| 'medium' \| 'low', reason?: string }` | `{ success, report }` |
| PUT | `/api/crimes/:id/admin-notes` | Add internal notes | `{ notes: string }` | `{ success, report }` |

### Analytics Endpoints (Detailed)

| Method | Endpoint | Description | Query Params | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/analytics/overview` | Dashboard overview stats | `?dateFrom=...&dateTo=...` | `{ totalReports, verifiedCount, pendingCount, highRiskCount }` |
| GET | `/api/admin/analytics/crime-types` | Crime type distribution | `?dateFrom=...&dateTo=...` | `[{ crimeType, count }]` |
| GET | `/api/admin/analytics/trends/daily` | Daily trend data | `?month=2024-01` | `[{ date, count }]` |
| GET | `/api/admin/analytics/trends/weekly` | Weekly trend data | `?year=2024` | `[{ week, count }]` |
| GET | `/api/admin/analytics/trends/monthly` | Monthly trend data | `?range=1y` (last 1 year) | `[{ month, count }]` |
| GET | `/api/admin/analytics/hotspots` | Top crime hotspots | `?radius=50000` | `[{ address, count, coordinates }]` |
| GET | `/api/admin/analytics/risk-distribution` | Risk level over time | `?period=monthly` | `[{ period, high, medium, low }]` |
| GET | `/api/admin/analytics/verification-efficiency` | Admin performance metrics | `?adminId=...` | `{ avgReviewTime, verificationRate, dismissalRate }` |

### SOS Dispatch Endpoints (Detailed)

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/dispatch/active-sos` | List all active SOS alerts | Query: `?status=triggered\|en_route` | `{ alerts: [...] }` |
| GET | `/api/admin/dispatch/sos/:alertId` | Get full SOS alert detail | — | `{ sosAlert, reporterLocation, responderInfo }` |
| PUT | `/api/admin/dispatch/sos/acknowledge` | Acknowledge an SOS alert | `{ sosAlertId, responderId }` | `{ success, sosAlert }` |
| PUT | `/api/admin/dispatch/sos/update-status` | Update SOS status | `{ sosAlertId, status: 'en_route'\|'on_scene'\|'resolved' }` | `{ success, sosAlert }` |

### User Management Endpoints (Detailed)

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/users` | List all users | Query: `?page=1&limit=20&search=john` | `{ users: [...], total, page }` |
| GET | `/api/admin/users/:id` | Get user details + history | — | `{ user, reportHistory, safetyScore }` |
| PUT | `/api/admin/users/:id/ban` | Suspend a user | `{ reason: string }` | `{ success, user }` |
| PUT | `/api/admin/users/:id/unban` | Reactivate a user | `{}` | `{ success, user }` |

### Broadcast Alert Endpoints (Detailed)

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/admin/broadcast/create` | Create & send broadcast | `{ title, message, targetAudience, priority, regionFilter? }` | `{ success, broadcastId }` |
| GET | `/api/admin/broadcasts` | List all broadcasts | Query: `?isActive=true` | `{ broadcasts: [...] }` |
| PUT | `/api/admin/broadcasts/:id/deactivate` | Deactivate a broadcast | `{}` | `{ success }` |

### Export Endpoints (Detailed)

| Method | Endpoint | Description | Query Params | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/admin/reports/export/csv` | Download CSV export | `?dateFrom=...&dateTo=...&status=verified` | File download (CSV) |
| POST | `/api/admin/reports/export/pdf` | Generate PDF report | `{ dateFrom, dateTo, includeCharts: true }` | File download (PDF) |

---

## 7. 🏆 Admin Portal Best Practices

### Security Considerations

1. **Role-Based Access Control (RBAC)** — Only users with `role: 'admin'` can access admin endpoints
2. **Session Management** — JWT tokens with short expiry (15 min) + refresh token rotation
3. **Audit Logging** — Log every admin action (who verified what, when, and why) in a separate `audit_logs` collection
4. **IP Whitelisting** (Optional) — Restrict admin access to known office IPs for production deployment
5. **Two-Factor Authentication** — Optional TOTP integration for high-security deployments

### Performance Optimization

1. **Server-Side Pagination** — Never load all reports at once; use cursor-based pagination
2. **Analytics Caching** — Cache aggregated analytics data (Redis) with 5-minute TTL to avoid heavy MongoDB aggregation on every request
3. **WebSocket for SOS Only** — Use real-time WebSocket only for active SOS alerts; REST for everything else
4. **Lazy Loading Charts** — Load chart data on tab switch, not on initial page load

### UX Best Practices

1. **Keyboard Shortcuts** — `Ctrl+K` for quick search, `Esc` to close modals, arrow keys for table navigation
2. **Bulk Actions** — Select multiple reports → bulk verify / bulk risk-tag
3. **Undo Last Action** — Allow undo within 5 seconds of verification/risk assignment
4. **Toast Notifications** — Non-intrusive success/error feedback for all actions
5. **Dark Mode Toggle** — For night-shift admin operators

---

## 8. 📋 Admin Development Phases (Standalone)

### Phase A: Foundation (Days 1–2)
- [ ] Set up React/Vue.js project with Tailwind CSS
- [ ] Configure routing, layout shell (sidebar + topbar), auth guard
- [ ] Build AdminLogin screen with session management
- [ ] Connect to backend API (Axios instance with interceptors)

### Phase B: Dashboard & Report Management (Days 3–5)
- [ ] Build AdminDashboard overview with stat cards
- [ ] Implement ReportReviewList with pagination, filters, search
- [ ] Build ReportDetailReview with evidence gallery and map embed
- [ ] Implement VerificationDecision modal (approve/reject with reason)

### Phase C: Risk Tagging & User Management (Days 6–7)
- [ ] Build RiskTaggingPanel with inline assignment + bulk option
- [ ] Create UserManagementList table with search/filter
- [ ] Implement UserProfileDetail and BanSuspendPanel

### Phase D: Analytics Dashboard (Days 8–10)
- [ ] Set up charting library (Recharts / Chart.js)
- [ ] Build AnalyticsDashboard with tabbed views
- [ ] Implement CrimeTypeDistribution pie chart
- [ ] Implement TemporalTrends line charts (daily/weekly/monthly tabs)
- [ ] Build HotspotMap with intensity circles using Leaflet

### Phase E: Emergency Dispatch & Polish (Days 11–13)
- [ ] Integrate Socket.io for real-time SOS alerts
- [ ] Build ActiveSOSAlerts list + SOSAlertDetail view
- [ ] Implement ResponderAssignment and DispatchStatusBoard (Kanban)
- [ ] Add BroadcastAlertPanel for push notification creation
- [ ] Implement ReportExportCenter with CSV/PDF generation

### Phase F: Content Management & Settings (Days 14–15)
- [ ] Build CrimeClassificationManager CRUD interface
- [ ] Create AdminSettings page
- [ ] Add keyboard shortcuts, toast notifications, undo actions
- [ ] Dark mode toggle implementation

---

## 9. 📦 Recommended Web Admin Packages

### React + Tailwind CSS Stack

| Purpose | Package | Note |
|---------|---------|------|
| Framework | `react@18` + `vite` | Fast dev server, optimized builds |
| Styling | `tailwindcss@3` + `@headlessui/react` | Utility CSS + accessible components |
| State Management | `zustand` | Lightweight, no boilerplate |
| Routing | `react-router-dom@6` | Declarative routing with guards |
| HTTP Client | `axios` | Interceptors for auth tokens |
| Charts | `recharts` or `chart.js` + `react-chartjs-2` | Beautiful, responsive charts |
| Maps | `leaflet` + `react-leaflet` | Interactive maps with heatmap plugin |
| Data Tables | `@tanstack/react-table` | Headless, highly customizable tables |
| Real-Time | `socket.io-client` | WebSocket for SOS alerts |
| Icons | `lucide-react` | Clean, consistent icon set |
| PDF Generation (Client) | `jspdf` + `jspdf-autotable` | Client-side PDF reports |
| Date Handling | `date-fns` | Lightweight date utilities |
| Form Management | `react-hook-form` + `zod` | Performant forms with validation |

### Alternative: Vue.js + Tailwind CSS Stack

| Purpose | Package | Note |
|---------|---------|------|
| Framework | `vue@3` + `vite` | Composition API, reactive |
| Styling | `tailwindcss@3` + `unplugin-icons` | Utility CSS + auto-imported icons |
| State Management | `pinia` | Official Vue state management |
| Routing | `vue-router@4` | Vue's official router |
| HTTP Client | `axios` | Same as React stack |
| Charts | `chart.js` + `vue-chartjs` | Chart rendering for Vue |
| Maps | `leaflet` + `@vue-leaflet/vue-leaflet` | Leaflet wrapper for Vue |
| Data Tables | `vuetify-data-tables` or `primevue/datatable` | Feature-rich table components |
| Real-Time | `socket.io-client` | Same as React stack |
| Icons | `@iconify/vue` | 100K+ icons available |

---

## 10. 🎯 Admin Portal Key Differentiators for Judges

1. **Complete TOR Compliance** — Every TOR requirement has a corresponding screen and API endpoint
2. **Real-Time SOS Dispatch Board** — Kanban-style emergency response tracking (rare in student projects)
3. **Multi-Format Report Export** — CSV, JSON, and PDF analytics reports with one click
4. **Risk Tagging Workflow** — Structured risk assessment process with audit trail
5. **Broadcast Alert System** — Admin can push targeted notifications to user base
6. **Verification Audit Trail** — Every admin action is logged with timestamp and reason
7. **Dual-Platform Architecture** — Mobile app for citizens + Web portal for agencies (full ecosystem)

---

*Document created as TOR gap-fill supplement.*
*Tech Stack: React/Vue.js · Tailwind CSS · Node.js + Express API · MongoDB*
*Total Admin Screens: 27 (including sub-panels and modals)*
*Companion Document: [RECOMMENDATIONS.md](./RECOMMENDATIONS.md) — Mobile app architecture*
