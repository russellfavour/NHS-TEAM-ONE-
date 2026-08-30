import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

/// Safety Score Detail Page - Shows detailed breakdown of user's safety score using charts
class SafetyScoreDetailPage extends StatelessWidget {
  const SafetyScoreDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Score Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Your Overall Safety Score',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular gauge
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: _buildScoreSections(),
                                centerSpaceRadius: 80,
                                sectionsSpace: 0,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '82',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '/ 100',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '+12% from Last Week',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Score Breakdown Section
            Text(
              'Score Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Individual metric cards with circular progress
            _metricCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Online Activity',
              score: 90,
              description: 'Your engagement in reporting and community activities',
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 12),

            _metricCard(
              icon: Icons.people_outline,
              title: 'Community Participation',
              score: 78,
              description: 'Your involvement in verifying and supporting reports',
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 12),

            _metricCard(
              icon: Icons.verified_user,
              title: 'Report Accuracy',
              score: 85,
              description: 'How accurate your reports are based on verification rate',
              color: Colors.orange.shade600,
            ),
            const SizedBox(height: 12),

            _metricCard(
              icon: Icons.timer_outlined,
              title: 'Response Time',
              score: 72,
              description: 'How quickly you respond to community alerts and requests',
              color: Colors.purple.shade600,
            ),

            const SizedBox(height: 24),

            // Weekly Trend Chart
            Text(
              'Weekly Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()] ?? '',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 65),
                        FlSpot(1, 72),
                        FlSpot(2, 68),
                        FlSpot(3, 78),
                        FlSpot(4, 80),
                        FlSpot(5, 79),
                        FlSpot(6, 82),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.3),
                            AppColors.primaryGreen.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  minY: 50,
                  maxY: 100,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tips Section
            Text(
              'Tips to Improve Your Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _tipCard('Submit detailed reports with accurate location information'),
            const SizedBox(height: 8),
            _tipCard('Verify reports from other community members when possible'),
            const SizedBox(height: 8),
            _tipCard('Respond promptly to safety alerts in your area'),
            const SizedBox(height: 8),
            _tipCard('Keep your emergency contacts updated'),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildScoreSections() {
    return [
      PieChartSectionData(
        value: 82,
        color: Colors.white,
        radius: 10,
        showTitle: false,
      ),
      PieChartSectionData(
        value: 18,
        color: Colors.white.withOpacity(0.3),
        radius: 10,
        showTitle: false,
      ),
    ];
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required int score,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
