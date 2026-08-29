import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _activateSOS() {
    setState(() => _isActivated = true);
    _countdownSeconds = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        // Navigate to live emergency screen
        Navigator.of(context).pushReplacementNamed('/live-emergency');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _isActivated ? AppColors.dangerGradient : LinearGradient(colors: [AppColors.alertRed, Colors.red.shade900], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!_isActivated) ...[
            // Pulsing SOS button
            AnimatedBuilder(animation: _pulseController, builder: (context, child) {
              return Container(
                width: 250 + (_pulseController.value * 30),
                height: 250 + (_pulseController.value * 30),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
              );
            }),
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: _activateSOS,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: CircleBorder(), padding: EdgeInsets.all(32)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.warning_amber_rounded, size: 64, color: Colors.white),
                  SizedBox(height: 8),
                  Text('SOS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ),
            ),
            SizedBox(height: 48),
            Text('Tap to send emergency alert', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9))),
            SizedBox(height: 16),
            Text('Your location will be shared with contacts and community', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
          ] else ...[
            // Active SOS state
            Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text('Help is on the way!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16),
            Text('Emergency alert sent to your contacts', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
            SizedBox(height: 32),
            // Countdown timer
            Container(padding: EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Text('$_countdownSeconds', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white))),
            SizedBox(height: 16),
            Text('Cancel in $_countdownSeconds seconds', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ],
        ])),
      ),
    );
  }
}
