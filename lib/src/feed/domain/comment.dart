import 'video_feed_item.dart';

class VideoComment {
  final String id;
  final String body;
  final DateTime? createdAt;
  final FeedAuthor user;
  final int likesCount;
  final bool isLikedByMe;

  VideoComment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.user,
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  factory VideoComment.fromJson(Map<String, dynamic> json) => VideoComment(
    id: json['id'].toString(),
    body: json['body'] as String? ?? '',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    user: FeedAuthor.fromJson(json['user'] as Map<String, dynamic>),
    likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    isLikedByMe: json['is_liked'] == true,
  );

  VideoComment copyWith({int? likesCount, bool? isLikedByMe}) => VideoComment(
    id: id,
    body: body,
    createdAt: createdAt,
    user: user,
    likesCount: likesCount ?? this.likesCount,
    isLikedByMe: isLikedByMe ?? this.isLikedByMe,
  );
}
