import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/utils/safety_score.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../data/models/crime_report_model.dart';
import '../../../data/models/notification_model.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Default map center (Lagos, Nigeria) used when geolocation is unavailable.
const double _defaultLat = 6.5244;
const double _defaultLng = 3.3792;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const CrimeMapPage(),
    const SizedBox.shrink(), // FAB placeholder
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != 2) {
              // Skip FAB position
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''), // Spacer for FAB
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SOS button (top)
        FloatingActionButton.extended(
          onPressed: () => context.push('/sos-emergency'),
          backgroundColor: AppColors.alertRed,
          elevation: 4,
          icon: const Icon(Icons.warning_amber_rounded, size: 20),
          label: const Text('SOS', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 16),
        // Main FAB (center) - Report Crime
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showReportingMenu(context),
            backgroundColor: AppColors.primaryGreen,
            elevation: 6,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
      ],
    );
  }

  void _showReportingMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('What would you like to do?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _menuOption(Icons.report_problem, 'Report a Crime', AppColors.alertRed, () {
              Navigator.pop(context);
              context.push('/reporting-wizard');
            }),
            _menuOption(Icons.route, 'Safe Route Planner', AppColors.primaryGreen, () {
              Navigator.pop(context);
              context.push('/safe-route');
            }),
            _menuOption(Icons.local_police, 'Find Safe Places', Colors.blue.shade700, () {
              Navigator.pop(context);
              context.push('/safe-places');
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

/// Best-effort current position; falls back to Lagos when unavailable.
Future<Position> _resolveUserPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('location services disabled');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('location permission denied');
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 10)),
    );
  } catch (_) {
    return Position(latitude: _defaultLat, longitude: _defaultLng, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0);
  }
}

/// Home Dashboard - dynamic greeting, live safety score and recent alerts.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _offlineNote; // non-null when showing fallback sample data
  SafetyScore _score = const SafetyScore(score: 75, label: 'Safe', fromLiveData: false);
  List<int> _weeklyCounts = List.filled(7, 0);
  int _reportsThisWeek = 0;
  int _reportsLastWeek = 0;
  List<CrimeReportModel> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final position = await _resolveUserPosition();
      final response = await _api.getReports(
        nearLat: position.latitude,
        nearLng: position.longitude,
        radiusKm: 5,
        limit: 100,
      );
      if (!mounted) return;

      final reportsResponse = ReportsResponse.fromJson(response);
      final allReports = [...reportsResponse.verified];
      _recentReports = allReports
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _score = SafetyScore.compute(
          allReports,
          communityAlerts: reportsResponse.communityAlerts,
          centerLat: position.latitude,
          centerLng: position.longitude,
          radiusKm: 5,
        );
        _weeklyCounts = dailyReportCounts(allReports, days: 7);
        final now = DateTime.now();
        _reportsThisWeek = allReports.where((r) => now.difference(r.createdAt).inDays < 7).length;
        _reportsLastWeek = allReports
            .where((r) {
              final d = now.difference(r.createdAt).inDays;
              return d >= 7 && d < 14;
            })
            .length;
        _offlineNote = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Offline / API failure: show clearly-labeled sample data.
      setState(() {
        _score = const SafetyScore(score: 75, label: 'Safe', fromLiveData: false);
        _weeklyCounts = [1, 0, 2, 1, 3, 0, 1];
        _reportsThisWeek = 8;
        _reportsLastWeek = 9;
        _recentReports = const [];
        _offlineNote = 'Live data unavailable — showing sample alerts.';
        _loading = false;
      });
    }
  }

  String get _greetingName {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.name.isNotEmpty) {
      return authState.user.name.trim().split(RegExp(r'\s+')).first;
    }
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _greetingName;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hello, $firstName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Stay safe, stay informed.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_offlineNote != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_offlineNote!, style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
                  ]),
                ),
              ],

              // Safety Score Card - Green gradient matching design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF81C784), const Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('Your Safety Score', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)))),
                          if (!_score.fromLiveData)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text('Sample', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.9))),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          // Circular gauge
                          SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
                            SizedBox(width: 100, height: 100, child: CircularProgressIndicator(
                              value: _score.score / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('$_scoreScore', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(_score.label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                            ]),
                          ])),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(_reportsThisWeek <= _reportsLastWeek ? Icons.trending_down : Icons.trending_up, size: 18, color: Colors.white),
                              const SizedBox(width: 4),
                              Expanded(child: Text(
                                '$_reportsThisWeek reports nearby this week',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                              )),
                            ]),
                            const SizedBox(height: 16),
                            // Mini bar chart of the last 7 days
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              for (final count in _weeklyCounts)
                                _miniBar(count == 0 ? 0.15 : ((count / _maxWeeklyCount) * 0.9 + 0.1)),
                            ]),
                          ])),
                        ]),
                      ]),
              ),

              const SizedBox(height: 24),

              // Quick Actions - 4 cards in a row
              Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _quickActionCard(Icons.report_problem, 'Report\nCrime', AppColors.alertRed, () => context.push('/reporting-wizard')),
                _quickActionCard(Icons.location_on, 'SOS', Colors.red.shade700, () => context.push('/sos-emergency')),
                _quickActionCard(Icons.map_outlined, 'Safe\nRoute', AppColors.primaryGreen, () => context.push('/safe-route')),
                _quickActionCard(Icons.chat_bubble_outline, 'AI\nAssistant', Colors.blue.shade700, () => context.push('/ai-assistant')),
              ]),

              const SizedBox(height: 24),

              // Recent Alerts (live from GET /api/reports)
              Row(children: [
                Expanded(child: Text('Recent Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: Colors.grey[500]),
                  onPressed: _loading ? null : _loadDashboardData,
                ),
              ]),
              const SizedBox(height: 16),

              if (_recentReports.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline, size: 40, color: AppColors.primaryGreen.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text(_offlineNote != null ? 'No sample alerts' : 'No recent incidents nearby', style: TextStyle(color: Colors.grey[600])),
                  ]),
                )
              else
                for (final report in _recentReports.take(3)) ...[
                  _alertCard(report, isSample: false),
                  const SizedBox(height: 12),
                ],

              if (_offlineNote != null && _recentReports.isEmpty) ...[
                _sampleAlertCard('Armed Robbery', 'Ikeja, Lagos', '10 min ago', AppColors.alertRed),
                const SizedBox(height: 12),
                _sampleAlertCard('Theft', 'Yaba, Lagos', '25 min ago', Colors.blue.shade800),
              ],

              const SizedBox(height: 32), // Bottom padding for FAB
            ])),
          ),
      ],
    );
  }

  int get _scoreScore => _score.score;

  int get _maxWeeklyCount {
    var max = 1;
    for (final v in _weeklyCounts) {
      if (v > max) max = v;
    }
    return max;
  }

  Widget _miniBar(double height) {
    return Container(
      width: 8,
      height: (40 * height).clamp(6.0, 40.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _quickActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _alertCard(CrimeReportModel report, {required bool isSample}) {
    final color = AppColors.getCrimeTypeColor(report.type);
    return InkWell(
      onTap: () => context.push('/crime-detail', extra: report.toJson()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          // Colored circle with initial
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(report.type.isNotEmpty ? report.type[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text(
              report.description.isNotEmpty ? (report.description.length > 40 ? '${report.description.substring(0, 40)}…' : report.description) : 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(timeAgo(report.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            if (report.riskLevel == 'HIGH')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.alertRed.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('HIGH RISK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.alertRed)),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _sampleAlertCard(String title, String location, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(title.isNotEmpty ? title[0] : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Text('SAMPLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            ),
          ]),
          Text(location, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
        Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}

/// Crime Map Page - real OSM map with verified reports + community alerts.
class CrimeMapPage extends StatefulWidget {
  const CrimeMapPage({super.key});

  @override
  State<CrimeMapPage> createState() => _CrimeMapPageState();
}

class _CrimeMapPageState extends State<CrimeMapPage> {
  final ApiService _api = ApiService();
  final OSMMapController _mapController = OSMMapController();

  bool _loading = true;
  String? _error;
  double _centerLat = _defaultLat;
  double _centerLng = _defaultLng;
  Position? _userPosition;

  List<CrimeReportModel> _reports = [];
  List<CommunityAlertModel> _communityAlerts = [];
  String _filter = 'All'; // 'All' | crime type | '__alerts__'

  static const String _alertsFilterKey = '__alerts__';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMapData({double? centerLat, double? centerLng}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lat = centerLat ?? _centerLat;
      final lng = centerLng ?? _centerLng;

      if (_userPosition == null) {
        _userPosition = await _resolveUserPosition();
      }

      final response = await _api.getReports(
        nearLat: lat,
        nearLng: lng,
        radiusKm: 100,
        limit: 100,
      );
      if (!mounted) return;

      final parsed = ReportsResponse.fromJson(response);
      setState(() {
        _reports = parsed.verified;
        _communityAlerts = parsed.communityAlerts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load map data. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  List<String> get _availableTypes {
    final types = <String>{};
    for (final r in _reports) {
      if (r.type.isNotEmpty) types.add(r.type);
    }
    return types.toList()..sort();
  }

  bool _matchesFilter(CrimeReportModel report, {bool isAlert = false}) {
    if (_filter == 'All') return true;
    if (_filter == _alertsFilterKey) return isAlert;
    return !isAlert && report.type == _filter;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <MapMarker>[
      for (final r in _reports)
        if (_matchesFilter(r))
          MapMarker(
            lat: _latOf(r.location),
            lng: _lngOf(r.location),
            color: AppColors.getRiskLevelColor(r.riskLevel),
            icon: Icons.warning_amber_rounded,
            onTap: () => _showReportSheet(r),
          ),
      for (final a in _communityAlerts)
        if (_filter == 'All' || _filter == _alertsFilterKey)
          MapMarker(
            lat: _latOf(a.location),
            lng: _lngOf(a.location),
            color: Colors.orange.shade700,
            icon: Icons.groups,
            onTap: () => _showCommunityAlertSheet(a),
          ),
    ];

    return Stack(children: [
      OSMMapWidget(
        lat: _centerLat,
        lng: _centerLng,
        initialZoom: 12,
        controller: _mapController,
        markers: markers,
        userLocation: _userPosition != null ? LatLngPoint(_userPosition!.latitude, _userPosition!.longitude) : null,
      ),

      // Filter bar at top
      Positioned(top: 8, left: 16, right: 16, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _filterChip('All', 'All'),
          for (final type in _availableTypes) ...[
            const SizedBox(width: 8),
            _filterChip(type, type),
          ],
          if (_communityAlerts.isNotEmpty) ...[
            const SizedBox(width: 8),
            _filterChip('Community Alerts', _alertsFilterKey),
          ],
        ])),
      )),

      // Loading / error overlays
      if (_loading)
        Positioned.fill(child: Container(
          color: Colors.white.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()),
        )),
      if (!_loading && _error != null)
        Positioned(top: 64, left: 16, right: 16, child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade300)),
          child: Row(children: [
            Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade900))),
            IconButton(icon: Icon(Icons.refresh, size: 16, color: Colors.red.shade700), onPressed: () => _loadMapData()),
          ]),
        )),

      // Map legend at bottom
      Positioned(bottom: 12, left: 16, child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _legendItem(AppColors.alertRed, 'High Risk'),
          _legendItem(Colors.orange.shade700, 'Medium Risk / Community Alert'),
          _legendItem(AppColors.successGreen, 'Low Risk'),
        ]),
      )),

      // Count badge
      if (!_loading)
        Positioned(top: 64, right: 16, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
          child: Text('${markers.length} shown', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        )),
    ]);
  }

  double _latOf(Map<String, dynamic> location) {
    final coords = location['coordinates'];
    if (coords is List<dynamic> && coords.length == 2) return (coords[1] as num).toDouble();
    return _defaultLat;
  }

  double _lngOf(Map<String, dynamic> location) {
    final coords = location['coordinates'];
    if (coords is List<dynamic> && coords.length == 2) return (coords[0] as num).toDouble();
    return _defaultLng;
  }

  Widget _filterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12)),
    ]));
  }

  void _showReportSheet(CrimeReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(report.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.getStatusColor(report.status).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(report.statusDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getStatusColor(report.status))),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.getRiskLevelColor(report.riskLevel)),
              const SizedBox(width: 4),
              Text('${report.riskLevelDisplay} · ${timeAgo(report.createdAt)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ]),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(report.description, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/crime-detail', extra: report.toJson());
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Full Details'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showCommunityAlertSheet(CommunityAlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.groups, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text('Community Alert', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text('${alert.reportCount} report(s) of ${alert.type} in this area · ${timeAgo(alert.createdAt)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            if (alert.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(alert.description, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Notifications Page - dynamic alerts from /api/notifications with category tabs.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  bool _offline = false;
  List<NotificationModel> _notifications = [];
  String _tab = 'All'; // All | Alerts | Updates | System

  static const List<String> _tabs = ['All', 'Alerts', 'Updates', 'System'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final response = await _api.getNotifications(limit: 50);
      if (!mounted) return;
      final list = (response['notifications'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      setState(() {
        _notifications = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _offline = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _offline = true;
        _loading = false;
      });
    }
  }

  List<NotificationModel> get _filtered {
    switch (_tab) {
      case 'Alerts':
        return _notifications.where((n) => n.type == 'HOTSPOT_ALERT' || n.type == 'COMMUNITY_WARNING').toList();
      case 'Updates':
        return _notifications.where((n) => n.type == 'REPORT_STATUS_CHANGE').toList();
      case 'System':
        return _notifications.where((n) => n.type == 'SOS_RESPONSE').toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    setState(() {
      final index = _notifications.indexOf(notification);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: notification.id, userId: notification.userId, title: notification.title, message: notification.message,
          type: notification.type, isRead: true, metadata: notification.metadata, createdAt: notification.createdAt,
        );
      }
    });
    try {
      await _api.markNotificationAsRead(notification.id);
    } catch (_) {
      // Best effort — the item stays visually read for this session.
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = [
        for (final n in _notifications)
          NotificationModel(
            id: n.id, userId: n.userId, title: n.title, message: n.message,
            type: n.type, isRead: true, metadata: n.metadata, createdAt: n.createdAt,
          ),
      ];
    });
    try {
      await _api.markAllNotificationsAsRead();
    } catch (_) {}
  }

  (IconData, Color) _typeStyle(String type) {
    switch (type) {
      case 'HOTSPOT_ALERT':
        return (Icons.warning_amber_rounded, Colors.orange.shade700);
      case 'REPORT_STATUS_CHANGE':
        return (Icons.verified, AppColors.statusVerified);
      case 'COMMUNITY_WARNING':
        return (Icons.groups, Colors.blue.shade700);
      case 'SOS_RESPONSE':
        return (Icons.local_police, AppColors.alertRed);
      default:
        return (Icons.notifications_none, Colors.grey.shade600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(children: [
      // Header with title + mark-all-read
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        child: Row(children: [
          Expanded(child: Text('Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          if (_unreadCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.alertRed.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('$_unreadCount new', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.alertRed)),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'Mark all as read',
            icon: Icon(Icons.done_all_outlined, size: 20, color: _unreadCount > 0 ? AppColors.primaryGreen : Colors.grey[400]),
            onPressed: _unreadCount > 0 ? _markAllAsRead : null,
          ),
        ]),
      ),

      // Category tabs
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final tab in _tabs) ...[
              _categoryTab(tab),
              const SizedBox(width: 8),
            ],
          ]),
        )),
      ),

      // Offline banner when API is unreachable
      if (_offline)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
          child: Row(children: [
            Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(child: Text('Couldn\'t reach the server — showing sample alerts.', style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
          ]),
        ),

      // Notification list
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(_offline ? 'No sample alerts' : 'You\'re all caught up', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ]),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _notificationCard(items[index]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _categoryTab(String label) {
    return FilterChip(
      label: Text(label),
      selected: _tab == label,
      onSelected: (_) => setState(() => _tab = label),
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppColors.primaryGreen,
    );
  }

  Widget _notificationCard(NotificationModel notification) {
    final (icon, color) = _typeStyle(notification.type);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markAsRead(notification),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notification.title, style: TextStyle(fontSize: 14, fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600)),
            const SizedBox(height: 2),
            Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(notification.typeDisplay, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              ),
              const SizedBox(width: 8),
              Text(timeAgo(notification.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ])),
          if (!notification.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.alertRed, shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}

/// Profile Page - dynamic user info from the profile API.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _name;
  String? _email;
  String? _imageUrl;
  DateTime? _memberSince;
  int _reportCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Seed from the auth bloc immediately, then refresh from the API.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _name = authState.user.name.isNotEmpty ? authState.user.name : null;
        _email = authState.user.email.isNotEmpty ? authState.user.email : null;
        _imageUrl = authState.user.image;
      });
    }

    try {
      final response = await _api.getProfile();
      if (!mounted) return;
      final user = response['user'] as Map<String, dynamic>? ?? {};
      setState(() {
        _name = (user['name'] as String?)?.isNotEmpty == true ? user['name'] as String : _name;
        _email = (user['email'] as String?)?.isNotEmpty == true ? user['email'] as String : _email;
        final image = user['image'];
        if (image is String && image.isNotEmpty) {
          _imageUrl = _api.resolveMediaUrl(image);
        }
        final createdAt = user['createdAt'];
        if (createdAt is String) {
          try {
            _memberSince = DateTime.parse(createdAt);
          } catch (_) {}
        }
        final count = user['_count'] as Map<String, dynamic>?;
        _reportCount = (count?['reports'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // Keep the auth-bloc seed values on failure.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your reports and alerts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.pop(dialogContext);
              context.go('/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _name ?? 'Community Member';
    final initials = name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return ListView(children: [
      // Profile header
      Container(padding: const EdgeInsets.all(24), child: Column(children: [
        _loading && _imageUrl == null
            ? const SizedBox(width: 100, height: 100, child: CircularProgressIndicator(strokeWidth: 3))
            : CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                child: _imageUrl == null
                    ? Text(initials.isEmpty ? '?' : initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryGreen))
                    : null,
              ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (_email != null) Text(_email!, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Text('$_reportCount report${_reportCount == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
          ),
          if (_memberSince != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text('Member since ${formatDate(_memberSince!)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          ],
        ]),
      ])),

      const Divider(),

      // Menu items
      _menuTile(Icons.report_problem, 'My Reports', () => context.push('/my-reports')),
      _menuTile(Icons.star, 'Safety Score Details', () => context.push('/safety-score-detail')),
      _menuTile(Icons.notifications, 'Notification Settings', () => context.push('/notification-settings')),
      _menuTile(Icons.phone, 'Emergency Contacts', () => context.push('/emergency-contacts')),
      _menuTile(Icons.bookmark, 'Saved Locations', () => context.push('/saved-locations')),
      _menuTile(Icons.photo_library, 'Media Library', () => context.push('/media-library')),
      _menuTile(Icons.settings, 'Settings', () => context.push('/settings')),

      const Divider(),

      // Logout
      ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)), onTap: () => _logout(context)),
    ]);
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: CircleAvatar(child: Icon(icon, size: 20)), title: Text(label), trailing: Icon(Icons.chevron_right, color: Colors.grey[400]), onTap: onTap);
  }
}
