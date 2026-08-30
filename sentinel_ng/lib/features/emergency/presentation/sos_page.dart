import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// SOS Emergency Page - Triggers emergency alert to contacts and community
class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isActivated = false;
  Timer? _countdownTimer;
  int _countdownSeconds = 30;
  String? _errorMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get location: ${e.toString()}');
    }
  }

  void _activateSOS() async {
    if (_isActivated) return;
    
    setState(() => _isActivated = true);
    _countdownSeconds = 30;
    
    // Get emergency contacts count for display
    try {
      final apiService = ApiService();
      await apiService.getSOSContacts();
    } catch (e) {
      debugPrint('Could not fetch SOS contacts: $e');
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _sendSOSAlert();
      }
    });
  }

  Future<void> _sendSOSAlert() async {
    try {
      final apiService = ApiService();
      
      // Prepare location data
      Map<String, dynamic> location;
      if (_currentPosition != null) {
        location = <String, dynamic>{
          'type': 'Point',
          'coordinates': [
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ],
        };
      } else {
        // Default coordinates (Lagos, Nigeria as fallback)
        location = <String, dynamic>{
          'type': 'Point',
          'coordinates': [3.3911, 6.5244],
        };
      }

      await apiService.triggerSOS(location: location);
      
      if (mounted) {
        context.go('/live-emergency');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to send SOS alert. Please try again.');
      // Still navigate after a short delay even on error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/live-emergency');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isActivated ? null : () => Navigator.of(context).pop(),
        ),
      ),
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
              if (!_isActivated) ...[
                // Pulsing SOS button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 250 + (_pulseController.value * 30),
                      height: 250 + (_pulseController.value * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: ElevatedButton(
                    onPressed: _activateSOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(32),
                      elevation: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 64, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Tap to send emergency alert',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your location will be shared with contacts and community',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                // Location status indicator or error message
                if (_currentPosition != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

              ] else ...[
                // Active SOS state
                Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  'Help is on the way!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emergency alert sent to your contacts',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 32),

                // Countdown timer circle
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_countdownSeconds',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cancel in $_countdownSeconds seconds',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),

                // Cancel button
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    _countdownTimer?.cancel();
                    setState(() => _isActivated = false);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Alert'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),

              ],
            ],
          ),
        ),
      ),
    );
  }
}
