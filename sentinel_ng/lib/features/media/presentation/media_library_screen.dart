import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

/// Media Library — every photo and video the user has attached to their reports.
///
/// Sources: each report's `mediaUrls` array plus its structured `evidence`
/// field (entries of {type, url, uploadedAt}). Items are de-duplicated by URL.
class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class MediaItem {
  final String resolvedUrl;
  final bool isVideo;
  final String reportType; // crime type of the parent report (for context)
  final DateTime? uploadedAt;

  const MediaItem({required this.resolvedUrl, required this.isVideo, required this.reportType, this.uploadedAt});
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<MediaItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _api.getMyReports();
      if (!mounted) return;

      final seen = <String>{};
      final items = <MediaItem>[];

      for (final raw in reports.whereType<Map<String, dynamic>>()) {
        final reportType = raw['type'] as String? ?? 'Report';

        // 1) mediaUrls array
        final urls = raw['mediaUrls'];
        if (urls is List<dynamic>) {
          for (final url in urls.whereType<String>()) {
            _addItem(items, seen, url, reportType);
          }
        }

        // 2) structured evidence entries: [{type, url, uploadedAt}]
        final evidence = raw['evidence'];
        if (evidence is List<dynamic>) {
          for (final entry in evidence.whereType<Map<String, dynamic>>()) {
            final url = entry['url'] as String?;
            if (url == null || url.isEmpty) continue;
            final type = (entry['type'] as String?)?.toLowerCase() ?? '';
            final uploadedAt = entry['uploadedAt'];
            DateTime? when;
            if (uploadedAt is String) {
              try {
                when = DateTime.parse(uploadedAt);
              } catch (_) {}
            }
            items.add(MediaItem(
              resolvedUrl: _api.resolveMediaUrl(url),
              isVideo: type.contains('video') || _looksLikeVideo(url),
              reportType: reportType,
              uploadedAt: when,
            ));
            seen.add(_api.resolveMediaUrl(url));
          }
        }
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your media library. $e';
        _loading = false;
      });
    }
  }

  void _addItem(List<MediaItem> items, Set<String> seen, String url, String reportType) {
    final resolved = _api.resolveMediaUrl(url);
    if (seen.contains(resolved)) return;
    seen.add(resolved);
    items.add(MediaItem(resolvedUrl: resolved, isVideo: _looksLikeVideo(url), reportType: reportType));
  }

  bool _looksLikeVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.3gp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _loadMedia),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_off, size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(onPressed: _loadMedia, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ]),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.photo_library_outlined, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No media yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text('Photos and videos you attach to reports will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMedia,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _mediaTile(_items[index]),
                      ),
                    ),
    );
  }

  Widget _mediaTile(MediaItem item) {
    return GestureDetector(
      onTap: () {
        if (item.isVideo) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullscreenVideoPlayer(url: item.resolvedUrl, label: item.reportType)));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullscreenImageViewer(url: item.resolvedUrl, label: item.reportType)));
        }
      },
      child: Stack(fit: StackFit.expand, children: [
        if (item.isVideo)
          Container(
            color: const Color(0xFF1B1B1F),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_circle_fill, size: 42, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 6),
              Text('Video', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            ]),
          )
        else
          CachedNetworkImage(
            imageUrl: item.resolvedUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade200, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade300,
              child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.grey[500]),
            ),
          ),

        // Report-type badge
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(6)),
            child: Text(item.reportType, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.white)),
          ),
        ),

        if (item.isVideo)
          Positioned(right: 6, top: 6, child: Icon(Icons.videocam_rounded, size: 16, color: Colors.white.withOpacity(0.8))),
      ]),
    );
  }
}

/// Fullscreen image viewer with tap-to-close.
class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  final String label;
  const _FullscreenImageViewer({required this.url, required this.label});

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
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ]),
          ),
        )),
        // Tap anywhere to close (but not the back button area)
        Positioned.fill(
          child: GestureDetector(onTap: () => Navigator.of(context).pop(), behavior: HitTestBehavior.translucent),
        ),
      ]),
    );
  }
}

/// Fullscreen video player using video_player.
class _FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  final String label;
  const _FullscreenVideoPlayer({required this.url, required this.label});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
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
      // Keep the UI in sync with playback state.
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

        // Top bar
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
              Expanded(child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ]),
          ),
        )),

        // Bottom controls
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
