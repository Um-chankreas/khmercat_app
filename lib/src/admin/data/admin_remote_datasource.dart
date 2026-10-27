import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

String? _media(Object? url) =>
    url is String && url.isNotEmpty ? AppConfig.fixMediaUrl(url) : null;

DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// The dashboard's numbers.
class AdminSummary {
  final int pendingRestaurants;
  final int openReports;
  final int users;
  final int usersThisWeek;
  final int activeRestaurants;
  final int bannedUsers;

  const AdminSummary({
    required this.pendingRestaurants,
    required this.openReports,
    required this.users,
    required this.usersThisWeek,
    required this.activeRestaurants,
    required this.bannedUsers,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) => AdminSummary(
    pendingRestaurants: _int(json['pending_restaurants']),
    openReports: _int(json['open_reports']),
    users: _int(json['users']),
    usersThisWeek: _int(json['users_this_week']),
    activeRestaurants: _int(json['active_restaurants']),
    bannedUsers: _int(json['banned_users']),
  );
}

/// A restaurant in one of the admin lists.
class AdminRestaurant {
  final String id;
  final String name;
  final String? picture;
  final String? category;
  final String? address;
  final String? ownerName;
  final String? ownerUsername;
  final DateTime? createdAt;
  final String? rejectionReason;
  final DateTime? deactivatedAt;
  final String? deactivationReason;
  final int openReportsCount;

  const AdminRestaurant({
    required this.id,
    required this.name,
    this.picture,
    this.category,
    this.address,
    this.ownerName,
    this.ownerUsername,
    this.createdAt,
    this.rejectionReason,
    this.deactivatedAt,
    this.deactivationReason,
    this.openReportsCount = 0,
  });

  factory AdminRestaurant.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return AdminRestaurant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      picture: _media(json['profile_picture'] ?? json['cover_picture']),
      category: category?['name'] as String?,
      address: json['address'] as String?,
      ownerName: owner?['name'] as String?,
      ownerUsername: owner?['username'] as String?,
      createdAt: _date(json['created_at']),
      rejectionReason: json['rejection_reason'] as String?,
      deactivatedAt: _date(json['deactivated_at']),
      deactivationReason: json['deactivation_reason'] as String?,
      openReportsCount: _int(json['open_reports_count']),
    );
  }
}

/// One report about a video.
class ReportEntry {
  final String reason;
  final String? note;
  final String? reporterUsername;
  final DateTime? createdAt;

  const ReportEntry({
    required this.reason,
    this.note,
    this.reporterUsername,
    this.createdAt,
  });

  factory ReportEntry.fromJson(Map<String, dynamic> json) => ReportEntry(
    reason: json['reason'] as String? ?? 'other',
    note: switch (json['note']) {
      final String n when n.trim().isNotEmpty => n.trim(),
      _ => null,
    },
    reporterUsername:
        (json['reporter'] as Map<String, dynamic>?)?['username'] as String?,
    createdAt: _date(json['created_at']),
  );
}

/// How a reported video was handled: deleted (`removed`) or `dismissed`.
class ReportResolution {
  final String status;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final String? resolvedByName;

  const ReportResolution({
    required this.status,
    this.resolvedAt,
    this.resolvedById,
    this.resolvedByName,
  });

  bool get removed => status == 'removed';

  static ReportResolution? maybeFromJson(Object? json) {
    if (json is! Map) return null;
    final by = json['resolved_by'] as Map?;
    return ReportResolution(
      status: json['status'] as String? ?? '',
      resolvedAt: _date(json['resolved_at']),
      resolvedById: by?['id']?.toString(),
      resolvedByName: by?['name'] as String?,
    );
  }
}

/// A reported video with its reports (the latest few).
class ReportedVideo {
  final String videoId;
  final String? thumbnailUrl;
  final String caption;
  final String? authorId;
  final String? authorName;
  final String? authorUsername;
  final String? authorPicture;
  final bool authorBanned;
  final String? restaurantName;
  final DateTime? createdAt;

  /// Taken down already (in its owner's trash).
  final bool removed;
  final int reportsCount;

  /// Reason → how many reports gave it.
  final Map<String, int> reasonCounts;
  final List<ReportEntry> reports;
  final ReportResolution? resolution;

  /// For playing it; null if the record can't be read as a feed item.
  final VideoFeedItem? video;

  const ReportedVideo({
    required this.videoId,
    required this.caption,
    required this.removed,
    required this.reportsCount,
    required this.reports,
    this.reasonCounts = const {},
    this.thumbnailUrl,
    this.authorId,
    this.authorName,
    this.authorUsername,
    this.authorPicture,
    this.authorBanned = false,
    this.restaurantName,
    this.createdAt,
    this.resolution,
    this.video,
  });

  /// The reason given most often.
  String get topReason {
    if (reasonCounts.isEmpty) {
      return reports.isEmpty ? 'other' : reports.first.reason;
    }
    return (reasonCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  factory ReportedVideo.fromJson(Map<String, dynamic> json) {
    final v = json['video'] as Map<String, dynamic>;
    final user = v['user'] as Map<String, dynamic>?;
    VideoFeedItem? video;
    try {
      video = VideoFeedItem.fromJson(v);
    } catch (_) {}
    final counts = json['reason_counts'];
    return ReportedVideo(
      videoId: v['id'].toString(),
      thumbnailUrl: _media(v['thumbnail_url']),
      caption: (v['caption'] as String? ?? '').trim(),
      authorId: user?['id']?.toString(),
      authorName: user?['name'] as String?,
      authorUsername: user?['username'] as String?,
      authorPicture: _media(user?['profile_picture']),
      authorBanned: json['author_banned'] == true,
      restaurantName:
          (v['restaurant'] as Map<String, dynamic>?)?['name'] as String?,
      createdAt: _date(v['created_at']),
      removed: v['deleted_at'] != null,
      reportsCount: _int(json['reports_count']),
      reasonCounts: counts is Map
          ? {for (final e in counts.entries) e.key.toString(): _int(e.value)}
          : const {},
      reports: (json['reports'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ReportEntry.fromJson)
          .toList(),
      resolution: ReportResolution.maybeFromJson(json['resolution']),
      video: video,
    );
  }
}

/// A person in the admin Users list.
class AdminUser {
  final String id;
  final String name;
  final String username;
  final String? email;
  final String? picture;
  final bool isAdmin;
  final int videosCount;
  final int openReportsCount;
  final bool isBanned;
  final DateTime? bannedAt;

  /// Null while banned: for good.
  final DateTime? bannedUntil;
  final String? banReason;

  const AdminUser({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.picture,
    this.isAdmin = false,
    this.videosCount = 0,
    this.openReportsCount = 0,
    this.isBanned = false,
    this.bannedAt,
    this.bannedUntil,
    this.banReason,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String?,
    picture: _media(json['profile_picture']),
    isAdmin: json['is_admin'] == true,
    videosCount: _int(json['videos_count']),
    openReportsCount: _int(json['open_reports_count']),
    isBanned: json['is_banned'] == true,
    bannedAt: _date(json['banned_at']),
    bannedUntil: _date(json['banned_until']),
    banReason: json['ban_reason'] as String?,
  );
}

/// One line of the admin activity log.
class AdminActivity {
  final String id;
  final String action;
  final String targetType;
  final String summary;
  final String? reason;
  final String? adminId;
  final String? adminName;
  final DateTime? createdAt;

  const AdminActivity({
    required this.id,
    required this.action,
    required this.targetType,
    required this.summary,
    this.reason,
    this.adminId,
    this.adminName,
    this.createdAt,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map?;
    return AdminActivity(
      id: json['id'].toString(),
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      reason: json['reason'] as String?,
      adminId: admin?['id']?.toString(),
      adminName: admin?['name'] as String?,
      createdAt: _date(json['created_at']),
    );
  }
}

/// Ban lengths in days; null = forever.
typedef BanLength = int?;

/// The ban reasons, as the API takes them (see `banReasonLabel`).
const banReasons = ['sexual', 'spam', 'hate_harassment', 'fake_account'];

typedef AdminPage<T> = ({List<T> items, bool hasMore, Map<String, int> counts});

Map<String, int> _counts(Object? json) => json is Map
    ? {for (final e in json.entries) e.key.toString(): _int(e.value)}
    : const {};

class AdminRemoteDataSource {
  final ApiClient _client;
  AdminRemoteDataSource(this._client);

  Future<AdminSummary> summary() async =>
      AdminSummary.fromJson((await _client.get(ApiRoute.adminSummary)).dataMap);

  /// Restaurants that are `pending`, `active` or `deactivated` (also
  /// `approved` / `rejected`). `counts` has pending / active / deactivated.
  Future<AdminPage<AdminRestaurant>> restaurants(
    String status,
    int page,
  ) async {
    final data = (await _client.get(
      ApiRoute.adminRestaurants,
      query: {'status': status, 'page': page},
    )).dataMap;
    return (
      items: (data['restaurants'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AdminRestaurant.fromJson)
          .toList(),
      hasMore: data['has_more'] == true,
      counts: _counts(data['counts']),
    );
  }

  Future<void> approve(String restaurantId) =>
      _client.post(ApiRoute.adminApproveRestaurant(restaurantId));

  Future<void> reject(String restaurantId, {String? reason}) => _client.post(
    ApiRoute.adminRejectRestaurant(restaurantId),
    body: {'reason': ?reason},
  );

  Future<void> deactivate(String restaurantId, String reason) => _client.post(
    ApiRoute.adminDeactivateRestaurant(restaurantId),
    body: {'reason': reason},
  );

  Future<void> activate(String restaurantId) =>
      _client.post(ApiRoute.adminActivateRestaurant(restaurantId));

  /// Reported videos: `open`, or `resolved` (deleted + dismissed). `counts`
  /// has `open`.
  Future<AdminPage<ReportedVideo>> reports(String status, int page) async {
    final data = (await _client.get(
      ApiRoute.adminReports,
      query: {'status': status, 'page': page},
    )).dataMap;
    return (
      items: (data['items'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ReportedVideo.fromJson)
          .toList(),
      hasMore: data['has_more'] == true,
      counts: _counts(data['counts']),
    );
  }

  Future<void> removeVideo(String videoId) =>
      _client.post(ApiRoute.adminRemoveReported(videoId));

  Future<void> dismissReports(String videoId) =>
      _client.post(ApiRoute.adminDismissReports(videoId));

  /// People: `all`, `reported` or `banned`, optionally searched by [query].
  /// `counts` has reported / banned.
  Future<AdminPage<AdminUser>> users(
    String filter,
    int page, {
    String? query,
  }) async {
    final q = query?.trim();
    final data = (await _client.get(
      ApiRoute.adminUsers,
      query: {
        'filter': filter,
        'page': page,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    )).dataMap;
    return (
      items: (data['users'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AdminUser.fromJson)
          .toList(),
      hasMore: data['has_more'] == true,
      counts: _counts(data['counts']),
    );
  }

  /// Bans for [days] (7 / 30) or, null, for good. Returns how many reported
  /// videos were deleted with it.
  Future<int> ban(
    String userId, {
    required BanLength days,
    required String reason,
    required bool deleteReportedVideos,
  }) async {
    final json = await _client.post(
      ApiRoute.adminBanUser(userId),
      body: {
        'days': ?days,
        'reason': reason,
        'delete_reported_videos': deleteReportedVideos,
      },
    );
    return _int(json.dataMap['deleted_videos']);
  }

  Future<void> unban(String userId) =>
      _client.post(ApiRoute.adminUnbanUser(userId));

  Future<({List<AdminActivity> items, bool hasMore})> activity(int page) async {
    final data = (await _client.get(
      ApiRoute.adminActivity,
      query: {'page': page},
    )).dataMap;
    return (
      items: (data['actions'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AdminActivity.fromJson)
          .toList(),
      hasMore: data['has_more'] == true,
    );
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(apiClientProvider));
});

/// The dashboard numbers (also the Menu's Admin row and the Reports badge).
/// Invalidate after an action that changes them.
final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>(
  (ref) => ref.read(adminRemoteDataSourceProvider).summary(),
);
