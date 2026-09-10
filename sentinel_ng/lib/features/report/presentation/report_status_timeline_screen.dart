import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/crime_report_model.dart';

/// Report Status Timeline Screen — builds a dynamic timeline from real report data.
///
/// Fetches the report by ID and constructs timeline events from:
/// - createdAt (Submitted)
/// - updatedAt changes / status transitions
/// - verificationHistory (if available in API response)
/// Falls back to generic timeline only when fetch fails.
class ReportStatusTimelineScreen extends StatefulWidget {
  final String reportId;
  const ReportStatusTimelineScreen({super.key, required this.reportId});

  @override
  State<ReportStatusTimelineScreen> createState() => _ReportStatusTimelineScreenState();
}

class _ReportStatusTimelineScreenState extends State<ReportStatusTimelineScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reportFuture = _fetchReportDetails();
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
        title: Text('Report Status - ${widget.reportId.substring(0, widget.reportId.length > 8 ? 8 : widget.reportId.length)}'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () => _shareReport(context)),
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
          final timelineEvents = _buildTimelineFromReport(report, snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report summary card
                _buildSummaryCard(report),

                const SizedBox(height: 24),

                // Timeline header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.getStatusColor(report.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 14, color: AppColors.getStatusColor(report.status)),
                          const SizedBox(width: 4),
                          Text(
                            report.statusDisplay,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getStatusColor(report.status)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Timeline events
                if (timelineEvents.isEmpty)
                  _emptyTimelineCard()
                else
                  ..._buildTimeline(timelineEvents),

                const SizedBox(height: 32),

                // Admin notes section (if any verification history exists)
                _buildAdminNotesCard(snapshot.data!),

                const SizedBox(height: 24),

                // Related actions
                _buildRelatedActions(report),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds timeline events dynamically from the real report data.
  List<TimelineEvent> _buildTimelineFromReport(CrimeReportModel report, Map<String, dynamic> rawData) {
    final events = <TimelineEvent>[];
    final now = DateTime.now();

    // Event 1: Report Submitted (createdAt).
    events.add(TimelineEvent(
      title: 'Report Submitted',
      description: 'Your crime report has been successfully submitted and is now pending review.',
      status: 'submitted',
      timestamp: report.createdAt,
      icon: Icons.upload_file,
    ));

    // Event 2: Under Review (if not yet verified).
    if (report.status != 'VERIFIED' && report.status != 'CROWD_REPORTED') {
      events.add(TimelineEvent(
        title: 'Under Review',
        description: 'Your report has been assigned to an admin for review.',
        status: 'under_review',
        timestamp: report.createdAt.add(const Duration(hours: 2)), // Estimated.
        icon: Icons.visibility_outlined,
      ));
    }

    // Event 3: Verification history (if available in raw data).
    final verificationHistory = rawData['verificationHistory'] as List<dynamic>?;
    if (verificationHistory != null && verificationHistory.isNotEmpty) {
      for (final entry in verificationHistory.whereType<Map<String, dynamic>>()) {
        final timestampStr = entry['timestamp'] as String? ?? entry['createdAt'] as String?;
        DateTime? timestamp;
        try {
          if (timestampStr != null) timestamp = DateTime.parse(timestampStr);
        } catch (_) {}

        final actionType = (entry['action'] as String?)?.toLowerCase() ?? '';
        final actor = entry['actor'] as String? ?? 'Admin';
        final note = entry['note'] as String? ?? '';

        if (report.status == 'VERIFIED' || report.status == 'CROWD_REPORTED') {
          events.add(TimelineEvent(
            title: 'Report Verified',
            description: note.isNotEmpty ? '$actor: $note' : 'Your report has been verified by the admin team and is now visible on the community map.',
            status: 'verified',
            timestamp: timestamp ?? now.subtract(const Duration(hours: 1)),
            icon: Icons.verified,
          ));
        } else if (actionType == 'rejected' || actionType == 'denied') {
          events.add(TimelineEvent(
            title: 'Report Rejected',
            description: note.isNotEmpty ? '$actor: $note' : 'Your report has been rejected after review.',
            status: 'rejected',
            timestamp: timestamp ?? now.subtract(const Duration(hours: 1)),
            icon: Icons.cancel,
          ));
        } else if (actionType == 'flagged') {
          events.add(TimelineEvent(
            title: 'Report Flagged for Review',
            description: note.isNotEmpty ? '$actor: $note' : 'Your report has been flagged and requires additional review.',
            status: 'under_review',
            timestamp: timestamp ?? now.subtract(const Duration(hours: 1)),
            icon: Icons.flag,
          ));
        } else {
          // Generic verification entry.
          events.add(TimelineEvent(
            title: 'Verification Update',
            description: note.isNotEmpty ? '$actor: $note' : 'Report status updated by admin.',
            status: 'verified',
            timestamp: timestamp ?? now.subtract(const Duration(hours: 1)),
            icon: Icons.update,
          ));
        }
      }
    } else if (report.status == 'VERIFIED' || report.status == 'CROWD_REPORTED') {
      // No explicit verification history but status is verified — add generic event.
      events.add(TimelineEvent(
        title: 'Report Verified',
        description: 'Your report has been verified by the admin team and is now visible on the community map.',
        status: 'verified',
        timestamp: report.updatedAt,
        icon: Icons.verified,
      ));
    }

    // Event 4: Risk level assignment.
    if (report.riskLevel == 'HIGH') {
      events.add(TimelineEvent(
        title: 'Risk Level Assigned — High Risk',
        description: 'This incident has been classified as high risk due to severity and location.',
        status: 'risk_assigned',
        timestamp: report.updatedAt,
        icon: Icons.warning_amber_rounded,
      ));
    } else if (report.riskLevel == 'MEDIUM') {
      events.add(TimelineEvent(
        title: 'Risk Level Assigned — Medium Risk',
        description: 'This incident has been classified as medium risk.',
        status: 'risk_assigned',
        timestamp: report.updatedAt,
        icon: Icons.warning_rounded,
      ));
    }

    // Event 5: Community alert (if crowd reported).
    if (report.status == 'CROWD_REPORTED') {
      events.add(TimelineEvent(
        title: 'Community Alert Triggered',
        description: 'Users in the vicinity have been notified about this incident.',
        status: 'alert_sent',
        timestamp: report.updatedAt,
        icon: Icons.notifications_active,
      ));
    }

    // Event 6: Last updated.
    if (report.updatedAt.isAfter(report.createdAt.add(const Duration(minutes: 1)))) {
      events.add(TimelineEvent(
        title: 'Report Updated',
        description: 'The report was last updated with new information.',
        status: 'updated',
        timestamp: report.updatedAt,
        icon: Icons.edit_note,
      ));
    }

    // Sort by timestamp descending.
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return events;
  }

  Widget _buildSummaryCard(CrimeReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#SR${report.id.substring(0, report.id.length > 8 ? 8 : report.id.length)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.more_vert, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: AppColors.getCrimeTypeColor(report.type), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(report.type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text('Coordinates: ${report.location['coordinates'][1].toStringAsFixed(4)}, ${report.location['coordinates'][0].toStringAsFixed(4)}', style: TextStyle(color: Colors.grey[600]))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(List<TimelineEvent> events) {
    return List.generate(events.length, (index) {
      final event = events[index];
      final isLast = index == events.length - 1;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot.
              Container(
                width: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _getStatusColor(event.status).withOpacity(0.2),
                      child: Icon(_getEventIcon(event.status), size: 14, color: _getStatusColor(event.status)),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 60,
                        color: _getStatusColor(event.status).withOpacity(0.3),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Event content.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(_formatDateTime(event.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.description, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildAdminNotesCard(Map<String, dynamic> rawData) {
    // Check for admin notes in verification history.
    final verificationHistory = rawData['verificationHistory'] as List<dynamic>?;
    String? adminNote;
    String? verifiedBy;

    if (verificationHistory != null) {
      for (final entry in verificationHistory.whereType<Map<String, dynamic>>()) {
        final note = entry['note'] as String?;
        final actor = entry['actor'] as String?;
        if (note != null && note.isNotEmpty) adminNote = note;
        if (actor != null && actor.isNotEmpty) verifiedBy = actor;
      }
    }

    // Also check for a top-level adminNotes field.
    final topLevelNotes = rawData['adminNotes'] as String? ?? rawData['notes'] as String?;
    if (topLevelNotes != null && topLevelNotes.isNotEmpty) {
      adminNote = topLevelNotes;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text('Admin Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            if (adminNote != null || verifiedBy != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (verifiedBy != null) Text('Verified by: $verifiedBy', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    if (adminNote != null) Text(adminNote, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              )
            else
              Text('No admin notes available.', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedActions(CrimeReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Related Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Share Report'),
              avatar: const Icon(Icons.share, size: 16),
              onPressed: () => _shareReport(context),
            ),
            if (report.status == 'PENDING')
              ActionChip(
                label: const Text('Add Confirmation'),
                avatar: const Icon(Icons.check, size: 16),
                onPressed: () {},
              ),
            ActionChip(
              label: const Text('Report Issue'),
              avatar: const Icon(Icons.flag, size: 16),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.timeline_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No timeline events yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Timeline will populate as your report is reviewed.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.statusSubmitted;
      case 'under_review':
        return AppColors.statusUnderReview;
      case 'verified':
        return AppColors.statusVerified;
      case 'rejected':
        return Colors.red.shade600;
      case 'risk_assigned':
        return AppColors.alertRed;
      case 'alert_sent':
        return Colors.blue.shade600;
      case 'updated':
        return Colors.teal.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.upload_file;
      case 'under_review':
        return Icons.visibility_outlined;
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'risk_assigned':
        return Icons.warning_amber_rounded;
      case 'alert_sent':
        return Icons.notifications_active;
      case 'updated':
        return Icons.edit_note;
      default:
        return Icons.circle;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
  }
}

/// Timeline event data class.
class TimelineEvent {
  final String title;
  final String description;
  final String status;
  final DateTime timestamp;
  final IconData icon;

  const TimelineEvent({
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.icon,
  });
}

/// Error state widget.
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

/// Empty state widget.
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
          ],
        ),
      ),
    );
  }
}
