// lib/src/profile/domain/profile_post.dart
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

/// One post on the signed-in user's own profile (Videos / Favorite / Delete
/// tabs) — GET /profile/{userId}/posts.
class ProfilePost {
  final String id;
  final String caption;
  final int? rating;
  final String videoUrl;
  final String? thumbnailUrl;
  final double aspectRatio;
  final FeedAuthor user;
  final FeedRestaurant? restaurant;
  final int likesCount;
  final int commentsCount;
  final bool isFavorite;
  final bool isLiked;
  final String status;
  final DateTime? deletedAt;

  ProfilePost({
    required this.id,
    required this.caption,
    this.rating,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.aspectRatio,
    required this.user,
    this.restaurant,
    required this.likesCount,
    required this.commentsCount,
    required this.isFavorite,
    required this.isLiked,
    required this.status,
    this.deletedAt,
  });

  factory ProfilePost.fromJson(Map<String, dynamic> json) => ProfilePost(
    id: json['id'].toString(),
    caption: json['caption'] as String? ?? '',
    rating: (json['rating'] as num?)?.toInt(),
    videoUrl: AppConfig.fixMediaUrl(json['video_url'] as String? ?? ''),
    thumbnailUrl: (json['thumbnail_url'] as String?) != null
        ? AppConfig.fixMediaUrl(json['thumbnail_url'] as String)
        : null,
    aspectRatio: (json['aspect_ratio'] as num?)?.toDouble() ?? (9 / 16),
    user: FeedAuthor.fromJson(json['user'] as Map<String, dynamic>),
    restaurant: json['restaurant'] != null
        ? FeedRestaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
        : null,
    likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    isFavorite: json['is_favorite'] == true,
    isLiked: json['is_liked'] == true,
    status: json['status'] as String? ?? 'ready',
    deletedAt: json['deleted_at'] != null
        ? DateTime.tryParse(json['deleted_at'] as String)
        : null,
  );

  ProfilePost copyWith({bool? isFavorite, bool? isLiked}) => ProfilePost(
    id: id,
    caption: caption,
    rating: rating,
    videoUrl: videoUrl,
    thumbnailUrl: thumbnailUrl,
    aspectRatio: aspectRatio,
    user: user,
    restaurant: restaurant,
    likesCount: likesCount,
    commentsCount: commentsCount,
    isFavorite: isFavorite ?? this.isFavorite,
    isLiked: isLiked ?? this.isLiked,
    status: status,
    deletedAt: deletedAt,
  );

  /// For reusing [VideoViewerScreen], which is built around the feed's item
  /// shape rather than a second parallel player.
  VideoFeedItem toVideoFeedItem() => VideoFeedItem(
    id: id,
    caption: caption,
    videoUrl: videoUrl,
    thumbnailUrl: thumbnailUrl,
    aspectRatio: aspectRatio,
    commentsCount: commentsCount,
    likesCount: likesCount,
    likedByMe: isLiked,
    savedByMe: isFavorite,
    user: user,
    restaurant: restaurant,
  );
}
