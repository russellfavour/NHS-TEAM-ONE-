import 'package:flutter/material.dart';

class SafetyScoreDetailPage extends StatelessWidget {
  const SafetyScoreDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Score Details')),
      body: Center(child: Text('Safety Score Detail', style: TextStyle(fontSize: 18))),
    );
  }
}
