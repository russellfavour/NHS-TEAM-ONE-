import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/crime_report_model.dart';

/// Crime Detail Screen — shows full details of a crime report.
///
/// Accepts report data via route extra (instant from map taps) or fetches by ID.
/// Displays media gallery including videos with playback support.
class CrimeDetailScreen extends StatefulWidget {
  final String reportId;
  /// Optional pre-loaded report data passed via route extra (e.g. from map marker).
  final Map<String, dynamic>? initialData;

  const CrimeDetailScreen({super.key, required this.reportId, this.initialData});

  @override
  State<CrimeDetailScreen> createState() => _CrimeDetailScreenState();
}

class _CrimeDetailScreenState extends State<CrimeDetailScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _reportFuture = Future.value(widget.initialData!);
    } else {
      _reportFuture = _fetchReportDetails();
    }
  }

  Future<Map<String, dynamic>> _fetchReportDetails() async {
    try {
      final apiService = ApiService();
      return await apiService.getReportDetail(widget.reportId);
    } catch (e) {
      throw Exception('Failed to load report details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (_isLoading && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || _error != null) {
            return ErrorState(
              message: snapshot.error?.toString() ?? _error!,
              onRetry: () {
                setState(() {
                  _isLoading = true;
                  _reportFuture = _fetchReportDetails();
                });
              },
            );
          }

          if (!snapshot.hasData) {
            return const EmptyState(
              icon: Icons.report_problem,
              title: 'No Report Found',
              subtitle: 'The report could not be found or has been removed.',
            );
          }

          final report = CrimeReportModel.fromJson(snapshot.data!);
          return _buildReportDetail(report);
        },
      ),
    );
  }

  Widget _buildReportDetail(CrimeReportModel report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge and report ID header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.getStatusColor(report.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.getStatusColor(report.status),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      report.statusDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getStatusColor(report.status),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#SR${report.id.substring(0, report.id.length > 8 ? 8 : report.id.length)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Crime type and risk level cards
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  icon: Icons.report_problem,
                  title: 'Crime Type',
                  value: report.type,
                  color: AppColors.getCrimeTypeColor(report.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  icon: Icons.warning,
                  title: 'Risk Level',
                  value: report.riskLevelDisplay,
                  color: AppColors.getRiskLevelColor(report.riskLevel),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description section
          _sectionCard(
            title: 'Description',
            icon: Icons.description_outlined,
            child: Text(
              report.description.isNotEmpty ? report.description : 'No description provided.',
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),

          const SizedBox(height: 20),

          // Location section with map button
          _sectionCard(
            title: 'Location',
            icon: Icons.location_on,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.alertRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordinates: ${report.location['coordinates'][1].toStringAsFixed(4)}, ${report.location['coordinates'][0].toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openMap(context, report.location),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Media/Evidence section with proper image/video gallery
          if (report.mediaUrls.isNotEmpty) ...[
            _sectionCard(
              title: 'Evidence (${report.mediaUrls.length})',
              icon: Icons.photo_library,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.mediaUrls.length,
                      itemBuilder: (context, index) {
                        final url = ApiService().resolveMediaUrl(report.mediaUrls[index]);
                        return _mediaThumbnail(context, url);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Report metadata
          _sectionCard(
            title: 'Report Information',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaRow('Submitted By', report.isAnonymous ? 'Anonymous' : (report.reporter?.name ?? 'Unknown')),
                const SizedBox(height: 8),
                _metaRow('Date Submitted', _formatDate(report.createdAt)),
                const SizedBox(height: 8),
                _metaRow('Last Updated', _formatDate(report.updatedAt)),
                const SizedBox(height: 8),
                _metaRow('Confirmations', '${report.confirmationCount}'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status Timeline button
          ElevatedButton.icon(
            onPressed: () {
              context.push('/report-status-timeline?id=${report.id}');
            },
            icon: const Icon(Icons.timeline),
            label: const Text('View Status Timeline'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Builds a thumbnail for a media item (image or video).
  Widget _mediaThumbnail(BuildContext context, String url) {
    final isVideo = _looksLikeVideo(url);
    return GestureDetector(
      onTap: () => _openMediaViewer(context, url),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            if (isVideo)
              Container(
                color: const Color(0xFF1B1B1F),
                child: const Center(child: Icon(Icons.play_circle_filled, size: 36, color: Colors.white70)),
              )
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, u) => Container(color: Colors.grey.shade200),
                errorWidget: (context, u, e) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.grey[500]),
                ),
              ),
            // Video indicator badge
            if (isVideo)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text('Video', style: TextStyle(fontSize: 9, color: Colors.white)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  bool _looksLikeVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.3gp');
  }

  void _openMediaViewer(BuildContext context, String url) {
    if (_looksLikeVideo(url)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FullscreenVideoPlayer(url: url)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FullscreenImageViewer(url: url)),
      );
    }
  }

  void _openMap(BuildContext context, Map<String, dynamic> location) {
    final coords = location['coordinates'];
    if (coords is List<dynamic> && coords.length == 2) {
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      context.push('/map?lat=$lat&lng=$lng');
    }
  }

  void _shareReport(BuildContext context) {
    // Placeholder for share functionality.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ])),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 20, color: AppColors.primaryGreen), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        const Divider(height: 20),
        child,
      ])),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
    ]);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== Fullscreen Media Viewers ====================

/// Fullscreen image viewer with pinch-to-zoom.
class FullscreenImageViewer extends StatelessWidget {
  final String url;
  const FullscreenImageViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, u) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, u, e) => const Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
            ),
          ),
        ),
        // Top bar with back button.
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
              const Text('Evidence Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        )),
        // Tap anywhere to close.
        Positioned.fill(
          child: GestureDetector(onTap: () => Navigator.of(context).pop(), behavior: HitTestBehavior.translucent),
        ),
      ]),
    );
  }
}

/// Fullscreen video player using video_player package.
class FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  const FullscreenVideoPlayer({super.key, required this.url});

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      controller.addListener(_onVideoStatusChanged);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not play this video: $e');
    }
  }

  void _onVideoStatusChanged() {
    if (!mounted || !_initialized) return;
    setState(() {}); // Refresh position indicator.
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoStatusChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (_error != null)
          Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ])))
        else if (!_initialized)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else
          GestureDetector(
            onTap: () {
              final controller = _controller;
              if (controller == null) return;
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

        // Top bar.
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
              const Text('Evidence Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        )),

        // Bottom controls.
        if (_initialized && _controller != null)
          Positioned(bottom: 0, left: 0, right: 0, child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withOpacity(0.55),
              child: Row(children: [
                IconButton(
                  icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 32, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: _controller!.value.position.inMilliseconds.toDouble().clamp(0.0, (_controller!.value.duration.inMilliseconds == 0 ? 1 : _controller!.value.duration.inMilliseconds).toDouble()),
                      max: _controller!.value.duration.inMilliseconds == 0 ? 1 : _controller!.value.duration.inMilliseconds.toDouble(),
                      activeColor: AppColors.primaryGreen,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => _controller?.seekTo(Duration(milliseconds: v.round())),
                    ),
                  ),
                ),
                Text(
                  '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
            ),
          )),
      ]),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ==================== Shared State Widgets ====================

/// Error state widget for displaying error messages.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget for when there's no data to display.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
