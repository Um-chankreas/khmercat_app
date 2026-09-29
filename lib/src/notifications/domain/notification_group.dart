import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';

/// One row on the notifications screen: a single notification, or several
/// similar ones folded together so the list isn't a wall of repeats —
///  - one person liked several of your reviews ("liked 8 of your reviews")
///  - several people liked the same review ("@a and 3 others liked…")
///  - a restaurant posted several videos ("posted 3 new videos")
/// Only notifications from the same day are grouped.
class NotificationGroup {
  /// Newest first.
  final List<AppNotification> items;
  const NotificationGroup(this.items);

  AppNotification get latest => items.first;
  NotificationType get type => latest.type;
  List<String> get ids => [for (final n in items) n.id];
  bool get isRead => items.every((n) => n.isRead);
  DateTime get createdAt => latest.createdAt;

  /// Distinct people in this row, newest first.
  List<NotificationActor> get actors {
    final seen = <String>{};
    return [
      for (final n in items)
        if (n.actor != null && seen.add(n.actor!.id)) n.actor!,
    ];
  }

  /// Distinct video thumbnails, newest first.
  List<String> get thumbnails {
    final seen = <String>{};
    return [
      for (final n in items)
        if (n.videoThumbnailUrl != null && seen.add(n.videoId ?? ''))
          n.videoThumbnailUrl!,
    ];
  }

  int get videoCount => {for (final n in items) n.videoId}.length;
}

String _day(DateTime t) {
  final l = t.toLocal();
  return '${l.year}-${l.month}-${l.day}';
}

/// Folds [items] (newest first) into rows, keeping newest-first order.
List<NotificationGroup> groupNotifications(List<AppNotification> items) {
  // Bucket keys → members, in first-seen (newest) order.
  final buckets = <String, List<AppNotification>>{};

  // Likes on the same video by different people, same day.
  final likesByVideo = <String, List<AppNotification>>{};
  for (final n in items) {
    if (n.type == NotificationType.like && n.videoId != null) {
      likesByVideo
          .putIfAbsent('${n.videoId}|${_day(n.createdAt)}', () => [])
          .add(n);
    }
  }
  final multiActorVideos = {
    for (final e in likesByVideo.entries)
      if ({for (final n in e.value) n.actor?.id}.length > 1) e.key,
  };

  for (final n in items) {
    final day = _day(n.createdAt);
    final String key;
    switch (n.type) {
      case NotificationType.like:
        final videoKey = '${n.videoId}|$day';
        key = multiActorVideos.contains(videoKey)
            ? 'like-video|$videoKey'
            // Otherwise: one person's likes across videos.
            : 'like-actor|${n.actor?.id}|$day';
      case NotificationType.restaurantVideo:
        key = 'post|${n.restaurantId}|$day';
      default:
        key = 'single|${n.id}';
    }
    buckets.putIfAbsent(key, () => []).add(n);
  }

  final groups = [for (final b in buckets.values) NotificationGroup(b)];
  groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return groups;
}

/// Date sections, like Facebook: Today, Yesterday, This week, Earlier.
/// Unread rows stay in their date's section (they're highlighted instead).
enum NotificationSection {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This week'),
  earlier('Earlier');

  final String label;
  const NotificationSection(this.label);

  static NotificationSection of(NotificationGroup g, DateTime now) {
    final t = g.createdAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo <= 0) return NotificationSection.today;
    if (daysAgo == 1) return NotificationSection.yesterday;
    if (daysAgo < 7) return NotificationSection.thisWeek;
    return NotificationSection.earlier;
  }
}
