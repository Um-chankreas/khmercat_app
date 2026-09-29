import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';

import 'search_remote_datasource.dart';

typedef SearchResults = ({
  List<Restaurant> restaurants,
  List<Restaurant> recommended,
  List<VideoFeedItem> videos,
  List<PublicProfile> users,

  /// Total matches per section; can be larger than the lists above.
  ({int restaurants, int videos, int users}) counts,
});

class SearchRepository {
  final SearchRemoteDataSource _remote;
  SearchRepository(this._remote);

  Future<SearchResults> search({
    String? query,
    String? categoryId,
    double? lat,
    double? lng,
    bool nearest = false,
  }) async {
    final data = await _remote.search(
      query: query,
      categoryId: categoryId,
      lat: lat,
      lng: lng,
      nearest: nearest,
    );

    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (data[key] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(parse)
            .toList();

    final restaurants = list('restaurants', Restaurant.fromJson);
    final videos = list('videos', VideoFeedItem.fromJson);
    final users = list('users', PublicProfile.fromJson);
    final counts = data['counts'] as Map<String, dynamic>? ?? const {};
    int count(String key, int fallback) =>
        (counts[key] as num?)?.toInt() ?? fallback;

    return (
      restaurants: restaurants,
      recommended: list('recommended', Restaurant.fromJson),
      videos: videos,
      users: users,
      counts: (
        restaurants: count('restaurants', restaurants.length),
        videos: count('videos', videos.length),
        users: count('users', users.length),
      ),
    );
  }
}
