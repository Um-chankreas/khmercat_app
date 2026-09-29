import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';

import 'notifications_remote_datasource.dart';

typedef NotificationsPage = ({
  List<AppNotification> items,
  int currentPage,
  bool hasMore,
  int unreadCount,

  /// Unread count per filter tab.
  Map<NotificationFilter, int> unreadByFilter,
});

class NotificationsRepository {
  final NotificationsRemoteDataSource _remote;
  NotificationsRepository(this._remote);

  Future<NotificationsPage> getNotifications({
    int page = 1,
    NotificationFilter filter = NotificationFilter.all,
  }) async {
    final json = await _remote.getNotifications(
      page: page,
      filter: filter.apiValue,
    );
    final contents = (json['contents'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};

    return (
      items: contents,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      hasMore: meta['has_more'] == true,
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
      unreadByFilter: {
        for (final f in NotificationFilter.values)
          f: ((meta['unread'] as Map?)?[f.apiValue] as num?)?.toInt() ?? 0,
      },
    );
  }

  Future<void> markRead(String id) => _remote.markRead(id);
  Future<void> markAllRead() => _remote.markAllRead();
  Future<void> markManyRead(List<String> ids) => _remote.markManyRead(ids);
  Future<void> deleteMany(List<String> ids) => _remote.deleteMany(ids);
  Future<void> delete(String id) => _remote.delete(id);
  Future<void> deleteAll() => _remote.deleteAll();
}
