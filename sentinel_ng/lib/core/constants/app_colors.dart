import 'package:flutter/material.dart';

/// Application color palette following Sentinel NG design system
class AppColors {
  // Primary brand colors
  static const Color primaryGreen = Color(0xFF006400);
  static const Color successGreen = Color(0xFF2E7D32);
  
  // Alert & Emergency colors
  static const Color alertRed = Color(0xFFDC143C);
  static const Color warningYellow = Color(0xFFFFD700);
  static const Color dangerDark = Color(0xFFB71C1C);
  
  // Neutral colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Status colors
  static const Color statusSubmitted = Color(0xFF1976D2);
  static const Color statusUnderReview = Color(0xFFFFA000);
  static const Color statusVerified = Color(0xFF388E3C);
  static const Color statusDismissed = Color(0xFFD32F2F);
  
  // Crime type colors
  static const Map<String, Color> crimeTypeColors = {
    'Armed Robbery': Color(0xFFB71C1C),
    'Theft': Color(0xFFE65100),
    'Assault': Color(0xFFF57F17),
    'Vandalism': Color(0xFF388E3C),
    'Cyber Crime': Color(0xFF1976D2),
    'Suspicious Activity': Color(0xFF7B1FA2),
    'Others': Color(0xFF616161),
  };

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, successGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [alertRed, dangerDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Helper methods
  static Color getCrimeTypeColor(String type) {
    return crimeTypeColors[type] ?? textSecondary;
  }

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'PENDING':
        return statusSubmitted;
      case 'UNDER_REVIEW':
        return statusUnderReview;
      case 'VERIFIED':
        return statusVerified;
      case 'DISMISSED':
      case 'REJECTED':
        return statusDismissed;
      default:
        return textSecondary;
    }
  }

  static Color getRiskLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
        return alertRed;
      case 'MEDIUM':
        return warningYellow;
      case 'LOW':
        return successGreen;
      default:
        return textSecondary;
    }
  }
}
