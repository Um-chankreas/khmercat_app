import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

String? _media(Object? url) =>
    url is String && url.isNotEmpty ? AppConfig.fixMediaUrl(url) : null;

/// A restaurant in the admin approval queue.
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      rejectionReason: json['rejection_reason'] as String?,
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
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

/// A reported video with its reports (the latest few).
class ReportedVideo {
  final String videoId;
  final String? thumbnailUrl;
  final String caption;
  final String? authorUsername;
  final String? restaurantName;

  /// Taken down already (in its owner's trash).
  final bool removed;
  final int reportsCount;
  final List<ReportEntry> reports;

  /// For playing it; null if the record can't be read as a feed item.
  final VideoFeedItem? video;

  const ReportedVideo({
    required this.videoId,
    required this.caption,
    required this.removed,
    required this.reportsCount,
    required this.reports,
    this.thumbnailUrl,
    this.authorUsername,
    this.restaurantName,
    this.video,
  });

  factory ReportedVideo.fromJson(Map<String, dynamic> json) {
    final v = json['video'] as Map<String, dynamic>;
    VideoFeedItem? video;
    try {
      video = VideoFeedItem.fromJson(v);
    } catch (_) {}
    return ReportedVideo(
      videoId: v['id'].toString(),
      thumbnailUrl: _media(v['thumbnail_url']),
      caption: (v['caption'] as String? ?? '').trim(),
      authorUsername:
          (v['user'] as Map<String, dynamic>?)?['username'] as String?,
      restaurantName:
          (v['restaurant'] as Map<String, dynamic>?)?['name'] as String?,
      removed: v['deleted_at'] != null,
      reportsCount: (json['reports_count'] as num?)?.toInt() ?? 0,
      reports: (json['reports'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ReportEntry.fromJson)
          .toList(),
      video: video,
    );
  }
}

typedef AdminPage<T> = ({List<T> items, bool hasMore, int count});

class AdminRemoteDataSource {
  final ApiClient _client;
  AdminRemoteDataSource(this._client);

  /// Restaurants with [status] (pending / approved / rejected). `count` is
  /// how many are pending.
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
      count: ((data['counts'] as Map?)?['pending'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> approve(String restaurantId) =>
      _client.post(ApiRoute.adminApproveRestaurant(restaurantId));

  Future<void> reject(String restaurantId, {String? reason}) => _client.post(
    ApiRoute.adminRejectRestaurant(restaurantId),
    body: {'reason': ?reason},
  );

  /// Reported videos with [status] (open / removed / dismissed). `count` is
  /// how many videos have open reports.
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
      count: ((data['counts'] as Map?)?['open'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> removeVideo(String videoId) =>
      _client.post(ApiRoute.adminRemoveReported(videoId));

  Future<void> dismissReports(String videoId) =>
      _client.post(ApiRoute.adminDismissReports(videoId));
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(apiClientProvider));
});

/// What's waiting for an admin, for the Menu's Admin rows.
final adminCountsProvider =
    FutureProvider.autoDispose<({int pendingRestaurants, int openReports})>((
      ref,
    ) async {
      final admin = ref.read(adminRemoteDataSourceProvider);
      final results = await Future.wait([
        admin.restaurants('pending', 1).then((p) => p.count),
        admin.reports('open', 1).then((p) => p.count),
      ]);
      return (pendingRestaurants: results[0], openReports: results[1]);
    });
