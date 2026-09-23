import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';

import 'search_remote_datasource.dart';

typedef SearchResults = ({
  List<Restaurant> restaurants,
  List<VideoFeedItem> videos,
  List<PublicProfile> users,
});

class SearchRepository {
  final SearchRemoteDataSource _remote;
  SearchRepository(this._remote);

  Future<SearchResults> search(String query) async {
    final data = await _remote.search(query);
    return (
      restaurants: (data['restaurants'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList(),
      videos: (data['videos'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoFeedItem.fromJson)
          .toList(),
      // Not every backend build returns matching users from /search; when
      // the key is missing this is just empty and the Users tab says so.
      users: (data['users'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PublicProfile.fromJson)
          .toList(),
    );
  }
}
