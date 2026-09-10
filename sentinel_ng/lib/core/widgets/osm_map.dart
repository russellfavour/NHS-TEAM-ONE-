import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A lightweight, dependency-free OpenStreetMap tile map widget.
///
/// Renders OSM tiles (https://tile.openstreetmap.org) directly — the same open
/// source data that Leaflet uses — with pan / pinch-zoom / mouse-wheel zoom,
/// markers, polylines and radius circles. No API key or subscription required,
/// works identically on web and mobile.
class OSMMapWidget extends StatefulWidget {
  /// Initial map center (WGS84). Defaults to Lagos, Nigeria.
  final double lat;
  final double lng;

  /// Initial zoom level (3..19).
  final double initialZoom;

  /// Markers to display.
  final List<MapMarker> markers;

  /// Optional polyline (e.g. a route) drawn over the map.
  final List<LatLngPoint>? polyline;
  final Color? polylineColor;
  final double? polylineWidth;

  /// Optional radius circle (center + radius in km).
  final LatLngPoint? circleCenter;
  final double? circleRadiusKm;
  final Color? circleColor;

  /// Blue "you are here" dot.
  final LatLngPoint? userLocation;

  /// Called when the user taps the map background with the tapped coordinate.
  final ValueChanged<LatLngPoint>? onMapTap;

  /// Optional controller for programmatic centering / zooming.
  final OSMMapController? controller;

  const OSMMapWidget({
    super.key,
    this.lat = 6.5244,
    this.lng = 3.3792,
    this.initialZoom = 12,
    this.markers = const [],
    this.polyline,
    this.polylineColor,
    this.polylineWidth,
    this.circleCenter,
    this.circleRadiusKm,
    this.circleColor,
    this.userLocation,
    this.onMapTap,
    this.controller,
  });

  @override
  State<OSMMapWidget> createState() => _OSMMapWidgetState();
}

class LatLngPoint {
  final double lat;
  final double lng;
  const LatLngPoint(this.lat, this.lng);

  @override
  String toString() => 'LatLngPoint($lat, $lng)';
}

/// A marker on the map. Provide [child] for a fully custom marker widget, or
/// rely on the default colored pin (with optional icon).
class MapMarker {
  final double lat;
  final double lng;
  final Color color;
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;

  const MapMarker({
    required this.lat,
    required this.lng,
    this.color = const Color(0xFFDC143C),
    this.icon,
    this.child,
    this.onTap,
  });
}

/// Allows programmatic control of the map (center / zoom).
class OSMMapController {
  final ValueNotifier<MapCamera> _camera = ValueNotifier(const MapCamera(6.5244, 3.3792, 12));

  MapCamera get camera => _camera.value;

  void setCamera(double lat, double lng, [double? zoom]) {
    _camera.value = MapCamera(lat, lng, zoom ?? _camera.value.zoom);
  }

  void dispose() => _camera.dispose();
}

class MapCamera {
  final double lat;
  final double lng;
  final double zoom;
  const MapCamera(this.lat, this.lng, this.zoom);
}

const double _tileSize = 256.0;
const double _minZoom = 3;
const double _maxZoom = 19;
const double _maxLat = 85.051129;

class _OSMMapWidgetState extends State<OSMMapWidget> {
  late double _centerLat;
  late double _centerLng;
  late double _zoom;
  bool _controllerAttached = false;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.lat;
    _centerLng = widget.lng;
    _zoom = (widget.initialZoom).clamp(_minZoom, _maxZoom);
    if (widget.controller != null) {
      widget.controller!._camera.addListener(_onControllerCameraChanged);
      _controllerAttached = true;
    }
  }

  @override
  void didUpdateWidget(OSMMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_controllerAttached) oldWidget.controller!._camera.removeListener(_onControllerCameraChanged);
      _controllerAttached = false;
      if (widget.controller != null) {
        widget.controller!._camera.addListener(_onControllerCameraChanged);
        _controllerAttached = true;
      }
    }
  }

  void _onControllerCameraChanged() {
    final cam = widget.controller!._camera.value;
    setState(() {
      _centerLat = cam.lat;
      _centerLng = cam.lng;
      _zoom = cam.zoom.clamp(_minZoom, _maxZoom);
    });
  }

  @override
  void dispose() {
    if (_controllerAttached) widget.controller!._camera.removeListener(_onControllerCameraChanged);
    super.dispose();
  }

  // ---------- Mercator math (Web Mercator / EPSG:3857, same as Leaflet/OSM) ----------

  double get _worldPx => _tileSize * math.pow(2, _zoom).toDouble();

  double _lngToX(double lng) => (lng + 180.0) / 360.0 * _worldPx;

  double _latToY(double lat) {
    final clamped = lat.clamp(-_maxLat, _maxLat);
    final latRad = clamped * math.pi / 180.0;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * _worldPx;
  }

  double _yToLat(double y) {
    final n = math.pi - 2 * math.pi * y / _worldPx;
    return (180.0 / math.pi) * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  /// Offset of a coordinate relative to the viewport center (in logical px).
  Offset _pointOffset(double lat, double lng, Size size) {
    final dx = _lngToX(lng) - _lngToX(_centerLng);
    final dy = _latToY(lat) - _latToY(_centerLat);
    return Offset(size.width / 2 + dx, size.height / 2 + dy);
  }

  // ---------- Interaction ----------

  void _panBy(Offset delta, Size size) {
    setState(() {
      _centerLng = (_lngToX(_centerLng) - delta.dx).clamp(0.0, _worldPx) == null
          ? _centerLng
          : ((_lngToX(_centerLng) - delta.dx) / _worldPx * 360.0) - 180.0;
      final y = (_latToY(_centerLat) + delta.dy).clamp(0.0, _worldPx);
      _centerLat = _yToLat(y.toDouble()).clamp(-_maxLat, _maxLat);
    });
  }

  void _zoomBy(double factor, {Offset? anchor}) {
    setState(() {
      final newZoom = (_zoom + math.log(factor) / math.ln2).clamp(_minZoom, _maxZoom);
      if (anchor != null && mounted) {
        // Keep the point under [anchor] stationary while zooming.
        final size = Size(MediaQuery.sizeOf(context).width, MediaQuery.sizeOf(context).height);
        final targetLat = _yToLat(_latToY(_centerLat) + anchor.dy - size.height / 2);
        final targetLng = (_lngToX(_centerLng) + anchor.dx - size.width / 2) / _worldPx * 360.0 - 180.0;
        _zoom = newZoom.toDouble();
        // After zoom change, recompute so the same world point stays under anchor:
        final oldWorldX = (targetLng + 180.0) / 360.0 * (_tileSize * math.pow(2, newZoom).toDouble());
        final oldWorldY = _latToY(targetLat);
        _centerLng = (oldWorldX - size.width / 2 + anchor.dx) / _worldPx * 360.0 - 180.0;
        _centerLat = _yToLat(oldWorldY - size.height / 2 + anchor.dy).clamp(-_maxLat, _maxLat);
      } else {
        _zoom = newZoom.toDouble();
      }
    });
  }

  void _setZoom(double z) => setState(() => _zoom = z.clamp(_minZoom, _maxZoom));

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (size.width <= 0 || size.height <= 0) return const SizedBox.shrink();

      final tiles = _visibleTiles(size);

      return Listener(
        onPointerSignal: (event) {
          // Mouse wheel zoom (web / desktop).
          if (event is PointerSignalEvent && event is PointerScrollEvent && event.scrollDelta.dy != 0) {
            final factor = event.scrollDelta.dy > 0 ? 1 / 1.2 : 1.2;
            _zoomBy(factor, anchor: event.position);
          }
        },
        child: GestureDetector(
          onPanUpdate: (details) => _panBy(details.delta, size),
          onScaleUpdate: (details) {
            if (details.scale != 1.0) {
              _zoomBy(details.scale, anchor: details.focalPoint);
            }
            // Two-finger pan while pinching.
            if (details.focalPointDelta != Offset.zero) {
              _panBy(details.focalPointDelta, size);
            }
          },
          onTapUp: (details) {
            final worldX = _lngToX(_centerLng) + details.localPosition.dx - size.width / 2;
            final worldY = _latToY(_centerLat) + details.localPosition.dy - size.height / 2;
            widget.onMapTap?.call(LatLngPoint(
              _yToLat(worldY).clamp(-_maxLat, _maxLat),
              (worldX / _worldPx * 360.0) - 180.0,
            ));
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Base background while tiles load
              Container(color: const Color(0xFFD9E4DC)),

              // Tiles
              for (final t in tiles)
                Positioned(
                  left: _lngToX(_centerLng) - size.width / 2 + t.x * _tileSize,
                  top: _latToY(_centerLat) - size.height / 2 + t.y * _tileSize,
                  width: _tileSize,
                  height: _tileSize,
                  child: _TileImage(zoom: t.z, x: t.x, y: t.y),
                ),

              // Radius circle
              if (widget.circleCenter != null && widget.circleRadiusKm != null)
                Positioned.fill(
                  child: CustomPaint(painter: _CirclePainter(
                    centerOffset: _pointOffset(widget.circleCenter!.lat, widget.circleCenter!.lng, size),
                    radiusPx: _kmToPixels(widget.circleRadiusKm!, widget.circleCenter!.lat),
                    color: widget.circleColor ?? const Color(0xFF1976D2).withOpacity(0.35),
                  )),
                ),

              // Polyline (route)
              if (widget.polyline != null && widget.polyline!.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(painter: _PolylinePainter(
                    points: [for (final p in widget.polyline!) _pointOffset(p.lat, p.lng, size)],
                    color: widget.polylineColor ?? const Color(0xFF1976D2),
                    width: widget.polylineWidth ?? 5,
                  )),
                ),

              // User location dot
              if (widget.userLocation != null)
                _positionedMarker(
                  _pointOffset(widget.userLocation!.lat, widget.userLocation!.lng, size),
                  size,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4285F4),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
                ),

              // Markers
              for (final m in widget.markers)
                _positionedMarker(
                  _pointOffset(m.lat, m.lng, size),
                  size,
                  child: GestureDetector(
                    onTap: m.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: m.child ?? _defaultPin(m.color, m.icon),
                  ),
                ),

              // Zoom controls
              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _zoomButton(Icons.add, () => _setZoom(_zoom + 1)),
                    const SizedBox(height: 8),
                    _zoomButton(Icons.remove, () => _setZoom(_zoom - 1)),
                  ],
                ),
              ),

              // Attribution (OSM tile usage policy)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.white.withOpacity(0.85),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10, color: Color(0xFF333333)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _positionedMarker(Offset offset, Size size, {required Widget child}) {
    // Cull markers far outside the viewport.
    if (offset.dx < -100 || offset.dy < -100 || offset.dx > size.width + 100 || offset.dy > size.height + 100) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Transform.translate(offset: const Offset(-20, -20), child: SizedBox(width: 40, height: 40, child: Center(child: child))),
    );
  }

  Widget _defaultPin(Color color, IconData? icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: icon != null ? Icon(icon, size: 18, color: Colors.white) : null,
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20)),
      ),
    );
  }

  List<_TileCoord> _visibleTiles(Size size) {
    final z = (_zoom.round().clamp(_minZoom, _maxZoom)).toInt();
    final worldPx = _tileSize * math.pow(2, z).toDouble();
    final tilesPerWorld = (worldPx / _tileSize).round();

    final centerX = _lngToX(_centerLng);
    final centerY = _latToY(_centerLat);

    final x0 = ((centerX - size.width / 2) / _tileSize).floor();
    final x1 = ((centerX + size.width / 2) / _tileSize).ceil();
    final y0 = ((centerY - size.height / 2) / _tileSize).floor();
    final y1 = ((centerY + size.height / 2) / _tileSize).ceil();

    final result = <_TileCoord>[];
    for (var ty = y0; ty <= y1; ty++) {
      if (ty < 0 || ty >= tilesPerWorld) continue;
      for (var tx = x0; tx <= x1; tx++) {
        // Wrap horizontally like Leaflet does.
        final wrappedX = ((tx % tilesPerWorld) + tilesPerWorld) % tilesPerWorld;
        result.add(_TileCoord(z, wrappedX, ty));
      }
    }
    return result;
  }

  double _kmToPixels(double km, double lat) {
    final latRad = lat.clamp(-_maxLat, _maxLat) * math.pi / 180.0;
    // Meters per pixel at this latitude (Web Mercator):
    final metersPerPixel = 40075016.686 * math.cos(latRad) / _worldPx;
    return km * 1000 / metersPerPixel;
  }
}

class _TileCoord {
  final int z, x, y;
  const _TileCoord(this.z, this.x, this.y);
  @override
  bool operator ==(Object other) => other is _TileCoord && other.z == z && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(z, x, y);
}

class _TileImage extends StatelessWidget {
  final int zoom, x, y;
  const _TileImage({required this.zoom, required this.x, required this.y});

  String get _url => 'https://tile.openstreetmap.org/$zoom/$x/$y.png';

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _url,
      fit: BoxFit.fill,
      placeholder: (context, url) => Container(color: const Color(0xFFE3EBE5)),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFDDE6DF),
        child: Center(child: Icon(Icons.broken_image_outlined, size: 18, color: Colors.grey[400])),
      ),
    );
  }
}

class _PolylinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double width;

  _PolylinePainter({required this.points, required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    // White casing under the colored line for readability.
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.9));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color);
  }

  @override
  bool shouldRepaint(_PolylinePainter oldDelegate) =>
      points != oldDelegate.points || color != oldDelegate.color || width != oldDelegate.width;
}

class _CirclePainter extends CustomPainter {
  final Offset centerOffset;
  final double radiusPx;
  final Color color;

  _CirclePainter({required this.centerOffset, required this.radiusPx, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(centerOffset, radiusPx, Paint()..color = color.withOpacity(0.18));
    canvas.drawCircle(centerOffset, radiusPx, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color);
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) =>
      centerOffset != oldDelegate.centerOffset || radiusPx != oldDelegate.radiusPx || color != oldDelegate.color;
}
