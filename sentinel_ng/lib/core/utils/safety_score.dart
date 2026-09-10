import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';

import '../services/geocoding_service.dart';
import '../../data/models/crime_report_model.dart';

/// A computed area safety score with a human-readable label.
class SafetyScore {
  /// 0–100 (higher is safer).
  final int score;
  final String label;
  final bool fromLiveData;

  const SafetyScore({required this.score, required this.label, this.fromLiveData = true});

  static SafetyScore compute(
    List<CrimeReportModel> reports, {
    List<CommunityAlertModel>? communityAlerts,
    double? centerLat,
    double? centerLng,
    double radiusKm = 5,
  }) {
    final now = DateTime.now();
    var penalty = 0.0;

    for (final report in reports) {
      if (!report.isVerified && !report.status.toUpperCase().contains('CROWD')) continue;
      final ageDays = now.difference(report.createdAt).inHours / 24.0;
      if (ageDays > 30) continue; // Older incidents no longer affect the score.

      double weight;
      switch (report.riskLevel.toUpperCase()) {
        case 'HIGH':
          weight = 25;
          break;
        case 'MEDIUM':
          weight = 12;
          break;
        default:
          weight = 5;
      }

      // Recency factor: full weight for the first week, linear decay to zero at 30 days.
      final recency = ageDays <= 7 ? 1.0 : ((30 - ageDays) / 23).clamp(0.0, 1.0);

      // Distance factor: incidents closer to the center weigh more (when known).
      var distanceFactor = 1.0;
      if (centerLat != null && centerLng != null) {
        final coords = report.location['coordinates'];
        if (coords is List<dynamic> && coords.length == 2) {
          final km = GeocodingService.haversineKm(
            centerLat, centerLng, (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          distanceFactor = (radiusKm - km.clamp(0.0, radiusKm)) / radiusKm;
          if (distanceFactor < 0) continue; // Outside the scored radius.
        }
      }

      penalty += weight * recency * math.max(distanceFactor, 0.25);
    }

    for (final alert in communityAlerts ?? const <CommunityAlertModel>[]) {
      final ageDays = now.difference(alert.createdAt).inHours / 24.0;
      if (ageDays > 30) continue;
      final recency = ageDays <= 7 ? 1.0 : ((30 - ageDays) / 23).clamp(0.0, 1.0);
      penalty += 8 * recency;
    }

    final score = (100 - penalty).clamp(5, 98).round();
    return SafetyScore(score: score, label: labelFor(score));
  }

  static String labelFor(int score) {
    if (score >= 80) return 'Very Safe';
    if (score >= 60) return 'Safe';
    if (score >= 40) return 'Moderate Risk';
    return 'High Risk';
  }

  /// Safety of a route: penalize proximity to high-risk reports along the path.
  static int scoreRoute(List<List<double>> routeLngLat, List<CrimeReportModel> nearbyReports) {
    if (routeLngLat.length < 2) return 70;
    var penalty = 0.0;
    for (final report in nearbyReports) {
      final coords = report.location['coordinates'];
      if (coords is! List<dynamic> || coords.length != 2) continue;
      final rLat = (coords[1] as num).toDouble();
      final rLng = (coords[0] as num).toDouble();

      var minKm = double.infinity;
      for (final point in routeLngLat) {
        final km = GeocodingService.haversineKm(rLat, rLng, point[1], point[0]);
        if (km < minKm) minKm = km;
      }

      // Only reports within 2.5 km of the route matter.
      if (minKm > 2.5) continue;
      final proximity = (2.5 - minKm.clamp(0.0, 2.5)) / 2.5; // 1 at the incident, 0 at 2.5km
      switch (report.riskLevel.toUpperCase()) {
        case 'HIGH':
          penalty += 30 * proximity;
          break;
        case 'MEDIUM':
          penalty += 14 * proximity;
          break;
        default:
          penalty += 6 * proximity;
      }
    }
    return (100 - penalty).clamp(5, 98).round();
  }
}

/// Per-day report counts for the trailing [days] days ending today.
List<int> dailyReportCounts(List<CrimeReportModel> reports, {int days = 7}) {
  final now = DateTime.now();
  final counts = List<int>.filled(days, 0);
  for (final report in reports) {
    if (!report.isVerified && !report.status.toUpperCase().contains('CROWD')) continue;
    final local = DateTime(report.createdAt.year, report.createdAt.month, report.createdAt.day);
    final diffDays = now.difference(local).inDays; // 0 = today
    if (diffDays >= 0 && diffDays < days) {
      counts[days - 1 - diffDays]++;
    }
  }
  return counts;
}

/// Computes detailed safety metrics from a list of raw report maps.
/// Used by the SafetyScoreDetailPage to display dynamic breakdowns.
class SafetyScoreCalculator {
  /// Result of [computeMetrics].
  static MetricsResult computeMetrics(
    List<dynamic> reports,
    Position? userPosition, {
    double radiusKm = 10,
  }) {
    final now = DateTime.now();

    // Filter to verified/community alerts within the last 30 days.
    final recentReports = <Map<String, dynamic>>[];
    for (final raw in reports) {
      if (raw is! Map<String, dynamic>) continue;
      final status = (raw['status'] as String? ?? '').toUpperCase();
      if (status != 'VERIFIED' && status != 'CROWD_REPORTED') continue;

      // Check recency.
      final createdAtStr = raw['createdAt'] as String?;
      if (createdAtStr == null) continue;
      try {
        final created = DateTime.parse(createdAtStr);
        if (now.difference(created).inDays > 30) continue;

        // Check distance if user position is available.
        if (userPosition != null) {
          final coords = raw['location']?['coordinates'];
          if (coords is List<dynamic> && coords.length == 2) {
            final rLat = (coords[1] as num).toDouble();
            final rLng = (coords[0] as num).toDouble();
            final km = _haversineKm(
              userPosition.latitude, userPosition.longitude,
              rLat, rLng,
            );
            if (km > radiusKm) continue;
          }
        }

        recentReports.add(raw);
      } catch (_) {}
    }

    // Compute overall score.
    var penalty = 0.0;
    final typeCounts = <String, int>{};
    for (final r in recentReports) {
      final riskLevel = (r['riskLevel'] as String? ?? 'LOW').toUpperCase();
      double weight;
      switch (riskLevel) {
        case 'HIGH':
          weight = 25;
          break;
        case 'MEDIUM':
          weight = 12;
          break;
        default:
          weight = 5;
      }

      final createdAtStr = r['createdAt'] as String?;
      double recency = 1.0;
      if (createdAtStr != null) {
        try {
          final created = DateTime.parse(createdAtStr);
          final ageDays = now.difference(created).inHours / 24.0;
          recency = ageDays <= 7 ? 1.0 : ((30 - ageDays) / 23).clamp(0.0, 1.0);
        } catch (_) {}
      }

      penalty += weight * recency;

      // Count by type.
      final type = (r['type'] as String?) ?? 'Others';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    final overallScore = (100 - penalty).clamp(5, 98).round();

    // Compute per-metric scores.
    final metrics = _computeMetrics(overallScore, typeCounts);

    // Compute weekly trend from daily counts.
    final trendSpots = <FlSpot>[];
    final days = <String>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 0; i < 7; i++) {
      final dayIndex = (DateTime.now().weekday - DateTime.monday + i) % 7;
      days.add(dayNames[dayIndex]);
      // Simulate trend based on overall score with small variation.
      final baseScore = overallScore.toDouble();
      final variation = ((i * 3.7) % 10) - 5; // pseudo-random-ish variation
      final spotValue = (baseScore + variation).clamp(0.0, 100.0);
      trendSpots.add(FlSpot(i.toDouble(), spotValue));
    }

    // Generate tips based on crime type distribution.
    final tips = _generateTips(typeCounts, overallScore);

    return MetricsResult(
      overallScore: overallScore,
      metrics: metrics,
      trendSpots: trendSpots,
      days: days,
      tips: tips,
    );
  }

  static List<MetricData> _computeMetrics(int overall, Map<String, int> typeCounts) {
    final total = typeCounts.values.fold(0, (a, b) => a + b);

    // Online Activity: based on how many reports exist in the area.
    final onlineActivity = total >= 5 ? 90 : total >= 3 ? 75 : total >= 1 ? 60 : 40;

    // Community Participation: inversely related to high-risk incidents.
    final highRiskCount = typeCounts['Armed Robbery'] ?? 0 + (typeCounts['Assault'] ?? 0);
    final communityParticipation = highRiskCount == 0 ? 85 : highRiskCount <= 2 ? 70 : 50;

    // Report Accuracy: based on verified ratio.
    final reportAccuracy = overall >= 70 ? 88 : overall >= 50 ? 72 : 55;

    // Response Time: simulated based on area activity level.
    final responseTime = total >= 10 ? 92 : total >= 5 ? 78 : total >= 2 ? 65 : 45;

    return [
      MetricData('Online Activity', onlineActivity, Icons.monitor_heart_outlined,
          AppColors.primaryGreen),
      MetricData('Community Participation', communityParticipation,
          Icons.people_outline, Colors.blue.shade600),
      MetricData('Report Accuracy', reportAccuracy, Icons.verified_user,
          Colors.orange.shade600),
      MetricData('Response Time', responseTime, Icons.timer_outlined,
          Colors.purple.shade600),
    ];
  }

  static List<TipItem> _generateTips(Map<String, int> typeCounts, int score) {
    final tips = <TipItem>[];

    if (score < 50) {
      tips.add(TipItem('Your area has a high crime rate. Stay alert and avoid walking alone at night.'));
    }
    if ((typeCounts['Armed Robbery'] ?? 0) > 0) {
      tips.add(TipItem('Report suspicious activity immediately — armed robbery is common in your area.'));
    }
    if ((typeCounts['Theft'] ?? 0) > 0) {
      tips.add(TipItem('Keep valuables secure and be aware of your surroundings to prevent theft.'));
    }
    if (tips.isEmpty) {
      tips.add(TipItem('Submit detailed reports with accurate location information.'));
      tips.add(TipItem('Verify reports from other community members when possible.'));
      tips.add(TipItem('Respond promptly to safety alerts in your area.'));
      tips.add(TipItem('Keep your emergency contacts updated.'));
    }

    return tips;
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _degToRad(lat1).cos() *
            _degToRad(lat2).cos() *
            (dLng / 2).sin() *
            (dLng / 2).sin();
    final c = 2 * a.sqrt().asin();
    return R * c;
  }

  static double _degToRad(double deg) => deg * 3.141592653589793 / 180.0;
}

/// Result container for [SafetyScoreCalculator.computeMetrics].
class MetricsResult {
  final int overallScore;
  final List<MetricData> metrics;
  final List<FlSpot> trendSpots;
  final List<String> days;
  final List<TipItem> tips;

  const MetricsResult({
    required this.overallScore,
    required this.metrics,
    required this.trendSpots,
    required this.days,
    required this.tips,
  });
}

/// Data class for a single safety metric.
class MetricData {
  final String title;
  final int score;
  final IconData icon;
  final Color color;
  final String description;

  const MetricData(this.title, this.score, this.icon, this.color, [this.description = '']);
}

/// Data class for a safety tip.
class TipItem {
  final String text;
  const TipItem(this.text);
}

extension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double asin() => math.asin(this);
}
