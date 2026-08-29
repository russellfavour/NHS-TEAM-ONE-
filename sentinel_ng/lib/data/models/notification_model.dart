import 'user_model.dart';

/// Notification model (from Prisma Notification model)
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // HOTSPOT_ALERT, REPORT_STATUS_CHANGE, COMMUNITY_WARNING, SOS_RESPONSE
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'COMMUNITY_WARNING',
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': isRead,
        if (metadata != null) 'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  String get typeDisplay {
    switch (type.toUpperCase()) {
      case 'HOTSPOT_ALERT': return 'Hotspot Alert';
      case 'REPORT_STATUS_CHANGE': return 'Report Update';
      case 'COMMUNITY_WARNING': return 'Community Warning';
      case 'SOS_RESPONSE': return 'Emergency Response';
      default: return type;
    }
  }

  bool get isNew => !isRead && DateTime.now().difference(createdAt).inHours < 24;
}

/// Notification preference model (from Prisma NotificationPreference model)
class NotificationPreferenceModel {
  final String id;
  final String userId;
  final bool hotspotAlerts;
  final bool statusChanges;
  final bool communityWarnings;
  final bool sosResponses;
  final bool emailEnabled;
  final bool pushEnabled;
  final double radiusKm;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    this.hotspotAlerts = true,
    this.statusChanges = true,
    this.communityWarnings = true,
    this.sosResponses = true,
    this.emailEnabled = false,
    this.pushEnabled = true,
    this.radiusKm = 5.0,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      hotspotAlerts: json['hotspotAlerts'] as bool? ?? true,
      statusChanges: json['statusChanges'] as bool? ?? true,
      communityWarnings: json['communityWarnings'] as bool? ?? true,
      sosResponses: json['sosResponses'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'hotspotAlerts': hotspotAlerts,
        'statusChanges': statusChanges,
        'communityWarnings': communityWarnings,
        'sosResponses': sosResponses,
        'emailEnabled': emailEnabled,
        'pushEnabled': pushEnabled,
        'radiusKm': radiusKm,
      };
}

/// SOS Emergency Contact model (from Prisma SosEmergencyContact model)
class SosEmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final bool isPrimary;
  final DateTime createdAt;

  const SosEmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory SosEmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return SosEmergencyContactModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'isPrimary': isPrimary,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// SOS Alert model (from Prisma SosAlert model - NEW for Flutter)
class SosAlertModel {
  final String id;
  final String sosAlertId;
  final String reporterId;
  final String status; // TRIGGERED, ACKNOWLEDGED, EN_ROUTE, ON_SCENE, RESOLVED, CANCELLED
  final Map<String, dynamic> location;
  final String? address;
  final UserModel? assignedTo;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? enRouteAt;
  final DateTime? onSceneAt;
  final DateTime? resolvedAt;

  const SosAlertModel({
    required this.id,
    required this.sosAlertId,
    required this.reporterId,
    required this.status,
    required this.location,
    this.address,
    this.assignedTo,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.enRouteAt,
    this.onSceneAt,
    this.resolvedAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id'] as String? ?? '',
      sosAlertId: json['sosAlertId'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      status: json['status'] as String? ?? 'TRIGGERED',
      location: json['location'] as Map<String, dynamic>? ?? {'type': 'Point', 'coordinates': [0.0, 0.0]},
      address: json['address'] as String?,
      assignedTo: json['assignedTo'] != null ? UserModel.fromJson(json['assignedTo']) : null,
      triggeredAt: DateTime.parse(json['triggeredAt'] as String? ?? DateTime.now().toIso8601String()),
      acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt']) : null,
      enRouteAt: json['enRouteAt'] != null ? DateTime.parse(json['enRouteAt']) : null,
      onSceneAt: json['onSceneAt'] != null ? DateTime.parse(json['onSceneAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sosAlertId': sosAlertId,
        'reporterId': reporterId,
        'status': status,
        'location': location,
        if (address != null) 'address': address,
        if (assignedTo != null) 'assignedTo': assignedTo!.toJson(),
        'triggeredAt': triggeredAt.toIso8601String(),
        if (acknowledgedAt != null) 'acknowledgedAt': acknowledgedAt!.toIso8601String(),
        if (enRouteAt != null) 'enRouteAt': enRouteAt!.toIso8601String(),
        if (onSceneAt != null) 'onSceneAt': onSceneAt!.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      };

  bool get isActive => ['TRIGGERED', 'ACKNOWLEDGED', 'EN_ROUTE', 'ON_SCENE'].contains(status);
  bool get isResolved => status == 'RESOLVED';
  bool get isCancelled => status == 'CANCELLED';
}

/// Broadcast Alert model (from Prisma BroadcastAlert model - NEW for Flutter)
class BroadcastAlertModel {
  final String id;
  final String title;
  final String message;
  final String targetAudience;
  final Map<String, dynamic>? regionFilter;
  final String priority; // LOW, MEDIUM, HIGH, CRITICAL
  final bool isActive;
  final DateTime? sentAt;
  final int deliveredCount;
  final UserModel? createdBy;
  final DateTime createdAt;

  const BroadcastAlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    this.regionFilter,
    required this.priority,
    required this.isActive,
    this.sentAt,
    this.deliveredCount = 0,
    this.createdBy,
    required this.createdAt,
  });

  factory BroadcastAlertModel.fromJson(Map<String, dynamic> json) {
    return BroadcastAlertModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetAudience: json['targetAudience'] as String? ?? 'all',
      regionFilter: json['regionFilter'] as Map<String, dynamic>?,
      priority: json['priority'] as String? ?? 'MEDIUM',
      isActive: json['isActive'] as bool? ?? true,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      deliveredCount: json['deliveredCount'] as int? ?? 0,
      createdBy: json['createdBy'] != null ? UserModel.fromJson(json['createdBy']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'targetAudience': targetAudience,
        if (regionFilter != null) 'regionFilter': regionFilter,
        'priority': priority,
        'isActive': isActive,
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        'deliveredCount': deliveredCount,
        if (createdBy != null) 'createdBy': createdBy!.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  String get priorityDisplay {
    switch (priority.toUpperCase()) {
      case 'CRITICAL': return 'Critical';
      case 'HIGH': return 'High Priority';
      case 'MEDIUM': return 'Medium Priority';
      case 'LOW': return 'Low Priority';
      default: return priority;
    }
  }

  String get audienceDisplay {
    switch (targetAudience.toLowerCase()) {
      case 'all': return 'All Users';
      case 'region': return 'Region Specific';
      case 'verified_users': return 'Verified Reporters';
      default: return targetAudience;
    }
  }
}

/// Analytics data model for admin dashboard (NEW for Flutter)
class AnalyticsModel {
  final OverviewStats overview;
  final List<CountItem> byType;
  final List<CountItem> byRiskLevel;
  final List<CountItem> byStatus;
  final List<TemporalTrend> temporalTrends;

  const AnalyticsModel({
    required this.overview,
    required this.byType,
    required this.byRiskLevel,
    required this.byStatus,
    required this.temporalTrends,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      overview: OverviewStats.fromJson(json['overview'] as Map<String, dynamic>? ?? {}),
      byType: (json['byType'] as List<dynamic>?)
              ?.map((e) => CountItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      byRiskLevel: (json['byRiskLevel'] as List<dynamic>?)
              ?.map((e) => CountItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      byStatus: (json['byStatus'] as List<dynamic>?)
              ?.map((e) => CountItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      temporalTrends: (json['temporalTrends'] as List<dynamic>?)
              ?.map((e) => TemporalTrend.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'overview': overview.toJson(),
        'byType': byType.map((e) => e.toJson()).toList(),
        'byRiskLevel': byRiskLevel.map((e) => e.toJson()).toList(),
        'byStatus': byStatus.map((e) => e.toJson()).toList(),
        'temporalTrends': temporalTrends.map((e) => e.toJson()).toList(),
      };
}

class OverviewStats {
  final int totalReports;
  final int verifiedCount;
  final int pendingCount;
  final int rejectedCount;

  const OverviewStats({this.totalReports = 0, this.verifiedCount = 0, this.pendingCount = 0, this.rejectedCount = 0});

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalReports: json['totalReports'] as int? ?? 0,
      verifiedCount: json['verifiedCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      rejectedCount: json['rejectedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalReports': totalReports,
        'verifiedCount': verifiedCount,
        'pendingCount': pendingCount,
        'rejectedCount': rejectedCount,
      };
}

class CountItem {
  final String name; // type, risk level, or status
  final int count;

  const CountItem({required this.name, required this.count});

  factory CountItem.fromJson(Map<String, dynamic> json) {
    return CountItem(
      name: json['type'] as String? ?? json['level'] as String? ?? json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'count': count};
}

class TemporalTrend {
  final String period; // YYYY-MM-DD or YYYY-Www or YYYY-MM
  final int count;

  const TemporalTrend({required this.period, required this.count});

  factory TemporalTrend.fromJson(Map<String, dynamic> json) {
    return TemporalTrend(
      period: json['period'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'period': period, 'count': count};
}
