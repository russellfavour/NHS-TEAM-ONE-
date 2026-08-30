import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Saved Locations Page - Manage saved home, work, and frequent locations
class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({super.key});

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  final List<Map<String, dynamic>> _locations = [
    {
      'id': '1',
      'name': 'Home',
      'address': '123 Victoria Island, Lagos',
      'type': 'home',
      'coordinates': {'lat': 6.4281, 'lng': 3.4219},
    },
    {
      'id': '2',
      'name': 'Work',
      'address': 'Ikeja GRA, Lagos',
      'type': 'work',
      'coordinates': {'lat': 6.5964, 'lng': 3.3515},
    },
    {
      'id': '3',
      'name': 'University',
      'address': 'University of Lagos, Akoka',
      'type': 'education',
      'coordinates': {'lat': 6.5158, 'lng': 3.3912},
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addLocation,
          ),
        ],
      ),
      body: _locations.isEmpty
          ? EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No Saved Locations',
              subtitle: 'Save your home, work, or frequent locations for quick access.',
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return _buildLocationCard(location);
                },
              ),
            ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    IconData typeIcon;
    Color typeColor;
    
    switch (location['type']) {
      case 'home':
        typeIcon = Icons.home;
        typeColor = AppColors.primaryGreen;
        break;
      case 'work':
        typeIcon = Icons.work_outline;
        typeColor = Colors.blue.shade600;
        break;
      case 'education':
        typeIcon = Icons.school;
        typeColor = Colors.orange.shade600;
        break;
      default:
        typeIcon = Icons.location_on;
        typeColor = Colors.grey.shade600;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          location['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text(location['address'], style: TextStyle(color: Colors.grey[600]))),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editLocation(location),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteLocation(location['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Location Name')),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'education', child: Text('Education')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // In real app, save to API/local storage
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editLocation(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Location Name', hintText: location['name'])),
            const SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Address', hintText: location['address'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteLocation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: const Text('Are you sure you want to remove this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _locations.removeWhere((l) => l['id'] == id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget for when there's no data to display
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}
