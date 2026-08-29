import 'package:flutter/material.dart';

class SafeRouteScreen extends StatelessWidget {
  const SafeRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Route Planner')),
      body: Center(child: Text('Safe Route Planner', style: TextStyle(fontSize: 18))),
    );
  }
}
