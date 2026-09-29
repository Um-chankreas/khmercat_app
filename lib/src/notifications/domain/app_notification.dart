// lib/src/notifications/domain/app_notification.dart
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart'
    show timeAgo;

enum NotificationType { follow, like, comment, reply, restaurantVideo, unknown }

NotificationType _typeFromString(String? raw) {
  switch (raw) {
    case 'follow':
      return NotificationType.follow;
    case 'like':
      return NotificationType.like;
    case 'comment':
      return NotificationType.comment;
    case 'reply':
      return NotificationType.reply;
    case 'restaurant_video':
      return NotificationType.restaurantVideo;
    default:
      return NotificationType.unknown;
  }
}

class NotificationActor {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;

  /// Whether you follow them (drives the "Follow back" button).
  final bool isFollowing;

  NotificationActor({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    this.isFollowing = false,
  });

  NotificationActor copyWith({bool? isFollowing}) => NotificationActor(
    id: id,
    name: name,
    username: username,
    profilePicture: profilePicture,
    isFollowing: isFollowing ?? this.isFollowing,
  );

  factory NotificationActor.fromJson(Map<String, dynamic> json) =>
      NotificationActor(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        profilePicture: (json['profile_picture'] as String?) != null
            ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
            : null,
        isFollowing: json['is_following'] == true,
      );
}

/// The filter tabs on the notifications screen (API `filter` values).
enum NotificationFilter {
  all('all', 'All'),
  likes('likes', 'Likes'),
  comments('comments', 'Comments'),
  follows('follows', 'Follows'),
  updates('updates', 'Updates');

  final String apiValue;
  final String label;
  const NotificationFilter(this.apiValue, this.label);

  bool matches(NotificationType type) => switch (this) {
    NotificationFilter.all => true,
    NotificationFilter.likes => type == NotificationType.like,
    NotificationFilter.comments =>
      type == NotificationType.comment || type == NotificationType.reply,
    NotificationFilter.follows => type == NotificationType.follow,
    NotificationFilter.updates => type == NotificationType.restaurantVideo,
  };

  /// Which filter a notification of [type] counts toward.
  static NotificationFilter of(NotificationType type) => switch (type) {
    NotificationType.like => NotificationFilter.likes,
    NotificationType.comment ||
    NotificationType.reply => NotificationFilter.comments,
    NotificationType.follow => NotificationFilter.follows,
    NotificationType.restaurantVideo => NotificationFilter.updates,
    NotificationType.unknown => NotificationFilter.all,
  };
}

class AppNotification {
  final String id;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  /// Who did the thing — present for every type except [restaurantVideo].
  final NotificationActor? actor;

  /// Which restaurant — present only for [restaurantVideo].
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantAvatar;

  /// The video this notification is about, when there is one.
  final String? videoId;
  final String? videoThumbnailUrl;

  /// The comment/reply text preview, when there is one.
  final String? commentId;
  final String? commentPreview;

  AppNotification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actor,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAvatar,
    this.videoId,
    this.videoThumbnailUrl,
    this.commentId,
    this.commentPreview,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actorJson = (json['actor'] as Map?)?.cast<String, dynamic>();
    final restaurantJson = (json['restaurant'] as Map?)
        ?.cast<String, dynamic>();
    final videoJson = (json['video'] as Map?)?.cast<String, dynamic>();
    final commentJson = (json['comment'] as Map?)?.cast<String, dynamic>();
    final rawThumb = videoJson?['thumbnail_url'] as String?;

    return AppNotification(
      id: json['id'].toString(),
      type: _typeFromString(json['type'] as String?),
      isRead: json['is_read'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      actor: actorJson != null ? NotificationActor.fromJson(actorJson) : null,
      restaurantId: restaurantJson?['id']?.toString(),
      restaurantName: restaurantJson?['name'] as String?,
      restaurantAvatar: (restaurantJson?['profile_picture'] as String?) != null
          ? AppConfig.fixMediaUrl(restaurantJson!['profile_picture'] as String)
          : null,
      videoId: videoJson?['id']?.toString(),
      videoThumbnailUrl: rawThumb != null
          ? AppConfig.fixMediaUrl(rawThumb)
          : null,
      commentId: commentJson?['id']?.toString(),
      commentPreview: commentJson?['preview'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead, NotificationActor? actor}) =>
      AppNotification(
        id: id,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        actor: actor ?? this.actor,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantAvatar: restaurantAvatar,
        videoId: videoId,
        videoThumbnailUrl: videoThumbnailUrl,
        commentId: commentId,
        commentPreview: commentPreview,
      );

  /// The avatar shown on the left — the actor's for every type except a
  /// restaurant's own post, which has no personal actor.
  String? get avatarUrl => type == NotificationType.restaurantVideo
      ? restaurantAvatar
      : actor?.profilePicture;

  /// Bold name shown in [message] — used separately so the UI can style it
  /// distinctly from the rest of the sentence.
  String get subjectName => type == NotificationType.restaurantVideo
      ? (restaurantName ?? 'A restaurant')
      : '@${actor?.username ?? 'someone'}';

  String get message {
    switch (type) {
      case NotificationType.follow:
        return 'started following you';
      case NotificationType.like:
        return 'liked your review';
      case NotificationType.comment:
        return commentPreview != null
            ? "commented: '$commentPreview'"
            : 'commented on your review';
      case NotificationType.reply:
        return commentPreview != null
            ? "replied: '$commentPreview'"
            : 'replied to your comment';
      case NotificationType.restaurantVideo:
        return 'posted new video';
      case NotificationType.unknown:
        return 'sent you a notification';
    }
  }

  String get timeAgoLabel => timeAgo(createdAt);
}
