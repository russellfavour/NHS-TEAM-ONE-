import 'package:flutter/material.dart';

class SavedLocationsPage extends StatelessWidget {
  const SavedLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations')),
      body: Center(child: Text('Saved Locations', style: TextStyle(fontSize: 18))),
    );
  }
}
