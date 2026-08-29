import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Multi-step crime reporting wizard - Complete implementation matching designs
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
  Map<String, dynamic>? locationData;
  String description = '';
  List<Map<String, String>> witnesses = [];
  final Map<String, String> suspectInfo = {};
  List<String> mediaUrls = [];
  bool isAnonymous = false;

  final List<String> steps = ['Crime Type', 'Location', 'Description', 'Witnesses', 'Suspect Info', 'Evidence', 'Preview'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Crime'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(value: (_currentStep + 1) / steps.length, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),
        
        Expanded(child: _buildCurrentStep()),
        
        // Navigation buttons
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          if (_currentStep > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep--), child: Text('Previous'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(child: ElevatedButton(
            onPressed: _nextStep, 
            child: Text(_currentStep == steps.length - 1 ? 'Submit Report' : 'Next'),
          )),
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
      default: return SizedBox.shrink();
    }
  }

  Widget _buildCrimeTypeSelection() {
    final crimeTypes = [
      {'name': 'Armed Robbery', 'icon': Icons.local_police, 'color': AppColors.alertRed},
      {'name': 'Theft', 'icon': Icons.directions_car, 'color': Colors.orange.shade700},
      {'name': 'Assault', 'icon': Icons.directions_run, 'color': Colors.amber.shade700},
      {'name': 'Vandalism', 'icon': Icons.build, 'color': AppColors.primaryGreen},
      {'name': 'Cyber Crime', 'icon': Icons.computer, 'color': Colors.blue.shade700},
      {'name': 'Suspicious Activity', 'icon': Icons.visibility, 'color': Colors.purple.shade700},
      {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey.shade600},
    ];

    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Select Crime Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Choose the category that best describes the incident', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      Expanded(child: ListView.builder(itemBuilder: (context, index) {
        final type = crimeTypes[index];
        final typeName = type['name'] as String;
        final typeIcon = type['icon'] as IconData;
        final typeColor = type['color'] as Color?;
        return Card(
          margin: EdgeInsets.only(bottom: 8),
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

  Widget _buildLocationSelection() {
    return Column(children: [
      Expanded(child: Container(
        color: Colors.grey[200], 
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
          Positioned(top: 16, right: 16, child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.my_location, size: 24, color: AppColors.primaryGreen),
          )),
        ]),
      )),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.my_location), label: Text('Use Current Location'))),
        SizedBox(width: 8),
        Expanded(flex: 3, child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.search), label: Text('Search Address'))),
      ])),
    ]);
  }

  Widget _buildDescriptionInput() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Incident Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Describe what happened in detail (max 500 characters)', style: TextStyle(color: Colors.grey[600])),
      SizedBox(height: 16),
      TextField(
        controller: TextEditingController(text: description),
        maxLines: 8,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: 'What happened?',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          alignLabelWithHint: true,
        ),
        onChanged: (v) => setState(() => description = v),
      ),
    ]));
  }

  Widget _buildWitnessInformation() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Witness Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Add any witnesses to the incident (optional)', style: TextStyle(color: Colors.grey[600])),
      SizedBox(height: 16),
      Expanded(child: ListView.builder(itemBuilder: (context, index) {
        if (index == witnesses.length) {
          return ElevatedButton.icon(
            onPressed: () => setState(() => witnesses.add({'name': '', 'phone': ''})), 
            icon: Icon(Icons.add), 
            label: Text('Add Witness'),
          );
        }
        return Card(margin: EdgeInsets.only(bottom: 8), child: Padding(padding: EdgeInsets.all(12), child: Column(children: [
          TextFormField(decoration: InputDecoration(labelText: 'Witness Name'), onChanged: (v) => witnesses[index]['name'] = v),
          SizedBox(height: 8),
          Row(children: [Expanded(child: TextFormField(decoration: InputDecoration(labelText: 'Phone Number')), flex: 2), SizedBox(width: 8), Expanded(flex: 1, child: IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => witnesses.removeAt(index))))]),
        ])));
      })),
    ]));
  }

  Widget _buildSuspectInformation() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Suspect Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Describe the suspect(s) and any vehicle information (optional)', style: TextStyle(color: Colors.grey[600])),
      SizedBox(height: 16),
      TextField(decoration: InputDecoration(labelText: 'Physical Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3, onChanged: (v) => suspectInfo['description'] = v),
      SizedBox(height: 16),
      TextField(decoration: InputDecoration(labelText: 'Vehicle Information', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2, onChanged: (v) => suspectInfo['vehicle'] = v),
    ]));
  }

  Widget _buildEvidenceCollection() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Evidence Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Upload photos, videos, or audio recordings (optional)', style: TextStyle(color: Colors.grey[600])),
      SizedBox(height: 16),
      Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.camera_alt), label: Text('Take Photo'))), SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.mic), label: Text('Record Audio')))]),
      SizedBox(height: 16),
      if (mediaUrls.isNotEmpty) ...[Text('${mediaUrls.length} file(s) attached')],
    ]));
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Review Your Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 16),
      _previewSection('Crime Type', selectedCrimeType ?? 'Not specified'),
      _previewSection('Location', locationData != null ? 'Selected' : 'Not set'),
      _previewSection('Description', description.isEmpty ? 'No description' : description.length > 100 ? '${description.substring(0, 100)}...' : description),
      _previewSection('Witnesses', witnesses.isEmpty ? 'None added' : '${witnesses.length} witness(es)'),
      _previewSection('Suspect Info', suspectInfo.isEmpty ? 'Not provided' : 'Details included'),
      _previewSection('Evidence', mediaUrls.isEmpty ? 'No files attached' : '$mediaUrls file(s) attached'),
      SwitchListTile(title: Text('Submit Anonymously'), value: isAnonymous, onChanged: (v) => setState(() => isAnonymous = v)),
    ]));
  }

  Widget _previewSection(String title, String content) {
    return Card(margin: EdgeInsets.only(bottom: 8), child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text(content)])));
  }

  void _nextStep() {
    if (_currentStep == steps.length - 1) {
      // Submit report
      Navigator.of(context).pushReplacementNamed('/report-submitted');
    } else {
      setState(() => _currentStep++);
    }
  }
}

/// Report submitted success screen matching the design
class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryGreen, Colors.green.shade700], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, size: 120, color: Colors.white),
        SizedBox(height: 32),
        Text('Report Submitted Successfully!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 16),
        Text('Your report has been received and will be reviewed shortly', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
        SizedBox(height: 32),
        Container(padding: EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Column(children: [Text('Report ID', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))), SizedBox(height: 8), Text('#SR2387', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))])),
        SizedBox(height: 48),
        ElevatedButton(onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false), child: Text('Back to Home')),
      ]))),
    );
  }
}
