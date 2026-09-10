import 'dart:math' as math;

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
