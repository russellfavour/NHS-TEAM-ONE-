import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/widgets/osm_map.dart';

/// Saved Locations Page — full CRUD with Hive local storage.
///
/// - Add via map tap or current location (geolocator).
/// - Edit name/address/type.
/// - Delete with confirmation.
/// - Show all locations on an OSM map.
class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({super.key});

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  late Box _box;
  List<LocItem> _locations = [];
  bool _loading = true;

  // Map state for "add location" flow.
  LatLngPoint? _selectedMapLocation;
  String? _selectedAddress;
  final GeocodingService _geo = GeocodingService();
  late final OSMMapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = OSMMapController();
    _loadLocations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ---------- Hive CRUD ----------

  Future<void> _loadLocations() async {
    setState(() => _loading = true);
    try {
      _box = Hive.box('savedLocations');
      final keys = _box.keys.cast<String>();
      final items = <LocItem>[];
      for (final key in keys) {
        final data = _box.get(key) as Map<String, dynamic>?;
        if (data != null) {
          items.add(LocItem.fromJson(data));
        }
      }
      // Sort by name.
      items.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _locations = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveLocation(LocItem item) async {
    await _box.put(item.id, item.toJson());
    await _loadLocations();
  }

  Future<void> _deleteLocation(String id) async {
    await _box.delete(id);
    await _loadLocations();
  }

  // ---------- Map-based location picking ----------

  void _openMapPicker() {
    setState(() => _selectedMapLocation = null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapLocationPicker(
        mapController: _mapController,
        onLocationSelected: (point, address) {
          setState(() {
            _selectedMapLocation = point;
            _selectedAddress = address;
          });
          Navigator.pop(context);
          // Now show the add dialog with the selected location.
          _showAddDialog(point, address);
        },
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always) throw Exception('Permission denied');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLngPoint(position.latitude, position.longitude);

      // Reverse geocode to get address.
      String? address;
      try {
        address = await _geo.reverseGeocode(point.lat, point.lng);
      } catch (_) {}

      if (mounted) _showAddDialog(point, address ?? 'Current Location');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get your location: $e')),
        );
      }
    }
  }

  Future<void> _showAddDialog(LatLngPoint point, String? address) async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'home');
    String? selectedAddress = address;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Location'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Location Name', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Address display.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Selected Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.place, size: 16, color: AppColors.alertRed),
                  const SizedBox(width: 4),
                  Expanded(child: Text(selectedAddress ?? '${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}', style: TextStyle(fontSize: 13))),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Type selector.
            DropdownButtonFormField<String>(
              value: typeCtrl.text,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('🏠 Home')),
                DropdownMenuItem(value: 'work', child: Text('💼 Work')),
                DropdownMenuItem(value: 'education', child: Text('🎓 Education')),
                DropdownMenuItem(value: 'gym', child: Text('🏋️ Gym/Fitness')),
                DropdownMenuItem(value: 'shopping', child: Text('🛒 Shopping')),
                DropdownMenuItem(value: 'other', child: Text('📍 Other')),
              ],
              onChanged: (v) => setDialogState(() => typeCtrl.text = v!),
            ),

            const SizedBox(height: 12),

            // Option to search for a different address.
            TextButton.icon(
              onPressed: () async {
                final result = await _searchAddress(context);
                if (result != null) {
                  setDialogState(() => selectedAddress = result.displayName);
                }
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search different address'),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a location name')));
                  return;
                }
                final newItem = LocItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  address: selectedAddress ?? '',
                  type: typeCtrl.text,
                  coordinates: {'lat': point.lat, 'lng': point.lng},
                  createdAt: DateTime.now().toIso8601String(),
                );
                _saveLocation(newItem);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" saved')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
  }

  Future<GeoResult?> _searchAddress(BuildContext context) async {
    final controller = TextEditingController();
    List<GeoResult>? results;
    bool searching = false;

    return await showDialog<GeoResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Address'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(hintText: 'e.g. 12 Adeola Odeku Street, Victoria Island', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onSubmitted: (_) async {
                setDialogState(() => searching = true);
                try {
                  final found = await _geo.searchAddress(controller.text, limit: 6);
                  if (dialogContext.mounted) setDialogState(() => results = found);
                } catch (_) {
                  if (dialogContext.mounted) setDialogState(() => results = const []);
                } finally {
                  if (dialogContext.mounted) setDialogState(() => searching = false);
                }
              },
            ),
            const SizedBox(height: 12),
            if (searching)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (results != null && results!.isEmpty)
              Text('No matches found. Try a more specific address.', style: TextStyle(color: Colors.grey[600]))
            else if (results != null)
              SizedBox(height: 240, child: ListView.builder(shrinkWrap: true, itemCount: results!.length, itemBuilder: (context, index) {
                final result = results![index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(result.displayName.split(',').take(3).join(','), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  onTap: () => Navigator.pop(dialogContext, result),
                );
              })),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))],
        ),
      ),
    );
  }

  // ---------- Edit dialog ----------

  Future<void> _editLocation(LocItem location) async {
    final nameCtrl = TextEditingController(text: location.name);
    String selectedType = location.type;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Location'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Location Name', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))), autofocus: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('🏠 Home')),
                DropdownMenuItem(value: 'work', child: Text('💼 Work')),
                DropdownMenuItem(value: 'education', child: Text('🎓 Education')),
                DropdownMenuItem(value: 'gym', child: Text('🏋️ Gym/Fitness')),
                DropdownMenuItem(value: 'shopping', child: Text('🛒 Shopping')),
                DropdownMenuItem(value: 'other', child: Text('📍 Other')),
              ],
              onChanged: (v) => setDialogState(() => selectedType = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final updated = LocItem(
                  id: location.id,
                  name: name,
                  address: location.address,
                  type: selectedType,
                  coordinates: location.coordinates,
                  createdAt: location.createdAt,
                );
                _saveLocation(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated')));
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
        actions: [
          IconButton(icon: const Icon(Icons.map), onPressed: _showLocationsOnMap),
          IconButton(icon: const Icon(Icons.add), onPressed: _openMapPicker),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? EmptyState(
                  icon: Icons.location_on_outlined,
                  title: 'No Saved Locations',
                  subtitle: 'Save your home, work, or frequent locations for quick access.',
                  action: ElevatedButton.icon(onPressed: _openMapPicker, icon: const Icon(Icons.add), label: const Text('Add Location')),
                )
              : RefreshIndicator(
                  onRefresh: _loadLocations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) => _buildLocationCard(_locations[index]),
                  ),
                ),
    );
  }

  Widget _buildLocationCard(LocItem location) {
    final (typeIcon, typeColor) = _getTypeInfo(location.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: typeColor.withOpacity(0.2), child: Icon(typeIcon, color: typeColor)),
        title: Text(location.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Expanded(child: Text(location.address.isNotEmpty ? location.address : '${location.coordinates['lat']}, ${location.coordinates['lng']}', style: TextStyle(color: Colors.grey[600]))),
          ]),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editLocation(location)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(location)),
        ]),
      ),
    );
  }

  void _confirmDelete(LocItem location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to remove "${location.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _deleteLocation(location.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${location.name}" removed')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLocationsOnMap() {
    if (_locations.isEmpty) return;

    final first = _locations.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Saved Locations on Map')),
          body: OSMMapWidget(
            lat: (first.coordinates['lat'] as num).toDouble(),
            lng: (first.coordinates['lng'] as num).toDouble(),
            initialZoom: 13,
            markers: [for (final loc in _locations) _toMarker(loc)],
          ),
        ),
      ),
    );
  }

  MapMarker _toMarker(LocItem location) {
    final (icon, color) = _getTypeInfo(location.type);
    return MapMarker(
      lat: (location.coordinates['lat'] as num).toDouble(),
      lng: (location.coordinates['lng'] as num).toDouble(),
      color: color,
      icon: icon,
    );
  }

  (IconData, Color) _getTypeInfo(String type) {
    switch (type) {
      case 'home':
        return (Icons.home, AppColors.primaryGreen);
      case 'work':
        return (Icons.work_outline, Colors.blue.shade600);
      case 'education':
        return (Icons.school, Colors.orange.shade600);
      case 'gym':
        return (Icons.fitness_center, Colors.teal.shade600);
      case 'shopping':
        return (Icons.shopping_bag, Colors.purple.shade600);
      default:
        return (Icons.location_on, Colors.grey.shade600);
    }
  }
}

/// ==================== Map Location Picker Bottom Sheet ====================

class _MapLocationPicker extends StatefulWidget {
  final OSMMapController mapController;
  final Function(LatLngPoint point, String? address) onLocationSelected;

  const _MapLocationPicker({required this.mapController, required this.onLocationSelected});

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  LatLngPoint? _selected;
  String? _address;
  final GeocodingService _geo = GeocodingService();
  bool _locating = false;

  Future<void> _selectLocation(LatLngPoint point) async {
    setState(() => _selected = point);
    final addr = await _geo.reverseGeocode(point.lat, point.lng);
    if (mounted) setState(() => _address = addr);
  }

  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) throw Exception('denied');

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final point = LatLngPoint(pos.latitude, pos.longitude);
      widget.mapController.setCamera(point.lat, point.lng, 16);
      await _selectLocation(point);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar.
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text('Pick a Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tap the map or use your current location', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),

          // Map.
          Container(
            height: 350,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [
                OSMMapWidget(
                  lat: _selected?.lat ?? 6.5244,
                  lng: _selected?.lng ?? 3.3792,
                  initialZoom: 13,
                  controller: widget.mapController,
                  markers: _selected != null ? [MapMarker(lat: _selected!.lat, lng: _selected!.lng, color: AppColors.alertRed, icon: Icons.place)] : const [],
                  onMapTap: (point) => _selectLocation(point),
                ),

                // Locate button.
                Positioned(right: 12, bottom: 12, child: FloatingActionButton.small(
                  backgroundColor: AppColors.primaryGreen,
                  onPressed: _locating ? null : _useCurrent,
                  child: _locating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location, size: 20),
                )),

                // Hint.
                if (_selected == null)
                  Positioned(left: 16, right: 16, bottom: 72, child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(20)),
                    child: Text('Tap the map to drop a pin', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.95))),
                  ))),
              ]),
            ),
          ),

          // Selected address chip.
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.check_circle, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(child: Text(_address ?? '${_selected!.lat.toStringAsFixed(5)}, ${_selected!.lng.toStringAsFixed(5)}', style: TextStyle(fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 16),

          // Confirm button.
          ElevatedButton.icon(
            onPressed: _selected != null ? () => widget.onLocationSelected(_selected!, _address) : null,
            icon: const Icon(Icons.check),
            label: const Text('Confirm Location'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ])),
      ]),
    );
  }
}

/// ==================== Data Model ====================

class LocItem {
  final String id;
  final String name;
  final String address;
  final String type; // home, work, education, gym, shopping, other
  final Map<String, dynamic> coordinates; // {lat: double, lng: double}
  final String createdAt;

  const LocItem({required this.id, required this.name, required this.address, required this.type, required this.coordinates, required this.createdAt});

  factory LocItem.fromJson(Map<String, dynamic> json) {
    return LocItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed',
      address: json['address'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      coordinates: (json['coordinates'] as Map<String, dynamic>?) ?? {'lat': 0.0, 'lng': 0.0},
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address, 'type': type, 'coordinates': coordinates, 'createdAt': createdAt};
  }
}

/// Empty state widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600]))],
        if (action != null) ...[const SizedBox(height: 24), action!],
      ])),
    );
  }
}
