import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Reports')),
      body: ListView(children: [
        // Filter chips
        Padding(padding: EdgeInsets.all(16), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [FilterChip(label: Text('All'), selected: true, onSelected: (_) {}), SizedBox(width: 8), FilterChip(label: Text('Pending'), onSelected: (_) {}), SizedBox(width: 8), FilterChip(label: Text('Verified'), onSelected: (_) {}), SizedBox(width: 8), FilterChip(label: Text('Rejected'), onSelected: (_) {})]))),
        
        // Report list
        _buildReportCard('#SR2387', 'Armed Robbery', 'Lagos Mainland', 'Verified', AppColors.statusVerified, 'Aug 21, 2024'),
        _buildReportCard('#SR2386', 'Theft', 'Ikeja GRA', 'Under Review', AppColors.statusUnderReview, 'Aug 20, 2024'),
        _buildReportCard('#SR2385', 'Assault', 'Victoria Island', 'Verified', AppColors.statusVerified, 'Aug 19, 2024'),
        _buildReportCard('#SR2384', 'Vandalism', 'Lekki Phase 1', 'Rejected', AppColors.statusDismissed, 'Aug 18, 2024'),
      ]),
    );
  }

  Widget _buildReportCard(String id, String type, String location, String status, Color statusColor, String date) {
    return Card(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(leading: CircleAvatar(child: Icon(Icons.report_problem)), title: Text('$id - $type'), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(location), Text(date)]), trailing: Chip(label: Text(status), backgroundColor: statusColor)));
  }
}
