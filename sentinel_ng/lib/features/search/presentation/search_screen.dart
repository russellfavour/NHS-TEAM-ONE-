import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/crime_report_model.dart';

/// Search Page - Search for crime reports by location or type with results display
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  List<String> _recentSearches = ['Lagos Mainland', 'Armed Robbery', 'Ikeja', 'Theft', 'Victoria Island'];
  final List<Map<String, dynamic>> _popularSearches = [
    {'query': 'Crime near me', 'icon': Icons.location_on},
    {'query': 'Safe routes', 'icon': Icons.route},
    {'query': 'Police stations', 'icon': Icons.local_police},
    {'query': 'Hospitals', 'icon': Icons.local_hospital},
  ];
  
  List<CrimeReportModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _crimeTypes = [
    'Armed Robbery',
    'Theft',
    'Assault',
    'Vandalism',
    'Cyber Crime',
    'Suspicious Activity',
    'Others',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Add to recent searches if not already there
    if (!_recentSearches.contains(query.trim())) {
      setState(() {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }

    try {
      final apiService = ApiService();
      
      // Try to fetch reports with search parameters
      Map<String, dynamic> response;
      try {
        response = await apiService.getReports(
          type: _selectedType,
          limit: 50,
        );
      } catch (e) {
        debugPrint('API Error: $e');
        // Fallback to empty results with message
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      // Parse response - adapt based on actual API structure
      List<dynamic> verifiedReports = response['verified'] ?? response['reports'] ?? [];
      
      setState(() {
        _searchResults = verifiedReports
            .where((r) => r is Map<String, dynamic>)
            .map((r) => CrimeReportModel.fromJson(r as Map<String, dynamic>))
            .toList();
        
        // Filter by query if provided
        if (query.trim().isNotEmpty) {
          final lowerQuery = query.toLowerCase();
          _searchResults = _searchResults.where((report) {
            return report.type.toLowerCase().contains(lowerQuery) ||
                   report.description.toLowerCase().contains(lowerQuery);
          }).toList();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by location or crime type...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _hasSearched = false;
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                const SizedBox(width: 8),
                // Crime type filter dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      hint: const Text('Type'),
                      icon: const Icon(Icons.filter_list),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Types')),
                        ..._crimeTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedType = value);
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _hasSearched ? _buildSearchResults() : _buildInitialView(),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) => Chip(
              label: Text(s),
              onDeleted: () {
                setState(() => _recentSearches.remove(s));
              },
              deleteIconColor: Colors.grey[600],
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            )).toList(),
          ),

          const SizedBox(height: 32),

          // Popular Searches
          Text('Popular Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((item) {
              final query = item['query'] as String;
              final icon = item['icon'] as IconData;
              return ActionChip(
                label: Text(query),
                avatar: Icon(icon),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Quick filters
          Text('Quick Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _crimeTypes.map((type) => FilterChip(
              label: Text(type),
              selected: _selectedType == type,
              onSelected: (selected) {
                setState(() => _selectedType = selected ? type : null);
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched || _searchController.text.isEmpty && _selectedType == null) {
      return _buildInitialView();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords or filters',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Results count bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} result(s) found',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasSearched = false;
                    _searchResults.clear();
                    _searchController.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final report = _searchResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.getCrimeTypeColor(report.type).withOpacity(0.2),
                    child: Icon(Icons.report_problem, color: AppColors.getCrimeTypeColor(report.type)),
                  ),
                  title: Text(report.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.description.length > 80 
                            ? '${report.description.substring(0, 80)}...' 
                            : report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('Location', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(_formatDate(report.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.getStatusColor(report.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.statusDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getStatusColor(report.status),
                      ),
                    ),
                  ),
                  onTap: () {
                    // Navigate to crime detail (would need route update)
                    debugPrint('Navigate to report ${report.id}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
