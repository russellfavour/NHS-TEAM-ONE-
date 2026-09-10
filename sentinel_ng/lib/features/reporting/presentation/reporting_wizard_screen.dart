import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../data/models/crime_report_model.dart';

/// Multi-step crime reporting wizard with a real map location picker,
/// Nominatim address search and photo/video evidence upload.
class ReportingWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ReportingWizardScreen({super.key, this.data});

  @override
  State<ReportingWizardScreen> createState() => _ReportingWizardScreenState();
}

class _ReportingWizardScreenState extends State<ReportingWizardScreen> {
  int _currentStep = 0;

  // Form data storage
  String? selectedCrimeType;
  LatLngPoint? locationData;
  String? locationAddress;
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, String>> witnesses = [];
  final Map<String, String> suspectInfo = {};
  bool isAnonymous = false;

  // Evidence (picked files, uploaded on submit)
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _evidenceFiles = [];

  // Location search state
  final GeocodingService _geo = GeocodingService();
  final OSMMapController _mapController = OSMMapController();
  bool _locating = false;

  final List<String> steps = ['Crime Type', 'Location', 'Description', 'Witnesses', 'Suspect Info', 'Evidence', 'Preview'];

  @override
  void initState() {
    super.initState();
    // Pre-fill from route extra when available (e.g. "report this" from a map).
    final data = widget.data;
    if (data != null) {
      selectedCrimeType = data['type'] as String? ?? selectedCrimeType;
      _descriptionController.text = data['description'] as String? ?? '';
      final coords = data['coordinates'];
      if (coords is List<dynamic> && coords.length == 2) {
        locationData = LatLngPoint((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Crime'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(value: (_currentStep + 1) / steps.length, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),

        Expanded(child: _buildCurrentStep()),

        // Navigation buttons
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          if (_currentStep > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep--), child: const Text('Previous'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep > 0 ? 2 : 3,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(_currentStep == steps.length - 1 ? 'Submit Report' : 'Next'),
            ),
          ),
        ])),
      ]),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildCrimeTypeSelection();
      case 1: return _buildLocationSelection();
      case 2: return _buildDescriptionInput();
      case 3: return _buildWitnessInformation();
      case 4: return _buildSuspectInformation();
      case 5: return _buildEvidenceCollection();
      case 6: return _buildPreviewStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCrimeTypeSelection() {
    final crimeTypes = [
      {'name': 'Armed Robbery', 'icon': Icons.local_police, 'color': AppColors.alertRed},
      {'name': 'Theft', 'icon': Icons.directions_car, 'color': Colors.orange.shade700},
      {'name': 'Assault', 'icon': Icons.directions_run, 'color': Colors.amber.shade700},
      {'name': 'Vandalism', 'icon': Icons.build, 'color': AppColors.primaryGreen},
      {'name': 'Cyber Crime', 'icon': Icons.computer, 'color': Colors.blue.shade700},
      {'name': 'Suspicious Activity', 'icon': Icons.visibility, 'color': Colors.purple.shade600},
      {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey.shade600},
    ];

    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Select Crime Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Choose the category that best describes the incident', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      Expanded(child: ListView.builder(itemCount: crimeTypes.length, itemBuilder: (context, index) {
        final type = crimeTypes[index];
        final typeName = type['name'] as String;
        final typeIcon = type['icon'] as IconData;
        final typeColor = type['color'] as Color?;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: selectedCrimeType == typeName ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
          child: RadioListTile<String>(
            value: typeName,
            groupValue: selectedCrimeType,
            onChanged: (v) => setState(() => selectedCrimeType = v),
            title: Text(typeName),
            secondary: Icon(typeIcon, color: typeColor),
          ),
        );
      })),
    ]));
  }

  // ---------- Location step: real OSM map + geolocator + Nominatim search ----------

  Widget _buildLocationSelection() {
    return Column(children: [
      Expanded(
        child: Stack(children: [
          OSMMapWidget(
            lat: locationData?.lat ?? 6.5244,
            lng: locationData?.lng ?? 3.3792,
            initialZoom: 13,
            controller: _mapController,
            markers: locationData != null
                ? [MapMarker(lat: locationData!.lat, lng: locationData!.lng, color: AppColors.alertRed, icon: Icons.place)]
                : const [],
            onMapTap: (point) => _selectLocation(point),
          ),

          // Selected address chip
          if (locationAddress != null || locationData != null)
            Positioned(
              top: 8,
              left: 12,
              right: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
                child: Row(children: [
                  Icon(Icons.place, size: 16, color: AppColors.alertRed),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    locationAddress ?? '${locationData!.lat.toStringAsFixed(5)}, ${locationData!.lng.toStringAsFixed(5)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  )),
                ]),
              ),
            ),

          // Locate-me button
          Positioned(
            right: 12,
            bottom: 64,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.primaryGreen,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location, size: 20),
            ),
          ),

          // Hint when nothing selected yet
          if (locationData == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 72,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(20)),
                child: Text('Tap the map to drop a pin', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.95))),
              )),
            ),
        ]),
      ),

      // Address bar + action buttons
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))]),
        child: Row(children: [
          Expanded(flex: 3, child: OutlinedButton.icon(
            onPressed: () => _showAddressSearchDialog(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search Address'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: ElevatedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: Icon(Icons.my_location, size: 18),
            label: Text(_locating ? 'Locating…' : 'Use Current Location'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
          )),
        ]),
      ),
    ]);
  }

  Future<void> _selectLocation(LatLngPoint point) async {
    setState(() {
      locationData = point;
      locationAddress = null; // cleared until reverse geocode resolves
    });
    final address = await _geo.reverseGeocode(point.lat, point.lng);
    if (mounted && address != null) {
      setState(() => locationAddress = address);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.granted) throw Exception('denied');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      _mapController.setCamera(position.latitude, position.longitude, 16);
      await _selectLocation(LatLngPoint(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get your location. Tap the map to drop a pin instead.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showAddressSearchDialog() async {
    final controller = TextEditingController();
    List<GeocodingService.GeoResult>? results;
    bool searching = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Address'),
          content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'e.g. 12 Adeola Odeku Street, Victoria Island',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No matches found. Try a more specific address.', style: TextStyle(color: Colors.grey[600])),
              )
            else if (results != null)
              SizedBox(height: 240, child: ListView.builder(
                shrinkWrap: true,
                itemCount: results!.length,
                itemBuilder: (context, index) {
                  final result = results![index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(result.displayName.split(',').take(3).join(','), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _mapController.setCamera(result.lat, result.lng, 16);
                      setState(() => locationAddress = result.displayName);
                      _selectLocation(LatLngPoint(result.lat, result.lng));
                    },
                  );
                },
              )),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  // ---------- Description step ----------

  Widget _buildDescriptionInput() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Incident Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Describe what happened in detail (max 500 characters)', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 16),
      TextField(
        controller: _descriptionController,
        maxLines: 8,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: 'What happened?',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          alignLabelWithHint: true,
        ),
      ),
    ]));
  }

  // ---------- Witnesses step ----------

  Widget _buildWitnessInformation() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Witness Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Add any witnesses to the incident (optional)', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 16),
      Expanded(child: ListView.builder(itemCount: witnesses.length + 1, itemBuilder: (context, index) {
        if (index == witnesses.length) {
          return ElevatedButton.icon(
            onPressed: () => setState(() => witnesses.add({'name': '', 'phone': ''})),
            icon: const Icon(Icons.add),
            label: const Text('Add Witness'),
          );
        }
        final witness = witnesses[index];
        return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: TextEditingController(text: witness['name']), decoration: const InputDecoration(labelText: 'Witness Name'), onChanged: (v) => witnesses[index]['name'] = v),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 2, child: TextField(controller: TextEditingController(text: witness['phone']), keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number'), onChanged: (v) => witnesses[index]['phone'] = v)),
            const SizedBox(width: 8),
            IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => witnesses.removeAt(index))),
          ]),
        ])));
      })),
    ]));
  }

  // ---------- Suspect step ----------

  Widget _buildSuspectInformation() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Suspect Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Describe the suspect(s) and any vehicle information (optional)', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 16),
      TextField(
        controller: TextEditingController(text: suspectInfo['description']),
        decoration: const InputDecoration(labelText: 'Physical Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        maxLines: 3,
        onChanged: (v) => suspectInfo['description'] = v,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: TextEditingController(text: suspectInfo['vehicle']),
        decoration: const InputDecoration(labelText: 'Vehicle Information', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        maxLines: 2,
        onChanged: (v) => suspectInfo['vehicle'] = v,
      ),
    ]));
  }

  // ---------- Evidence step: image_picker with preview grid ----------

  Widget _buildEvidenceCollection() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Evidence Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Add photos or videos of the scene (optional). Files are uploaded when you submit.', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _pickMedia(ImageSource.camera, video: false),
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('Take Photo'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _pickMedia(ImageSource.gallery, video: false),
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Photos'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
        )),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _pickMedia(ImageSource.camera, video: true),
          icon: const Icon(Icons.videocam_outlined, size: 18),
          label: const Text('Record Video'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _pickMedia(ImageSource.gallery, video: true),
          icon: const Icon(Icons.video_library_outlined, size: 18),
          label: const Text('Videos'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
        )),
      ]),

      const SizedBox(height: 16),

      if (_evidenceFiles.isNotEmpty) ...[
        Text('${_evidenceFiles.length} file(s) attached', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
            itemCount: _evidenceFiles.length,
            itemBuilder: (context, index) {
              final file = _evidenceFiles[index];
              final isVideo = file.mimeType?.startsWith('video') == true ||
                  file.path.toLowerCase().split('?').first.endsWith('.mp4');
              return Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: isVideo
                        ? Container(color: const Color(0xFF1B1B1F), child: const Center(child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white70)))
                        // On web the picked file path is a blob URL — use network image.
                        : kIsWeb
                            ? Image.network(file.path, fit: BoxFit.cover)
                            : Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(top: 4, right: 4, child: GestureDetector(
                  onTap: () => setState(() => _evidenceFiles.removeAt(index)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                )),
              ]);
            },
          ),
        ),
      ],
    ]));
  }

  Future<void> _pickMedia(ImageSource source, {required bool video}) async {
    try {
      final List<XFile>? picked = video
          ? await _picker.pickVideo(source: source, maxWidth: 1920)
          : await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _evidenceFiles.addAll(picked));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick media: $e')));
      }
    }
  }

  // ---------- Preview step ----------

  Widget _buildPreviewStep() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Review Your Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _previewSection('Crime Type', selectedCrimeType ?? 'Not specified'),
      _previewSection('Location', locationData != null ? (locationAddress ?? '${locationData!.lat.toStringAsFixed(5)}, ${locationData!.lng.toStringAsFixed(5)}') : 'Not set'),
      _previewSection('Description', _descriptionController.text.isEmpty ? 'No description' : (_descriptionController.text.length > 120 ? '${_descriptionController.text.substring(0, 120)}…' : _descriptionController.text)),
      _previewSection('Witnesses', witnesses.where((w) => (w['name'] ?? '').isNotEmpty).isEmpty ? 'None added' : '${witnesses.length} witness(es)'),
      _previewSection('Suspect Info', suspectInfo.values.every((v) => v.isEmpty) ? 'Not provided' : 'Details included'),
      _previewSection('Evidence', _evidenceFiles.isEmpty ? 'No files attached' : '${_evidenceFiles.length} file(s) will be uploaded'),
      SwitchListTile(title: const Text('Submit Anonymously'), value: isAnonymous, onChanged: (v) => setState(() => isAnonymous = v)),
    ]));
  }

  Widget _previewSection(String title, String content) {
    return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(content)])));
  }

  // ---------- Navigation + submit ----------

  void _nextStep() {
    if (_currentStep == steps.length - 1) {
      _submitReport();
      return;
    }

    // Per-step validation.
    switch (_currentStep) {
      case 0:
        if (selectedCrimeType == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a crime type')));
          return;
        }
        break;
      case 1:
        if (locationData == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please drop a pin or use your current location')));
          return;
        }
        break;
      case 2:
        if (_descriptionController.text.trim().length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the incident (at least 10 characters)')));
          return;
        }
        break;
    }

    setState(() => _currentStep++);
  }

  Future<void> _submitReport() async {
    final apiService = ApiService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        title: Text('Submitting report…'),
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 16),
          Expanded(child: Text('Uploading evidence and sending your report. This may take a moment.')),
        ]),
      ),
    );

    try {
      // Upload each evidence file first (multipart POST /api/uploads).
      final mediaUrls = <String>[];
      final evidenceEntries = <Map<String, dynamic>>[];
      for (final file in _evidenceFiles) {
        final bytes = await file.readAsBytes();
        final url = await apiService.uploadMediaBytes(bytes, file.name);
        mediaUrls.add(url);
        final isVideo = file.mimeType?.startsWith('video') == true || file.path.toLowerCase().split('?').first.endsWith('.mp4');
        evidenceEntries.add({
          'type': isVideo ? 'video' : 'image',
          'url': url,
          'uploadedAt': DateTime.now().toIso8601String(),
        });
      }

      final reportData = CreateReportRequest(
        type: selectedCrimeType ?? 'Others',
        description: _descriptionController.text.trim(),
        location: {
          'type': 'Point',
          'coordinates': [locationData!.lng, locationData!.lat], // GeoJSON: [lng, lat]
        },
        mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
        isAnonymous: isAnonymous,
      ).toJson();

      final cleanWitnesses = witnesses.where((w) => (w['name'] ?? '').isNotEmpty).toList();
      if (cleanWitnesses.isNotEmpty) reportData['witnesses'] = cleanWitnesses;
      final cleanSuspect = suspectInfo.map((k, v) => MapEntry(k, v.trim()));
      if (cleanSuspect.values.any((v) => v.isNotEmpty)) reportData['suspectInfo'] = cleanSuspect;
      if (evidenceEntries.isNotEmpty) reportData['evidence'] = evidenceEntries;

      final response = await apiService.createReport(reportData);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog

      final reportId = (response['id'] as String?) ?? '';
      context.pushReplacement('/report-submitted?id=$reportId');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

/// Report submitted success screen — shows the real report ID from the API.
class ReportSubmittedScreen extends StatelessWidget {
  final String reportId;
  const ReportSubmittedScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryGreen, Colors.green.shade700], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline, size: 120, color: Colors.white),
        const SizedBox(height: 32),
        Text('Report Submitted Successfully!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text('Your report has been received and will be reviewed shortly. You can track its status from My Reports.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
        ),
        const SizedBox(height: 32),
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Text('Report ID', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(reportId.isNotEmpty ? '#${reportId.substring(0, reportId.length > 12 ? 12 : reportId.length)}' : '—', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        ])),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.6)), minimumSize: const Size(0, 50)),
              onPressed: () => context.pushReplacement('/my-reports'),
              child: const Text('View My Reports'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryGreen, minimumSize: const Size(0, 50)),
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            )),
          ]),
        ),
      ]))),
    );
  }
}
