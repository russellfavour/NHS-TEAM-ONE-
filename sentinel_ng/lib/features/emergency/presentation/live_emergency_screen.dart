import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class LiveEmergencyScreen extends StatelessWidget {
  const LiveEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Emergency')),
      body: Center(child: Text('Live Emergency Screen', style: TextStyle(fontSize: 18))),
    );
  }
}
