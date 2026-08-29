import 'user_model.dart';

/// Crime report model (from Prisma Report model)
class CrimeReportModel {
  final String id;
  final String type;
  final String description;
  final String status; // PENDING, VERIFIED, REJECTED, CROWD_REPORTED
  final String riskLevel; // LOW, MEDIUM, HIGH
  final Map<String, dynamic> location; // GeoJSON Point {type: "Point", coordinates: [lng, lat]}
  final List<String> mediaUrls;
  final bool isAnonymous;
  final int confirmationCount;
  final UserModel? reporter;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrimeReportModel({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.riskLevel,
    required this.location,
    required this.mediaUrls,
    required this.isAnonymous,
    required this.confirmationCount,
    this.reporter,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrimeReportModel.fromJson(Map<String, dynamic> json) {
    return CrimeReportModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'Others',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      riskLevel: json['riskLevel'] as String? ?? 'LOW',
      location: json['location'] as Map<String, dynamic>? ?? {'type': 'Point', 'coordinates': [0.0, 0.0]},
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      confirmationCount: json['confirmationCount'] as int? ?? 1,
      reporter: json['reporter'] != null ? UserModel.fromJson(json['reporter']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'status': status,
      'riskLevel': riskLevel,
      'location': location,
      'mediaUrls': mediaUrls,
      'isAnonymous': isAnonymous,
      'confirmationCount': confirmationCount,
      if (reporter != null) 'reporter': reporter!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for UI display
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Under Review';
      case 'VERIFIED': return 'Verified';
      case 'REJECTED': return 'Rejected';
      case 'CROWD_REPORTED': return 'Community Alert';
      default: return status;
    }
  }

  String get riskLevelDisplay {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH': return 'High Risk';
      case 'MEDIUM': return 'Medium Risk';
      case 'LOW': return 'Low Risk';
      default: return riskLevel;
    }
  }

  bool get isVerified => status == 'VERIFIED' || status == 'CROWD_REPORTED';
  bool get isPending => status == 'PENDING';
}

/// Community alert model (aggregated from multiple pending reports)
class CommunityAlertModel {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> location;
  final int reportCount;
  final DateTime createdAt;

  const CommunityAlertModel({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.reportCount,
    required this.createdAt,
  });

  factory CommunityAlertModel.fromJson(Map<String, dynamic> json) {
    return CommunityAlertModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'Others',
      description: json['description'] as String? ?? '',
      location: json['location'] as Map<String, dynamic>? ?? {'type': 'Point', 'coordinates': [0.0, 0.0]},
      reportCount: json['reportCount'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'location': location,
        'reportCount': reportCount,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Paginated response for reports list
class ReportsResponse {
  final List<CrimeReportModel> verified;
  final List<CommunityAlertModel> communityAlerts;
  final PaginationInfo pagination;

  const ReportsResponse({required this.verified, required this.communityAlerts, required this.pagination});

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    return ReportsResponse(
      verified: (json['verified'] as List<dynamic>?)
              ?.map((e) => CrimeReportModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      communityAlerts: (json['communityAlerts'] as List<dynamic>?)
              ?.map((e) => CommunityAlertModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      pagination: json['pagination'] != null ? PaginationInfo.fromJson(json['pagination']) : const PaginationInfo(),
    );
  }

  int get totalItems => verified.length + communityAlerts.length;
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  const PaginationInfo({this.page = 1, this.limit = 50, this.total = 0, this.totalPages = 0, this.hasMore = false});

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 50,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Request model for creating a new report
class CreateReportRequest {
  final String type;
  final String description;
  final Map<String, dynamic> location; // GeoJSON Point
  final List<String>? mediaUrls;
  final bool isAnonymous;

  const CreateReportRequest({
    required this.type,
    required this.description,
    required this.location,
    this.mediaUrls,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'location': location,
      if (mediaUrls != null && mediaUrls!.isNotEmpty) 'mediaUrls': mediaUrls,
      'isAnonymous': isAnonymous,
    };
  }
}
