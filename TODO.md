# Sentinel NG - Development Roadmap

## Phase 1: Architecture & Backend Setup (The Foundation)
- [ ] **Database Schema Design**
    - [ ] User profiles (Auth, roles, safety score metrics).
    - [ ] Incident/Crime reports (Type, location, timestamps, evidence URLs).
    - [ ] Real-time Emergency logs (SOS triggers, responder tracking).
    - [ ] Notifications & Alerts history.
- [ ] **Backend API (Node.js/Express)**
    - [ ] Authentication System (JWT, Google/Apple OAuth).
    - [ ] CRUD for Crime Reports.
    - [ ] Geo-spatial queries (PostGIS or MongoDB GeoJSON) for Map & Heatmaps.
    - [ ] Socket.io integration for real-time SOS/Emergency tracking.
- [ ] **Cloud Infrastructure**
    - [ ] Setup AWS/Firebase for image/video storage.
    - [ ] Setup Push Notification service (FCM).

## Phase 2: Flutter Frontend - Core UI & Navigation
- [ ] **Design System Implementation**
    - [ ] Define Color Palette (Sentinel Green, Dark/Light modes).
    - [ ] Typography & Component Library (Buttons, Cards, Inputs).
- [ ] **Authentication Flow**
    - [ ] Splash $\rightarrow$ Onboarding $\rightarrow$ Login/Register.
- [ ] **Main Shell**
    - [ ] Bottom Navigation Bar implementation.
    - [ ] Home Dashboard UI.

## Phase 3: Feature Implementation - Reporting & Map
- [ ] **Interactive Crime Map**
    - [ ] Integration with Google Maps/Mapbox.
    - [ ] Custom Markers & Cluster implementation.
    - [ ] Heatmap layer implementation.
- [ ] **Multi-step Reporting Flow**
    - [ ] State management for the multi-step form (Riverpod/Bloc).
    - [ ] Image/Video picker integration.
    - [ ] Location picking (GPS + Manual).

## Phase 4: Feature Implementation - Safety & AI
- [ ] **SOS & Live Emergency**
    - [ ] Real-time location streaming (User $\rightarrow$ Server $\rightarrow$ Responder).
    - [ ] "Live Emergency" UI with active tracking.
- [ ] **AI Safe Route Planner**
    - [ ] Integration with Routing API.
    - [ ] Logic to overlay crime density on routes to calculate "Safety Score".
- [ ] **AI Assistant (Chatbot)**
    - [ ] Integration with LLM (OpenAI/Gemini) for voice/text reporting assistance.

## Phase 5: Polish, UX & Advanced Features
- [ ] **Micro-interactions** (Fluid animations for transitions and button presses).
- [ ] **Notification System** (Real-time alerts for nearby crimes).
- [ ] **Profile & History** (Viewing past reports and saved locations).

## Phase 6: Testing & Deployment
- [ ] Unit & Integration testing (Frontend & Backend).
- [ ] Load testing (Simulating high-traffic during emergencies).
- [ ] Final UI/UX Audit.
