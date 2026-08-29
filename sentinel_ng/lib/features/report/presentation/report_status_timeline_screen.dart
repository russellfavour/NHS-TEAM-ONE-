import 'package:flutter/material.dart';

class ReportStatusTimelineScreen extends StatelessWidget {
  final String reportId;
  const ReportStatusTimelineScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Status - $reportId')),
      body: Center(child: Text('Report Status Timeline', style: TextStyle(fontSize: 18))),
    );
  }
}
