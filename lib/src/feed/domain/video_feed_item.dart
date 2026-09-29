// lib/src/feed/domain/video_feed_item.dart

import 'package:khmer_cat_app/core/config/app_config.dart';

class FeedAuthor {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;
  final bool isVerified;

  FeedAuthor({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    this.isVerified = false,
  });

  factory FeedAuthor.fromJson(Map<String, dynamic> json) => FeedAuthor(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
    isVerified: json['is_verified'] == true,
  );
}

class FeedRestaurant {
  final String id;
  final String name;
  final String? profilePicture;

  FeedRestaurant({required this.id, required this.name, this.profilePicture});

  factory FeedRestaurant.fromJson(Map<String, dynamic> json) => FeedRestaurant(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
  );
}

class VideoFeedItem {
  final String id;
  final String caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final double aspectRatio;
  final int commentsCount;
  final int likesCount;
  final bool likedByMe;
  final bool savedByMe;
  final FeedAuthor user;
  final FeedRestaurant? restaurant;

  /// Optional — shown only when the API sends them (`created_at`, and a
  /// 1–5 `rating` on review videos).
  final DateTime? createdAt;
  final double? rating;

  /// Real server state (`is_following_restaurant` — every video always has
  /// a restaurant, both upload paths require one), not a client-side guess.
  final bool isFollowingRestaurant;

  final int viewsCount;
  final int? durationSeconds;

  VideoFeedItem({
    required this.id,
    required this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.aspectRatio,
    required this.commentsCount,
    required this.likesCount,
    required this.likedByMe,
    this.savedByMe = false,
    required this.user,
    this.restaurant,
    this.createdAt,
    this.rating,
    this.isFollowingRestaurant = false,
    this.viewsCount = 0,
    this.durationSeconds,
  });

  /// "0:45", "1:20", "1:02:03", or null when the length is unknown.
  String? get durationText {
    final s = durationSeconds;
    if (s == null || s <= 0) return null;
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = (s % 60);
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  factory VideoFeedItem.fromJson(Map<String, dynamic> json) => VideoFeedItem(
    id: json['id'].toString(),
    caption: json['caption'] as String? ?? '',
    videoUrl: AppConfig.fixMediaUrl(json['video_url'] as String),
    thumbnailUrl: (json['thumbnail_url'] as String?) != null
        ? AppConfig.fixMediaUrl(json['thumbnail_url'] as String)
        : null,
    aspectRatio: (json['aspect_ratio'] as num?)?.toDouble() ?? (9 / 16),
    commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    likedByMe: json['liked_by_me'] == true,
    savedByMe: json['saved_by_me'] == true,
    user: FeedAuthor.fromJson(json['user'] as Map<String, dynamic>),
    restaurant: json['restaurant'] != null
        ? FeedRestaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
        : null,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    rating: (json['rating'] as num?)?.toDouble(),
    isFollowingRestaurant: json['is_following_restaurant'] == true,
    viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
    durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  );

  VideoFeedItem copyWith({
    int? commentsCount,
    int? likesCount,
    bool? likedByMe,
    bool? savedByMe,
    bool? isFollowingRestaurant,
  }) {
    return VideoFeedItem(
      id: id,
      caption: caption,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      aspectRatio: aspectRatio,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      user: user,
      restaurant: restaurant,
      createdAt: createdAt,
      rating: rating,
      isFollowingRestaurant:
          isFollowingRestaurant ?? this.isFollowingRestaurant,
      viewsCount: viewsCount,
      durationSeconds: durationSeconds,
    );
  }
}

String formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return count.toString();
}

/// "just now", "5m ago", "3h ago", "2 days ago", "3w ago", "4mo ago", "2y ago".
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
  return '${diff.inDays ~/ 365}y ago';
}
