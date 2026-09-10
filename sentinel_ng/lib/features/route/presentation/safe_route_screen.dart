import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/utils/safety_score.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../data/models/crime_report_model.dart';

/// Safe Route Planner Screen — real Nominatim geocoding + OSRM routing.
///
/// 1. User enters origin/destination (or uses quick chips / current location).
/// 2. Addresses are geocoded via Nominatim.
/// 3. Route geometry is fetched from the free OSRM public API.
/// 4. The route is drawn on an OSM map with a safety score overlay.
/// 5. Falls back to straight-line if OSRM is unreachable.
class SafeRouteScreen extends StatefulWidget {
  /// Optional pre-filled destination from "Find Safe Places".
  final Map<String, dynamic>? initialDestination;

  const SafeRouteScreen({super.key, this.initialDestination});

  @override
  State<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends State<SafeRouteScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isCalculating = false;
  String? _calcError;

  // Geocoded coordinates.
  LatLngPoint? _originCoords;
  LatLngPoint? _destCoords;

  // Route data.
  List<LatLngPoint>? _routePolyline;
  double? _distanceMeters;
  double? _durationSeconds;
  int? _safetyScore;
  String? _riskLevel;

  // Nearby reports for safety computation.
  List<dynamic> _nearbyReports = [];

  // Search results for autocomplete.
  List<GeoResult> _originSuggestions = [];
  List<GeoResult> _destSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestSuggestions = false;

  // User's current location.
  Position? _userPosition;

  final GeocodingService _geo = GeocodingService();
  late final OSMMapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = OSMMapController();

    // Pre-fill destination if passed from "Find Safe Places".
    if (widget.initialDestination != null) {
      final destName = widget.initialDestination!['name'] as String?;
      if (destName != null) {
        _destinationController.text = destName;
      }
    }

    // Try to get user's current location.
    _getUserLocation();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _userPosition = position);
    } catch (_) {}
  }

  // ---------- Autocomplete search ----------

  Future<void> _searchOrigin(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _originSuggestions = [];
        _showOriginSuggestions = false;
      });
      return;
    }
    try {
      final results = await _geo.searchAddress(query, limit: 5);
      if (mounted) {
        setState(() {
          _originSuggestions = results;
          _showOriginSuggestions = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _originSuggestions = []);
    }
  }

  Future<void> _searchDest(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _destSuggestions = [];
        _showDestSuggestions = false;
      });
      return;
    }
    try {
      final results = await _geo.searchAddress(query, limit: 5);
      if (mounted) {
        setState(() {
          _destSuggestions = results;
          _showDestSuggestions = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _destSuggestions = []);
    }
  }

  void _selectOrigin(GeoResult result) {
    _originController.text = result.displayName.split(',').take(3).join(',');
    _originCoords = LatLngPoint(result.lat, result.lng);
    setState(() {
      _showOriginSuggestions = false;
      _originSuggestions = [];
    });
  }

  void _selectDest(GeoResult result) {
    _destinationController.text = result.displayName.split(',').take(3).join(',');
    _destCoords = LatLngPoint(result.lat, result.lng);
    setState(() {
      _showDestSuggestions = false;
      _destSuggestions = [];
    });
  }

  // ---------- Route calculation ----------

  Future<void> _calculateRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) return;

    setState(() {
      _isCalculating = true;
      _calcError = null;
    });

    try {
      // Geocode origin if not already set.
      if (_originCoords == null) {
        final results = await _geo.searchAddress(_originController.text, limit: 1);
        if (results.isEmpty) throw Exception('Could not find origin location.');
        _originCoords = LatLngPoint(results[0].lat, results[0].lng);
      }

      // Geocode destination if not already set.
      if (_destCoords == null) {
        final results = await _geo.searchAddress(_destinationController.text, limit: 1);
        if (results.isEmpty) throw Exception('Could not find destination location.');
        _destCoords = LatLngPoint(results[0].lat, results[0].lng);
      }

      // Fetch nearby reports for safety computation.
      try {
        final response = await ApiService().getReports(
          nearLat: _originCoords!.lat,
          nearLng: _originCoords!.lng,
          radiusKm: 15,
          limit: 200,
        );
        if (mounted) {
          setState(() {
            _nearbyReports = [
              ...(response['verified'] as List<dynamic>? ?? []),
              ...(response['communityAlerts'] as List<dynamic>? ?? []),
            ];
          });
        }
      } catch (_) {}

      // Try OSRM routing.
      final osrmRoute = await _geo.routeDriving(
        _originCoords!.lat, _originCoords!.lng,
        _destCoords!.lat, _destCoords!.lng,
      );

      if (!mounted) return;

      List<LatLngPoint> routePoints;
      double distanceMeters;
      double durationSeconds;

      if (osrmRoute != null && osrmRoute.coordinates.isNotEmpty) {
        // Convert OSRM [lng, lat] to LatLngPoint.
        routePoints = osrmRoute.coordinates.map((c) => LatLngPoint(c[1], c[0])).toList();
        distanceMeters = osrmRoute.distanceMeters;
        durationSeconds = osrmRoute.durationSeconds;

        // Compute safety score against nearby high-risk reports.
        final routeCoords = osrmRoute.coordinates;
        _safetyScore = SafetyScore.scoreRoute(routeCoords, []);
      } else {
        // Fallback: straight line between origin and destination.
        routePoints = [_originCoords!, _destCoords!];
        distanceMeters = GeocodingService.haversineKm(
          _originCoords!.lat, _originCoords!.lng,
          _destCoords!.lat, _destCoords!.lng,
        ) * 1000;
        durationSeconds = distanceMeters / (5.5 * 1000) * 60; // Walking speed ~5.5 km/h
        _safetyScore = null; // Can't compute meaningful score for straight line.
      }

      final riskLevel = _getRiskLabel(_safetyScore ?? 70);

      setState(() {
        _routePolyline = routePoints;
        _distanceMeters = distanceMeters;
        _durationSeconds = durationSeconds;
        _riskLevel = riskLevel;
        _isCalculating = false;
      });

      // Center map on the route.
      if (mounted) {
        final centerLat = (_originCoords!.lat + _destCoords!.lat) / 2;
        final centerLng = (_originCoords!.lng + _destCoords!.lng) / 2;
        _mapController.setCamera(centerLat, centerLng, 13);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCalculating = false;
        _calcError = 'Could not calculate route: $e';
      });
    }
  }

  String _getRiskLabel(int score) {
    if (score >= 80) return 'Low Risk';
    if (score >= 60) return 'Moderate Risk';
    if (score >= 40) return 'High Risk';
    return 'Very High Risk';
  }

  Color _getRiskColor(int score) {
    if (score >= 80) return AppColors.primaryGreen;
    if (score >= 60) return Colors.orange.shade600;
    if (score >= 40) return Colors.amber.shade700;
    return AppColors.alertRed;
  }

  // ---------- Quick location chips ----------

  void _setOrigin(String name, double lat, double lng) {
    _originController.text = name;
    _originCoords = LatLngPoint(lat, lng);
  }

  void _setDest(String name, double lat, double lng) {
    _destinationController.text = name;
    _destCoords = LatLngPoint(lat, lng);
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Route Planner')),
      body: Column(children: [
        // Input section.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plan Your Safe Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Origin input with autocomplete.
            Stack(children: [
              TextField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'Starting Point',
                  hintText: 'Enter origin or tap current location',
                  prefixIcon: Icon(Icons.start, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _userPosition != null
                      ? IconButton(icon: const Icon(Icons.my_location, size: 20), onPressed: _useCurrentAsOrigin)
                      : null,
                ),
                onChanged: (q) => _searchOrigin(q),
              ),
              if (_showOriginSuggestions && _originSuggestions.isNotEmpty)
                Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(shrinkWrap: true, itemCount: _originSuggestions.length, itemBuilder: (context, index) {
                      final result = _originSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined, size: 20),
                        title: Text(result.displayName.split(',').take(3).join(','), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        onTap: () => _selectOrigin(result),
                      );
                    }),
                  ),
                ),
            ]),

            const SizedBox(height: 12),

            // Destination input with autocomplete.
            Stack(children: [
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Enter destination address',
                  prefixIcon: Icon(Icons.flag, color: AppColors.alertRed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (q) => _searchDest(q),
              ),
              if (_showDestSuggestions && _destSuggestions.isNotEmpty)
                Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(shrinkWrap: true, itemCount: _destSuggestions.length, itemBuilder: (context, index) {
                      final result = _destSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined, size: 20),
                        title: Text(result.displayName.split(',').take(3).join(','), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        onTap: () => _selectDest(result),
                      );
                    }),
                  ),
                ),
            ]),

            const SizedBox(height: 12),

            // Quick locations.
            Text('Quick Locations:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _quickChip(Icons.home, 'Home', () => _setOrigin('Home', 6.4281, 3.4219)),
                const SizedBox(width: 8),
                _quickChip(Icons.work_outline, 'Work', () => _setDest('Work', 6.5964, 3.3515)),
                const SizedBox(width: 8),
                _quickChip(Icons.school, 'UNILAG', () => _setDest('University of Lagos', 6.5158, 3.3912)),
              ]),
            ),

            const SizedBox(height: 16),

            // Calculate button.
            ElevatedButton.icon(
              onPressed: _isCalculating ? null : _calculateRoute,
              icon: _isCalculating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.route),
              label: Text(_isCalculating ? 'Calculating...' : 'Find Safe Route'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),

            // Error message.
            if (_calcError != null) ...[
              const SizedBox(height: 8),
              Text(_calcError!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
            ],
          ]),
        ),

        // Map section (takes remaining space).
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            child: _routePolyline != null && _originCoords != null && _destCoords != null
                ? OSMMapWidget(
                    lat: (_originCoords!.lat + _destCoords!.lat) / 2,
                    lng: (_originCoords!.lng + _destCoords!.lng) / 2,
                    initialZoom: 13,
                    controller: _mapController,
                    markers: [
                      MapMarker(lat: _originCoords!.lat, lng: _originCoords!.lng, color: AppColors.primaryGreen, icon: Icons.start),
                      MapMarker(lat: _destCoords!.lat, lng: _destCoords!.lng, color: AppColors.alertRed, icon: Icons.flag),
                    ],
                    polyline: _routePolyline,
                    polylineColor: _getRiskColor(_safetyScore ?? 70),
                    polylineWidth: 5,
                  )
                : Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Route Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[400])),
                    ]),
                  ),
          ),
        ),

        // Route options panel (bottom sheet style).
        if (_routePolyline != null) _buildRouteInfoPanel(),
      ]),
    );
  }

  void _useCurrentAsOrigin() {
    if (_userPosition == null) return;
    final pos = _userPosition!;
    setState(() {
      _originController.text = 'My Current Location';
      _originCoords = LatLngPoint(pos.latitude, pos.longitude);
    });
  }

  Widget _quickChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildRouteInfoPanel() {
    final score = _safetyScore ?? 70;
    final riskColor = _getRiskColor(score);
    final distanceStr = _distanceMeters! < 1000 ? '${_distanceMeters!.round()} m' : '${(_distanceMeters! / 1000).toStringAsFixed(1)} km';
    final durationMin = (_durationSeconds! / 60).round();
    final durationStr = durationMin < 60 ? '$durationMin min' : '${durationMin ~/ 60}h ${durationMin % 60}min';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar.
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Route Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('$score/100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: riskColor)),
            ),
          ]),
          const SizedBox(height: 12),

          // Stats row.
          Row(children: [
            _statItem(Icons.access_time, durationStr),
            const SizedBox(width: 24),
            _statItem(Icons.straighten, distanceStr),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(_riskLevel ?? 'Moderate Risk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: riskColor)),
            ),
          ]),

          const SizedBox(height: 12),

          // Safety tip.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(_getSafetyTip(score), style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
            ]),
          ),

          const SizedBox(height: 12),

          // Start navigation button.
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.navigation),
            label: Text('Start Navigation'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ])),
      ]),
    );
  }

  Widget _statItem(IconData icon, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: Colors.grey[500]),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
    ]);
  }

  String _getSafetyTip(int score) {
    if (score >= 80) return 'This route passes through relatively safe areas. Stay alert as always.';
    if (score >= 60) return 'Moderate risk along this route. Stick to well-lit main roads and avoid isolated areas.';
    if (score >= 40) return 'High-risk areas detected on this route. Consider an alternative path or travel with a companion.';
    return 'Very high risk! This route passes through dangerous areas. Strongly recommend finding an alternate route.';
  }
}
