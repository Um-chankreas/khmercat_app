import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';
import 'package:khmer_cat_app/src/notifications/domain/notification_group.dart';

AppNotification _n(
  String id,
  String type, {
  String actor = '1',
  String video = '10',
  DateTime? at,
}) => AppNotification.fromJson({
  'id': id,
  'type': type,
  'is_read': false,
  'created_at': (at ?? DateTime(2026, 9, 29, 10)).toIso8601String(),
  'actor': {'id': actor, 'name': 'User $actor', 'username': 'user$actor'},
  'video': {'id': video, 'thumbnail_url': 'http://x/$video.jpg'},
});

void main() {
  test('one person liking many reviews becomes one row', () {
    final groups = groupNotifications([
      for (var i = 0; i < 8; i++) _n('$i', 'like', video: 'v$i'),
    ]);
    expect(groups, hasLength(1));
    expect(groups.first.videoCount, 8);
    expect(groups.first.ids, hasLength(8));
  });

  test('many people liking one review becomes one row', () {
    final groups = groupNotifications([
      _n('a', 'like', actor: '1'),
      _n('b', 'like', actor: '2'),
      _n('c', 'like', actor: '3'),
    ]);
    expect(groups, hasLength(1));
    expect(groups.first.actors.map((a) => a.username), [
      'user1',
      'user2',
      'user3',
    ]);
  });

  test('comments and follows are never merged; other days stay apart', () {
    final groups = groupNotifications([
      _n('c1', 'comment'),
      _n('c2', 'comment'),
      _n('f1', 'follow'),
      _n('l1', 'like', video: 'x'),
      _n('l2', 'like', video: 'y', at: DateTime(2026, 9, 20)),
    ]);
    expect(groups, hasLength(5));
  });

  test('sections are by date: today, yesterday, this week, earlier', () {
    final now = DateTime(2026, 9, 29, 15);
    NotificationSection sectionAt(DateTime t) => NotificationSection.of(
      NotificationGroup([_n('x', 'like', at: t)]),
      now,
    );

    expect(sectionAt(DateTime(2026, 9, 29, 0, 5)), NotificationSection.today);
    expect(sectionAt(DateTime(2026, 9, 28, 23)), NotificationSection.yesterday);
    expect(sectionAt(DateTime(2026, 9, 24)), NotificationSection.thisWeek);
    expect(sectionAt(DateTime(2026, 9, 1)), NotificationSection.earlier);
  });
}
