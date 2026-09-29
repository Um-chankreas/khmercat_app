import 'video_feed_item.dart';

/// A comment, or a reply when [parentId] is set. Replies are one level deep:
/// a top-level comment carries its loaded [replies] and the server's total
/// [repliesCount] (which can be larger until "View more replies" loads them).
class VideoComment {
  final String id;
  final String? parentId;
  final String body;
  final DateTime? createdAt;
  final FeedAuthor user;
  final int likesCount;
  final bool isLikedByMe;

  /// Written by the video's uploader ("Creator" badge).
  final bool isCreator;
  final int repliesCount;
  final List<VideoComment> replies;

  const VideoComment({
    required this.id,
    this.parentId,
    required this.body,
    required this.createdAt,
    required this.user,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isCreator = false,
    this.repliesCount = 0,
    this.replies = const [],
  });

  bool get isReply => parentId != null;

  /// Replies the server has that aren't loaded yet.
  int get hiddenReplies => (repliesCount - replies.length).clamp(0, 1 << 30);

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    final replies = (json['replies'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(VideoComment.fromJson)
        .toList();
    return VideoComment(
      id: json['id'].toString(),
      parentId: json['parent_id']?.toString(),
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      user: FeedAuthor.fromJson(json['user'] as Map<String, dynamic>),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['is_liked'] == true,
      isCreator: json['is_creator'] == true,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? replies.length,
      replies: replies,
    );
  }

  VideoComment copyWith({
    int? likesCount,
    bool? isLikedByMe,
    int? repliesCount,
    List<VideoComment>? replies,
  }) => VideoComment(
    id: id,
    parentId: parentId,
    body: body,
    createdAt: createdAt,
    user: user,
    likesCount: likesCount ?? this.likesCount,
    isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    isCreator: isCreator,
    repliesCount: repliesCount ?? this.repliesCount,
    replies: replies ?? this.replies,
  );
}
