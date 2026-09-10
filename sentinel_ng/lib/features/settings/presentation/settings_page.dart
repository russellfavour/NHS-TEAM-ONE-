import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';

/// App settings — navigation links, about section and logout.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _confirmingLogout = false;

  void _logout(BuildContext context) {
    if (_confirmingLogout) return;
    setState(() => _confirmingLogout = true);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your reports and alerts.'),
        actions: [
          TextButton(onPressed: () {
            setState(() => _confirmingLogout = false);
            Navigator.pop(dialogContext);
          }, child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionHeader('Preferences', Icons.tune_rounded),
        _linkTile(Icons.notifications, 'Notification Settings', 'Choose which alerts you receive and how far', () => context.push('/notification-settings'), AppColors.primaryGreen),
        _linkTile(Icons.phone, 'Emergency Contacts', 'Manage the people notified when you trigger SOS', () => context.push('/emergency-contacts'), Colors.blue.shade700),
        _linkTile(Icons.bookmark, 'Saved Locations', 'Your home, work and frequent places', () => context.push('/saved-locations'), Colors.orange.shade700),
        _linkTile(Icons.photo_library, 'Media Library', 'Photos and videos attached to your reports', () => context.push('/media-library'), Colors.purple.shade600),

        const SizedBox(height: 16),
        _sectionHeader('About', Icons.info_outline_rounded),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sentinel NG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Version 1.0.0 · Community safety network', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ])),
            ]),
            const SizedBox(height: 12),
            Text(
              'Sentinel NG helps Nigerian communities report crimes, verify incidents and stay informed about safety in their neighbourhoods. Map data © OpenStreetMap contributors.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        // Logout
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.alertRed.withOpacity(0.3))),
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.alertRed),
            title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.alertRed)),
            trailing: Icon(Icons.chevron_right_rounded, color: AppColors.alertRed.withOpacity(0.5)),
            onTap: () => _logout(context),
          ),
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

  Widget _linkTile(IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
