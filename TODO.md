# Fix Plan — Flutter App (sentinel_ng) + Backend Integration

## Constraints discovered
- **No internet in this sandbox** → cannot add new pub packages. `flutter_map` is NOT in the local pub cache.
  - Solution: build a custom open-source OSM tile map widget (`core/widgets/osm_map.dart`) using existing `cached_network_image` dep (Leaflet-style, no API key/subscription). Works on web + mobile.
- Next.js app is **live on Render** → backend changes must be additive / non-breaking only.
- Local MongoDB running at localhost:27017/crime_reporting (empty) for testing.

## Root cause of web login error
`TypeError: "error": type 'String' is not a subtype of type 'int'` = `ApiService._handleDioError` does
`error.response?.data['error']` when the response body is a **String** (non-JSON, e.g. HTML error page).
Indexing a String with a String key throws exactly this TypeError in Dart.
Also: default base URL `http://10.0.2.2:3000/api` only works on Android emulator — wrong for web.

## Backend changes (minimal, non-breaking) — ✅ DONE & verified via curl against local dev server
- [x] 1. `/api/sos-contacts/route.ts`: `auth()` → `getAuthSession(req)` (GET+POST) so Flutter Bearer tokens work; cookie auth unchanged.
- [x] 2. `/api/sos-contacts/[id]/route.ts`: same for PATCH/DELETE + added PUT alias.
- [x] 3. `/api/reports/[id]` GET: admin → any report; **report owner** → own reports (verified: pending visible to owner, 403 anonymous); anyone else → only VERIFIED/CROWD_REPORTED. PATCH stays admin-only.
- [x] 4. NEW `POST /api/uploads` — multipart upload using existing `src/lib/storage.ts` (`uploadMedia`). Auth via getAuthSession + rate limit + MIME allowlist + 25MB cap. Returns `{url}`. Additive only.
- [x] 5. `proxy.ts`: allow up to 25MB body **only** for `/api/uploads` (videos); keep 1MB everywhere else.

## Flutter changes
- [x] 6. pubspec: remove unused `google_maps_flutter` (needs API key, user forbade Google Maps). No new packages added.
- [x] 7. main.dart: platform-aware default API base URL (web → localhost:3000/api; mobile → 10.0.2.2); keep `--dart-define=API_BASE_URL` override.
- [x] 8. api_service.dart: fix `_handleDioError` non-JSON body crash (the web login bug); add endpoints: notifications (paginated/filtered), mark-all-read, notification preferences GET/PUT, media upload returning url; expose baseUrl for absolute media URLs.
- [x] 9. auth_bloc: register no longer fakes authenticated state when API returns no token → new `AuthRegistered` state ("check your email") then go to login.
- [x] 10. NEW core/widgets/osm_map.dart — OSM tile map widget (pan/zoom, markers, polylines, circles, user location, attribution).
- [x] 11. home_page.dart:
      - Greeting from real profile (remove "Hello, Samuel 👋" + emoji)
      - Safety score computed live from reports near user (fallback state when offline)
      - Recent Alerts dynamic from GET /api/reports (verified + community alerts), fallback sample data labeled as such on API failure
      - Quick actions wired: Report Crime → wizard, SOS → sos page, Safe Route → route screen, AI Assistant → new assistant screen
      - FAB "+" menu: Find Safe Places → new safe places screen
- [x] 12. Map tab: real OSM map showing verified reports + community alerts from backend; working filter chips; marker tap → detail sheet; legend.
- [x] 13. Alerts (Notifications) tab: dynamic from /api/notifications; tabs All/Alerts/Updates/System functional (filter by type); mark read on tap; mark-all-read action; fallback sample list with offline banner when API fails.
- [x] 14. Profile page: dynamic user info (name/email/avatar/member-since/report count) from profile API; working Logout; new menu items: Notification Settings, Media Library, Settings.
- [x] 15. NEW ai_assistant_screen.dart — chat UI, rule-based assistant answering with live report data (area safety summary, recent incidents, tips).
- [x] 16. NEW safe_places_screen.dart — nearby police stations/hospitals/pharmacies via free Nominatim API on OSM map + list; category filters.
- [x] 17. NEW notification_settings_page.dart — GET/PUT /notifications/preferences (toggles + radius).
- [x] 18. NEW settings_page.dart — links to prefs/contacts/media, about, logout.
- [x] 19. NEW media_library_screen.dart — gallery of all evidence media from user's reports (/reports/me → mediaUrls + evidence); full-screen viewer with video playback (video_player). "Add back the media library".
- [x] 20. safety_score_detail_page: dynamic breakdown from real nearby reports (fl_chart already in deps); graceful no-data state.
- [x] 21. saved_locations_page: functional — Hive local storage, add via map tap / current location, delete, show on map.
- [x] 22. reporting_wizard: location step = real map + "Use Current Location" (geolocator) + Nominatim address search; evidence step = photo/video picker with preview grid, upload to /api/uploads on submit → mediaUrls + evidence JSON.
- [x] 23. crime_detail_screen: accept report passed via route extra (instant from map taps), fetch by id otherwise; show media gallery incl. videos.
- [x] 24. report_status_timeline_screen: dynamic timeline built from real report data (createdAt, status, verificationHistory); fallback generic timeline only when fetch fails.
- [x] 25. safe_route_screen: functional — geocode via Nominatim, route geometry via free OSRM public API, draw on OSM map, safety score computed against high-risk reports; graceful fallback to straight line if OSRM unreachable.

## Testing (after implementation)
- [x] 26. `flutter analyze` clean (0 errors, only info-level deprecation warnings).
- [ ] 27. Start Next.js backend locally (pnpm dev), seed test user + verified/pending reports via API, verify all endpoints incl. new /api/uploads and Bearer auth on sos-contacts; confirm web app routes unaffected.
- [ ] 28. Run Flutter web (`flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api`), test with headless Chromium + puppeteer: login (the reported bug), home dynamic data, map markers, alerts tabs, profile, media library, SOS flow.
