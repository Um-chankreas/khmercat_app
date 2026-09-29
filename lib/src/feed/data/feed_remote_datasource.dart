import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class FeedRemoteDataSource {
  final ApiClient _client;
  FeedRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getFeed({
    required String tab,
    String? cursor,
    int limit = 5,
    double? lat,
    double? lng,
    double? radiusKm,
    String? restaurantId,
    String? userId,
    String? type,
  }) async {
    final json = await _client.get(
      ApiRoute.videosFeed,
      query: {
        'tab': tab,
        'limit': limit,
        'cursor': ?cursor,
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
        'radius_km': ?radiusKm,
        'restaurant_id': ?restaurantId,
        'user_id': ?userId,
        'type': ?type,
      },
    );
    return json.dataMap;
  }

  Future<Map<String, dynamic>> getVideo(String videoId) async {
    final json = await _client.get(ApiRoute.video(videoId));
    return json.dataMap;
  }

  Future<Map<String, dynamic>> like(String videoId) async {
    final json = await _client.post(ApiRoute.videoLike(videoId));
    return json.dataMap;
  }

  Future<Map<String, dynamic>> unlike(String videoId) async {
    final json = await _client.delete(ApiRoute.videoLike(videoId));
    return json.dataMap;
  }

  Future<void> save(String videoId) {
    return _client.post(ApiRoute.videoSave(videoId));
  }

  Future<void> unsave(String videoId) {
    return _client.delete(ApiRoute.videoSave(videoId));
  }

  Future<void> recordView(String videoId) {
    return _client.post(ApiRoute.videoView(videoId));
  }
}
