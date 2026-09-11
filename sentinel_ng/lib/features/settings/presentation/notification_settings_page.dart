import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// Notification preferences — GET/PUT /api/notifications/preferences.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  // Defaults used when the API is unreachable.
  bool _hotspotAlerts = true;
  bool _statusChanges = true;
  bool _communityWarnings = true;
  bool _sosResponses = true;
  bool _emailEnabled = false;
  bool _pushEnabled = true;
  double _radiusKm = 5;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    try {
      final prefs = await _api.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _hotspotAlerts = prefs['hotspotAlerts'] as bool? ?? true;
        _statusChanges = prefs['statusChanges'] as bool? ?? true;
        _communityWarnings = prefs['communityWarnings'] as bool? ?? true;
        _sosResponses = prefs['sosResponses'] as bool? ?? true;
        _emailEnabled = prefs['emailEnabled'] as bool? ?? false;
        _pushEnabled = prefs['pushEnabled'] as bool? ?? true;
        _radiusKm = (prefs['radiusKm'] as num?)?.toDouble() ?? 5;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load your saved preferences — showing defaults.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateNotificationPreferences({
        'hotspotAlerts': _hotspotAlerts,
        'statusChanges': _statusChanges,
        'communityWarnings': _communityWarnings,
        'sosResponses': _sosResponses,
        'emailEnabled': _emailEnabled,
        'pushEnabled': _pushEnabled,
        'radiusKm': _radiusKm,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved'), backgroundColor: AppColors.primaryGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_loadError != null)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
                  child: Row(children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_loadError!, style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
                  ]),
                ),

              Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  _sectionHeader('Alert Types', Icons.notifications_none_rounded),
                  _toggleTile(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    title: 'Hotspot Alerts',
                    subtitle: 'Get alerted when a crime hotspot forms near you',
                    value: _hotspotAlerts,
                    onChanged: (v) => setState(() => _hotspotAlerts = v),
                  ),
                  _toggleTile(
                    icon: Icons.verified_rounded,
                    color: AppColors.statusVerified,
                    title: 'Report Status Changes',
                    subtitle: 'Updates when your reports are verified or reviewed',
                    value: _statusChanges,
                    onChanged: (v) => setState(() => _statusChanges = v),
                  ),
                  _toggleTile(
                    icon: Icons.groups_rounded,
                    color: Colors.blue.shade700,
                    title: 'Community Warnings',
                    subtitle: 'Aggregated warnings from multiple community reports',
                    value: _communityWarnings,
                    onChanged: (v) => setState(() => _communityWarnings = v),
                  ),
                  _toggleTile(
                    icon: Icons.local_police_rounded,
                    color: AppColors.alertRed,
                    title: 'SOS Responses',
                    subtitle: 'Notifications about SOS alerts and responder updates',
                    value: _sosResponses,
                    onChanged: (v) => setState(() => _sosResponses = v),
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('Delivery & Radius', Icons.gps_fixed_rounded),
                  _toggleTile(
                    icon: Icons.email_outlined,
                    color: Colors.grey.shade700,
                    title: 'Email Notifications',
                    subtitle: 'Also send alerts to your email address',
                    value: _emailEnabled,
                    onChanged: (v) => setState(() => _emailEnabled = v),
                  ),
                  _toggleTile(
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.primaryGreen,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts on this device in real time',
                    value: _pushEnabled,
                    onChanged: (v) => setState(() => _pushEnabled = v),
                  ),

                  // Alert radius slider
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: const Text('Alert Radius', style: TextStyle(fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('${_radiusKm.toStringAsFixed(0)} km', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('How far from you should incidents trigger alerts?', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Slider(
                        value: _radiusKm,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${_radiusKm.toStringAsFixed(0)} km',
                        activeColor: AppColors.primaryGreen,
                        onChanged: (v) => setState(() => _radiusKm = v),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save Preferences'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 6),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Switch(value: value, activeColor: AppColors.primaryGreen, onChanged: onChanged),
      ),
    );
  }
}
