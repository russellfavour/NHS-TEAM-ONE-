import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/widgets/osm_map.dart';

/// Find nearby safe places (police stations, hospitals, pharmacies) using the
/// free Nominatim geocoding API and render them on the OSM map.
class SafePlacesScreen extends StatefulWidget {
  const SafePlacesScreen({super.key});

  @override
  State<SafePlacesScreen> createState() => _SafePlacesScreenState();
}

class _PlaceCategory {
  final String label;
  final String nominatimQuery;
  final IconData icon;
  final Color color;
  const _PlaceCategory({required this.label, required this.nominatimQuery, required this.icon, required this.color});
}

class _SafePlacesScreenState extends State<SafePlacesScreen> {
  final GeocodingService _geo = GeocodingService();
  final OSMMapController _mapController = OSMMapController();

  static const List<_PlaceCategory> _categories = [
    _PlaceCategory(label: 'Police', nominatimQuery: 'police station', icon: Icons.local_police, color: Color(0xFF1565C0)),
    _PlaceCategory(label: 'Hospitals', nominatimQuery: 'hospital', icon: Icons.local_hospital, color: AppColors.alertRed),
    _PlaceCategory(label: 'Pharmacies', nominatimQuery: 'pharmacy', icon: Icons.medical_services, color: Color(0xFF2E7D32)),
  ];

  int _selectedCategory = 0;
  bool _loading = false;
  String? _error;
  List<GeoResult> _places = const [];
  Position? _userPosition;
  double _centerLat = 6.5244; // Lagos default
  double _centerLng = 3.3792;

  @override
  void initState() {
    super.initState();
    _initLocationAndSearch();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndSearch() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 10)),
          );
          if (!mounted) return;
          setState(() {
            _userPosition = position;
            _centerLat = position.latitude;
            _centerLng = position.longitude;
          });
        }
      }
    } catch (_) {
      // Fall back to the default center (Lagos).
    }
    await _searchPlaces();
  }

  Future<void> _searchPlaces() async {
    final category = _categories[_selectedCategory];
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _geo.findNearbyPlaces(
        category.nominatimQuery,
        lat: _centerLat,
        lng: _centerLng,
        radiusKm: 10,
        limit: 15,
      );
      if (!mounted) return;
      setState(() {
        _places = results;
        _loading = false;
      });

      // Center the map on the first result when we have one.
      if (results.isNotEmpty && mounted) {
        _mapController.setCamera(results.first.lat, results.first.lng, 14);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _places = const [];
        _error = 'Could not find nearby places. Check your internet connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedCategory];

    return Scaffold(
      appBar: AppBar(title: const Text('Find Safe Places')),
      body: Column(children: [
        // Category filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _categories.length; i++) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_categories[i].icon, size: 16, color: i == _selectedCategory ? Colors.white : _categories[i].color),
                        const SizedBox(width: 4),
                        Text(_categories[i].label, style: TextStyle(fontSize: 12, color: i == _selectedCategory ? Colors.white : null)),
                      ]),
                      selected: i == _selectedCategory,
                      onSelected: (_) {
                        setState(() => _selectedCategory = i);
                        _searchPlaces();
                      },
                      selectedColor: _categories[i].color,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Map with place markers
        Expanded(
          flex: 5,
          child: Stack(children: [
            OSMMapWidget(
              lat: _centerLat,
              lng: _centerLng,
              initialZoom: 13,
              controller: _mapController,
              userLocation: _userPosition != null ? LatLngPoint(_userPosition!.latitude, _userPosition!.longitude) : null,
              markers: [
                for (final place in _places)
                  MapMarker(
                    lat: place.lat,
                    lng: place.lng,
                    color: category.color,
                    icon: category.icon,
                    onTap: () => _showPlaceSheet(place),
                  ),
              ],
            ),
            if (_loading)
              Positioned.fill(child: Container(color: Colors.white.withOpacity(0.4), child: const Center(child: CircularProgressIndicator()))),
          ]),
        ),

        // Results list
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE0E0E0)))),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  Expanded(child: Text('${category.label} nearby', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                  IconButton(icon: Icon(Icons.refresh, size: 18, color: Colors.grey[500]), onPressed: _loading ? null : _searchPlaces),
                ]),
              ),
              Expanded(
                child: _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                      ])))
                    : _places.isEmpty && !_loading
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(category.icon, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No ${category.label.toLowerCase()}s found within 10 km', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _places.length,
                            itemBuilder: (context, index) => _placeTile(_places[index], category),
                          ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _placeTile(GeoResult place, _PlaceCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPlaceSheet(place),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: category.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place.displayName.split(',').take(3).join(','), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text('${place.lat.toStringAsFixed(4)}, ${place.lng.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  void _showPlaceSheet(GeoResult place) {
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
              Icon(_categories[_selectedCategory].icon, color: _categories[_selectedCategory].color),
              const SizedBox(width: 8),
              Expanded(child: Text('Safe Place', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text(place.displayName, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/safe-route', extra: <String, dynamic>{
                      'destinationName': place.displayName,
                      'destinationLat': place.lat,
                      'destinationLng': place.lng,
                    });
                  },
                  icon: const Icon(Icons.route, size: 18),
                  label: const Text('Route Here'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
