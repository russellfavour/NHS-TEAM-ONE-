import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Free geocoding + routing built on public OpenStreetMap services.
///
/// - Nominatim (https://nominatim.openstreetmap.org) for address search,
///   reverse geocoding and nearby POI lookup. No API key required.
///   Usage policy: max 1 request/second — requests are throttled here.
/// - OSRM public server (https://router.project-osrm.org) for driving routes.
class GeocodingService {
  GeocodingService._internal()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            // Nominatim requires a descriptive User-Agent.
            'User-Agent': 'SentinelNG/1.0 (community safety app; contact: dev@sentinelng.app)',
            'Accept': 'application/json',
          },
        ));

  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;

  final Dio _dio;

  // Nominatim usage policy: keep at least ~1s between requests.
  DateTime _lastNominatimRequest = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _nominatimGate() async {
    final elapsed = DateTime.now().difference(_lastNominatimRequest);
    if (elapsed < const Duration(milliseconds: 1050)) {
      await Future<void>.delayed(const Duration(milliseconds: 1050) - elapsed);
    }
    _lastNominatimRequest = DateTime.now();
  }

  /// A geocoded place.
  class GeoResult {
    final double lat;
    final double lng;
    final String displayName;
    const GeoResult({required this.lat, required this.lng, required this.displayName});
  }

  /// A computed driving route.
  class RouteResult {
    /// Ordered [lng, lat] coordinate pairs.
    final List<List<double>> coordinates;
    final double distanceMeters;
    final double durationSeconds;

    const RouteResult({
      required this.coordinates,
      required this.distanceMeters,
      required this.durationSeconds,
    });

    String get distanceDisplay {
      if (distanceMeters < 1000) return '${distanceMeters.round()} m';
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }

    String get durationDisplay {
      final minutes = (durationSeconds / 60).round();
      if (minutes < 60) return '$minutes min';
      final hours = minutes ~/ 60;
      return '${hours}h ${minutes % 60}min';
    }
  }

  /// Search for addresses/places by free text. Returns up to [limit] results.
  Future<List<GeoResult>> searchAddress(String query, {int limit = 5}) async {
    await _nominatimGate();
    final response = await _dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query.trim(),
        'format': 'jsonv2',
        'limit': limit,
        'addressdetails': 0,
      },
    );
    return _parseNominatim(response.data);
  }

  /// Find nearby points of interest (e.g. "police station", "hospital")
  /// within [radiusKm] of the given center point.
  Future<List<GeoResult>> findNearbyPlaces(
    String query, {
    required double lat,
    required double lng,
    double radiusKm = 5,
    int limit = 12,
  }) async {
    await _nominatimGate();

    // Build a bounding box around the center.
    final dLat = radiusKm / 110.574;
    final dLng = radiusKm / (111.320 * math.cos(lat.clamp(-85, 85) * math.pi / 180));
    final viewbox = '${(lng - dLng).toStringAsFixed(6)},${(lat + dLat).toStringAsFixed(6)},'
        '${(lng + dLng).toStringAsFixed(6)},${(lat - dLat).toStringAsFixed(6)}';

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'jsonv2',
          'limit': limit,
          'viewbox': viewbox,
          'bounded': 1,
          'addressdetails': 0,
        },
      );
      var results = _parseNominatim(response.data);

      // If the strict bounded search came up empty (sparse OSM data), retry
      // without the bounding box so the user still gets useful nearby hits.
      if (results.isEmpty) {
        await _nominatimGate();
        final fallback = await _dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': '$query near $lat, $lng'.trim(),
            'format': 'jsonv2',
            'limit': limit,
            'addressdetails': 0,
          },
        );
        results = _parseNominatim(fallback.data);
      }

      // Keep only places within the requested radius.
      return results.where((r) => _haversineKm(lat, lng, r.lat, r.lng) <= radiusKm * 1.2).toList();
    } on DioException {
      rethrow;
    }
  }

  /// Reverse geocode coordinates to a human-readable address (or null).
  Future<String?> reverseGeocode(double lat, double lng) async {
    await _nominatimGate();
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat.toStringAsFixed(6), 'lon': lng.toStringAsFixed(6), 'format': 'jsonv2'},
      );
      if (response.data is Map<String, dynamic>) {
        final name = response.data['display_name'];
        return name is String && name.isNotEmpty ? name : null;
      }
    } on DioException {
      // Reverse geocoding is best-effort — callers show coordinates instead.
    }
    return null;
  }

  /// Compute a driving route between two points via the public OSRM server.
  /// Returns null when the service is unreachable (callers fall back to a
  /// straight line).
  Future<RouteResult?> routeDriving(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    try {
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving/'
        '${fromLng.toStringAsFixed(6)},${fromLat.toStringAsFixed(6)};'
        '${toLng.toStringAsFixed(6)},${toLat.toStringAsFixed(6)}',
        queryParameters: {'overview': 'full', 'geometries': 'geojson'},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['code'] == 'Ok') {
        final routes = data['routes'];
        if (routes is List<dynamic> && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coordsRaw = geometry?['coordinates'];
          if (coordsRaw is List<dynamic>) {
            return RouteResult(
              coordinates: coordsRaw
                  .whereType<Map<String, dynamic>>()
                  .map((c) => [
                        (c[0] as num).toDouble(), // lng
                        (c[1] as num).toDouble(), // lat
                      ])
                  .toList(),
              distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
              durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
            );
          }
        }
      }
    } on DioException {
      // Fall through to null — caller uses straight-line fallback.
    }
    return null;
  }

  List<GeoResult> _parseNominatim(dynamic data) {
    if (data is! List<dynamic>) return [];
    final results = <GeoResult>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        try {
          final lat = double.parse(item['lat'] as String);
          final lng = double.parse(item['lon'] as String);
          results.add(GeoResult(
            lat: lat,
            lng: lng,
            displayName: item['display_name'] as String? ?? '',
          ));
        } catch (_) {
          // Skip malformed entries.
        }
      }
    }
    return results;
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Haversine distance in km (public for safety-score calculations).
  static double haversineKm(double lat1, double lng1, double lat2, double lng2) =>
      _haversineKm(lat1, lng1, lat2, lng2);
}
