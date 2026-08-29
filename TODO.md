# 🔗 Recommendation 4 Implementation — Hybrid Backend + Flutter App

## Phase 1: Backend Changes (Next.js crime-location-reporting-system)
- [x] **Prisma Schema Extension** — Add SosAlert & BroadcastAlert models
- [ ] Run Prisma migration to apply schema changes
- [ ] **CORS Middleware** — src/middleware.ts for Flutter requests
- [ ] **Auth Token Handling** — Support Bearer token in NextAuth v5
- [ ] **New API Route: `/api/admin/broadcast`** — Broadcast alerts (POST/GET)
- [ ] **New API Route: `/api/admin/analytics`** — Analytics aggregation (GET)
- [ ] **New API Route: `/api/admin/dispatch/active`** — SOS dispatch tracking (GET)

## Phase 2: Flutter App Foundation
- [ ] Update pubspec.yaml with all required dependencies
- [ ] Create core constants (colors, strings, routes)
- [ ] Create theme system (light/dark mode)
- [ ] Create reusable widgets (CustomButton, CustomTextField, etc.)
- [ ] Create API client service with Dio + secure storage
- [ ] Create error handling infrastructure

## Phase 3: Flutter Data Layer
- [ ] Create data models (User, CrimeReport, Notification, Evidence, etc.)
- [ ] Create repositories (Auth, Crime, Notification)
- [ ] Create remote data sources
- [ ] Create local storage service

## Phase 4: Flutter Auth Feature
- [ ] Splash screen
- [ ] Onboarding screens (3 pages)
- [ ] Login screen
- [ ] Register screen

## Phase 5: Flutter Core Features
- [ ] Home Dashboard with safety score + quick actions
- [ ] Bottom navigation bar (5 tabs)
- [ ] Crime Map with markers and filters
- [ ] SOS Emergency screen
- [ ] Notifications screen
- [ ] Profile screen

## Phase 6: Flutter Reporting Wizard
- [ ] Multi-step reporting wizard orchestrator
- [ ] Select crime type screen
- [ ] Select location (map) screen
- [ ] Incident description screen
- [ ] Witness information screen
- [ ] Suspect information screen
- [ ] Evidence collection screen
- [ ] Report success screen

## Phase 7: Flutter Additional Features
- [ ] Crime detail screen with status timeline
- [ ] Search screen
- [ ] Safety score detail screen
- [ ] My reports status screen
- [ ] Safe place markers on map
