import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// A restaurant as seen through the videos that mention it. The feed only
/// carries id / name / picture per restaurant, so recommendations are built
/// from those plus the likes, review count and review ratings on its videos.
class RestaurantHighlight {
  final String id;
  final String name;
  final String? picture;
  final int likes;
  final int videos;
  final int reviews;

  /// Average of the `rating` on its review videos, when the API sends one.
  final double? avgRating;

  const RestaurantHighlight({
    required this.id,
    required this.name,
    required this.picture,
    required this.likes,
    required this.videos,
    required this.reviews,
    required this.avgRating,
  });
}

typedef NearbyRestaurant = ({Restaurant restaurant, double? meters});

class DiscoverData {
  final List<NearbyRestaurant> nearby;
  final List<RestaurantHighlight> popular;
  final List<RestaurantHighlight> topRated;
  final List<RestaurantHighlight> mostReviewed;
  final List<VideoFeedItem> trendingVideos;

  const DiscoverData({
    this.nearby = const [],
    this.popular = const [],
    this.topRated = const [],
    this.mostReviewed = const [],
    this.trendingVideos = const [],
  });
}

/// Distance in metres from [from] to [r], or null when either has no
/// coordinates.
double? distanceTo(Position? from, Restaurant r) {
  if (from == null || r.latitude == null || r.longitude == null) return null;
  return Geolocator.distanceBetween(
    from.latitude,
    from.longitude,
    r.latitude!,
    r.longitude!,
  );
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

/// Builds the search screen's idle content from data the API really has:
/// the location-aware "for you" feed and the review feed. There's no
/// dedicated nearby / recommended endpoint, so:
///  - Nearby  = restaurants behind the location-aware feed, fetched for their
///              coordinates and sorted by distance from the device.
///  - Popular = most-liked, Most reviewed = most review videos,
///    Top rated = best average review rating (only if ratings come back).
final discoverProvider = FutureProvider.autoDispose<DiscoverData>((ref) async {
  final position = ref.watch(locationProvider);
  final feed = ref.read(feedRepositoryProvider);

  Future<List<VideoFeedItem>> load({String? type}) async {
    try {
      final page = await feed.getFeed(
        tab: 'for_you',
        type: type,
        lat: position?.latitude,
        lng: position?.longitude,
        limit: 20, // the feed API caps `limit` at 20 (422 above that)
      );
      return page.items;
    } catch (_) {
      return const [];
    }
  }

  final results = await Future.wait([load(), load(type: 'review')]);
  final all = results[0];
  final reviews = results[1];

  // ---- per-restaurant stats
  final likes = <String, int>{};
  final videos = <String, int>{};
  final reviewCount = <String, int>{};
  final ratingSum = <String, double>{};
  final ratingCount = <String, int>{};
  final info = <String, FeedRestaurant>{};

  for (final v in all) {
    final r = v.restaurant;
    if (r == null) continue;
    info[r.id] = r;
    likes[r.id] = (likes[r.id] ?? 0) + v.likesCount;
    videos[r.id] = (videos[r.id] ?? 0) + 1;
  }
  for (final v in reviews) {
    final r = v.restaurant;
    if (r == null) continue;
    info[r.id] = r;
    reviewCount[r.id] = (reviewCount[r.id] ?? 0) + 1;
    if (v.rating != null) {
      ratingSum[r.id] = (ratingSum[r.id] ?? 0) + v.rating!;
      ratingCount[r.id] = (ratingCount[r.id] ?? 0) + 1;
    }
  }

  RestaurantHighlight highlight(String id) => RestaurantHighlight(
    id: id,
    name: info[id]!.name,
    picture: info[id]!.profilePicture,
    likes: likes[id] ?? 0,
    videos: videos[id] ?? 0,
    reviews: reviewCount[id] ?? 0,
    avgRating: ratingCount[id] == null
        ? null
        : ratingSum[id]! / ratingCount[id]!,
  );

  final ids = info.keys.toList();
  final popular = ([...ids]..sort((a, b) => (likes[b] ?? 0) - (likes[a] ?? 0)))
      .where((id) => (likes[id] ?? 0) > 0 || ids.length <= 8)
      .take(8)
      .map(highlight)
      .toList();
  final mostReviewed = ids.where((id) => (reviewCount[id] ?? 0) > 0).toList()
    ..sort((a, b) => reviewCount[b]! - reviewCount[a]!);
  final topRated = ids.where((id) => ratingCount[id] != null).toList()
    ..sort(
      (a, b) => (ratingSum[b]! / ratingCount[b]!).compareTo(
        ratingSum[a]! / ratingCount[a]!,
      ),
    );
  // Everything the feed returned, most liked first; the screen shows the
  // top few and "See all" the rest.
  final trending = [...all]..sort((a, b) => b.likesCount - a.likesCount);

  // ---- nearby: needs coordinates, which only the restaurant record has
  var nearby = <NearbyRestaurant>[];
  if (position != null && ids.isNotEmpty) {
    final repo = ref.read(restaurantRepositoryProvider);
    final fetched = await Future.wait(
      ids.take(10).map((id) async {
        try {
          return await repo.show(id);
        } catch (_) {
          return null;
        }
      }),
    );
    nearby =
        [
          for (final r in fetched.whereType<Restaurant>())
            (restaurant: r, meters: distanceTo(position, r)),
        ]..sort(
          (a, b) => (a.meters ?? double.infinity).compareTo(
            b.meters ?? double.infinity,
          ),
        );
  }

  return DiscoverData(
    nearby: nearby,
    popular: popular,
    topRated: topRated.take(8).map(highlight).toList(),
    mostReviewed: mostReviewed.take(8).map(highlight).toList(),
    trendingVideos: trending,
  );
});
