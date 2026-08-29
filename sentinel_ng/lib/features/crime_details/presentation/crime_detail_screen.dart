import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CrimeDetailScreen extends StatelessWidget {
  final String reportId;
  const CrimeDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crime Report Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge and report ID
            Row(children: [
              Chip(label: Text('Verified'), backgroundColor: AppColors.statusVerified),
              SizedBox(width: 8),
              Text('#SR2387', style: TextStyle(color: Colors.grey[600])),
            ]),
            SizedBox(height: 16),

            // Crime type and risk level
            Row(children: [
              Expanded(child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(children: [
                    Text('Crime Type', style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 8),
                    Text('Armed Robbery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
              SizedBox(width: 12),
              Expanded(child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(children: [
                    Text('Risk Level', style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 8),
                    Text('High Risk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.alertRed)),
                  ]),
                ),
              )),
            ]),
            SizedBox(height: 24),

            // Description
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Armed robbery reported at the main entrance of the shopping mall. Two suspects on motorcycles. One suspect was seen carrying a knife.'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Location
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.location_on, color: AppColors.alertRed),
                      SizedBox(width: 8),
                      Expanded(child: Text('Lagos Mainland, near Ikeja GRA')),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Evidence gallery
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(children: [
                      Container(width: 80, height: 80, color: Colors.grey[300], child: Icon(Icons.image)),
                      SizedBox(width: 8),
                      Container(width: 80, height: 80, color: Colors.grey[300], child: Icon(Icons.video_camera_front)),
                      SizedBox(width: 8),
                      Container(width: 80, height: 80, color: Colors.grey[300], child: Icon(Icons.audiotrack)),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Status timeline
            Text('Report Status Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildTimeline([
              {'title': 'Submitted', 'time': 'Aug 20, 2024 10:30 AM', 'done': true},
              {'title': 'Under Review', 'time': 'Aug 20, 2024 2:15 PM', 'done': true},
              {'title': 'Verified', 'time': 'Aug 21, 2024 9:00 AM', 'done': true},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<Map<String, dynamic>> items) {
    return Column(children: List.generate(items.length, (index) {
      final item = items[index];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: item['done'] as bool ? AppColors.primaryGreen : Colors.grey[300],
                child: Icon(Icons.check, size: 14, color: Colors.white),
              ),
              if (index < items.length - 1)
                Container(width: 2, height: 40, color: item['done'] as bool ? AppColors.primaryGreen : Colors.grey[300]),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item['time'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }));
  }
}
