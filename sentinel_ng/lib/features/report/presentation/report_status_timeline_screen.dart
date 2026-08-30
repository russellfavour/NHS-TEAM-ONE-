import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Report Status Timeline Screen - Shows detailed timeline of a report's status changes
class ReportStatusTimelineScreen extends StatefulWidget {
  final String reportId;
  const ReportStatusTimelineScreen({super.key, required this.reportId});

  @override
  State<ReportStatusTimelineScreen> createState() => _ReportStatusTimelineScreenState();
}

class _ReportStatusTimelineScreenState extends State<ReportStatusTimelineScreen> {
  // Mock timeline data - in real app, fetch from API
  final List<TimelineEvent> _timelineEvents = [
    TimelineEvent(
      title: 'Report Submitted',
      description: 'Your crime report has been successfully submitted and is now pending review.',
      status: 'submitted',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      icon: Icons.upload_file,
    ),
    TimelineEvent(
      title: 'Under Review',
      description: 'Your report has been assigned to an admin for review.',
      status: 'under_review',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      icon: Icons.visibility_outlined,
    ),
    TimelineEvent(
      title: 'Verified',
      description: 'Your report has been verified by the admin team and is now visible on the community map.',
      status: 'verified',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.verified,
    ),
    TimelineEvent(
      title: 'Risk Level Assigned - High Risk',
      description: 'This incident has been classified as high risk due to severity and location.',
      status: 'risk_assigned',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.warning_amber_rounded,
    ),
    TimelineEvent(
      title: 'Community Alert Triggered',
      description: 'Users in the vicinity have been notified about this incident.',
      status: 'alert_sent',
      timestamp: DateTime.now().subtract(const Duration(hours: 20)),
      icon: Icons.notifications_active,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Status - ${widget.reportId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report summary card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Timeline header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statusVerified.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.statusVerified),
                      const SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusVerified)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timeline
            ..._buildTimeline(),

            const SizedBox(height: 32),

            // Admin notes section (if any)
            _buildAdminNotesCard(),

            const SizedBox(height: 24),

            // Related actions
            _buildRelatedActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#SR${widget.reportId.substring(0, widget.reportId.length > 8 ? 8 : widget.reportId.length)}', 
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
                  decoration: BoxDecoration(color: AppColors.alertRed, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('Armed Robbery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text('Lagos Mainland, near Ikeja GRA', style: TextStyle(color: Colors.grey[600]))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeline() {
    return List.generate(_timelineEvents.length, (index) {
      final event = _timelineEvents[index];
      final isLast = index == _timelineEvents.length - 1;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
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

              // Event content
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

  Widget _buildAdminNotesCard() {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified by: Admin Team', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Report confirmed through cross-referencing with community reports and available evidence.', 
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedActions() {
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
              onPressed: () {},
            ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.statusSubmitted;
      case 'under_review':
        return AppColors.statusUnderReview;
      case 'verified':
        return AppColors.statusVerified;
      case 'risk_assigned':
        return AppColors.alertRed;
      case 'alert_sent':
        return Colors.blue.shade600;
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
      case 'risk_assigned':
        return Icons.warning_amber_rounded;
      case 'alert_sent':
        return Icons.notifications_active;
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
}

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
