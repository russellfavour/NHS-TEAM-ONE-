import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/crime_report_model.dart';

/// Crime Detail Screen - Shows full details of a crime report with API integration
class CrimeDetailScreen extends StatefulWidget {
  final String reportId;
  const CrimeDetailScreen({super.key, required this.reportId});

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
        title: const Text('Crime Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
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

          // Location section
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
                // Map placeholder button
                OutlinedButton.icon(
                  onPressed: () {},
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

          // Media/Evidence section
          if (report.mediaUrls.isNotEmpty) ...[
            _sectionCard(
              title: 'Evidence (${report.mediaUrls.length})',
              icon: Icons.photo_library,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.mediaUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey[500]),
                          ),
                        );
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Error state widget for displaying error messages
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

/// Empty state widget for when there's no data to display
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
