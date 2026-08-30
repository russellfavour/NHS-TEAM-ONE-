import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Safe Route Planner Screen - Plan safe routes avoiding high-risk areas
class SafeRouteScreen extends StatefulWidget {
  const SafeRouteScreen({super.key});

  @override
  State<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends State<SafeRouteScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isCalculating = false;
  List<RouteOption> _routeOptions = [];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _calculateRoute() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) return;

    setState(() => _isCalculating = true);

    // Simulate route calculation (in real app, call API + Google Maps Directions API)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _routeOptions = [
          RouteOption(
            name: 'Safest Route',
            description: 'Avoids high-risk areas. Recommended for night travel.',
            duration: '35 mins',
            distance: '8.2 km',
            safetyScore: 92,
            riskLevel: 'Low Risk',
            color: AppColors.primaryGreen,
            isRecommended: true,
          ),
          RouteOption(
            name: 'Fastest Route',
            description: 'Shortest distance but passes through moderate-risk areas.',
            duration: '25 mins',
            distance: '6.5 km',
            safetyScore: 68,
            riskLevel: 'Medium Risk',
            color: Colors.orange.shade600,
            isRecommended: false,
          ),
          RouteOption(
            name: 'Alternative Route',
            description: 'Balanced route with moderate safety and reasonable time.',
            duration: '30 mins',
            distance: '7.1 km',
            safetyScore: 85,
            riskLevel: 'Low Risk',
            color: Colors.blue.shade600,
            isRecommended: false,
          ),
        ];
        _isCalculating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Route Planner'),
      ),
      body: Column(
        children: [
          // Input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan Your Safe Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Origin input
                TextField(
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: 'Starting Point',
                    prefixIcon: Icon(Icons.start, color: AppColors.primaryGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Destination input
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.flag, color: AppColors.alertRed),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick locations
                Text('Quick Locations:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickChip(Icons.home, 'Home', () => _originController.text = 'Home'),
                      const SizedBox(width: 8),
                      _quickChip(Icons.work_outline, 'Work', () => _destinationController.text = 'Work'),
                      const SizedBox(width: 8),
                      _quickChip(Icons.school, 'University', () => _destinationController.text = 'University of Lagos'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Calculate button
                ElevatedButton.icon(
                  onPressed: _isCalculating ? null : _calculateRoute,
                  icon: _isCalculating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.route),
                  label: Text(_isCalculating ? 'Calculating...' : 'Find Safe Route'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          // Map placeholder section
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Stack(
                children: [
                  // Map background pattern
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Route Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[400])),
                      ],
                    ),
                  ),

                  // Route options overlay (when calculated)
                  if (_routeOptions.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildRouteOptions(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Route Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_routeOptions.length} routes found', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 12),

                // Route option cards
                ..._routeOptions.map((option) => _buildRouteOptionCard(option)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOptionCard(RouteOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: option.isRecommended 
            ? AppColors.primaryGreen.withOpacity(0.05) 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: option.isRecommended 
              ? AppColors.primaryGreen 
              : Colors.grey.shade300,
          width: option.isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: option.color),
                    const SizedBox(width: 8),
                    Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (option.isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Recommended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
              // Safety score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${option.safetyScore}/100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: option.color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(option.description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(option.duration, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 16),
              Icon(Icons.straighten, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(option.distance, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(option.riskLevel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: option.color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RouteOption {
  final String name;
  final String description;
  final String duration;
  final String distance;
  final int safetyScore;
  final String riskLevel;
  final Color color;
  final bool isRecommended;

  const RouteOption({
    required this.name,
    required this.description,
    required this.duration,
    required this.distance,
    required this.safetyScore,
    required this.riskLevel,
    required this.color,
    this.isRecommended = false,
  });
}
