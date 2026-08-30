import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// Live Emergency Screen - Shows active SOS alert with countdown and cancel option
class LiveEmergencyScreen extends StatefulWidget {
  const LiveEmergencyScreen({super.key});

  @override
  State<LiveEmergencyScreen> createState() => _LiveEmergencyScreenState();
}

class _LiveEmergencyScreenState extends State<LiveEmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _remainingSeconds = 30;
  bool _isCancelled = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startCountdown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _remainingSeconds = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCancelled || !mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _sendSOSAlert();
      }
    });
  }

  Future<void> _sendSOSAlert() async {
    try {
      final apiService = ApiService();
      // Get current location (placeholder - in real app use geolocator)
      final location = <String, dynamic>{
        'type': 'Point',
        'coordinates': [-73.985130, 40.748817], // Default NYC coordinates as placeholder
      };
      await apiService.triggerSOS(location: location);
      setState(() {
        _statusMessage = 'Emergency alert sent successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send alert. Please try again.';
      });
    }
  }

  void _cancelAlert() {
    setState(() => _isCancelled = true);
    _countdownTimer?.cancel();
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency Alert?'),
        content: const Text(
          'Are you sure you want to cancel this emergency alert?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isCancelled = false);
              _startCountdown();
            },
            child: const Text('No, Keep Active'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/home'); // Navigate home
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Yes, Cancel Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.alertRed, AppColors.dangerDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing SOS icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 280 + (_pulseController.value * 40),
                    height: 280 + (_pulseController.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  );
                },
              ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Status message
              Text(
                _isCancelled ? 'Alert Cancelled' : 'Help is on the way!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle with countdown or status
              if (!_isCancelled) ...[
                Text(
                  'Emergency alert will be sent in $_remainingSeconds seconds',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your location will be shared with emergency contacts and community',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 48),

              // Countdown circle (only when active)
              if (!_isCancelled) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Cancel button (only when active)
              if (!_isCancelled) ...[
                OutlinedButton.icon(
                  onPressed: _cancelAlert,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Alert'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Bottom info section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location Sharing Active',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contacts Notified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
