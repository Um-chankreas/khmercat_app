import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class NotificationsRemoteDataSource {
  final ApiClient _client;
  NotificationsRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    String filter = 'all',
  }) async {
    final json = await _client.get(
      ApiRoute.notifications,
      query: {'page': page, 'filter': filter},
    );
    return json.dataMap;
  }

  Future<void> markManyRead(List<String> ids) {
    return _client.post(ApiRoute.markNotificationsRead, body: {'ids': ids});
  }

  Future<void> deleteMany(List<String> ids) {
    return _client.delete(ApiRoute.notificationsBatch, body: {'ids': ids});
  }

  Future<void> markRead(String id) {
    return _client.post(ApiRoute.markNotificationRead(id));
  }

  Future<void> markAllRead() {
    return _client.post(ApiRoute.markAllNotificationsRead);
  }

  Future<void> delete(String id) {
    return _client.delete(ApiRoute.notification(id));
  }

  Future<void> deleteAll() {
    return _client.delete(ApiRoute.notifications);
  }
}
