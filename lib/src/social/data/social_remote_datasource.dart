import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class SocialRemoteDataSource {
  final ApiClient _client;
  SocialRemoteDataSource(this._client);

  Future<int> followUser(String username) async {
    final json = await _client.post(ApiRoute.userFollow(username));
    return (json.dataMap['followers_count'] as num).toInt();
  }

  Future<int> unfollowUser(String username) async {
    final json = await _client.delete(ApiRoute.userFollow(username));
    return (json.dataMap['followers_count'] as num).toInt();
  }

  Future<int> followRestaurant(String restaurantId) async {
    final json = await _client.post(ApiRoute.restaurantFollow(restaurantId));
    return (json.dataMap['followers_count'] as num).toInt();
  }

  Future<int> unfollowRestaurant(String restaurantId) async {
    final json = await _client.delete(ApiRoute.restaurantFollow(restaurantId));
    return (json.dataMap['followers_count'] as num).toInt();
  }
}
