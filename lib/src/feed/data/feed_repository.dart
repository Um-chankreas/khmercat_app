import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

import 'feed_remote_datasource.dart';

typedef FeedPage = ({
  List<VideoFeedItem> items,
  String? nextCursor,
  bool hasMore,
});

class FeedRepository {
  final FeedRemoteDataSource _remote;
  FeedRepository(this._remote);

  Future<FeedPage> getFeed({
    required String tab,
    String? cursor,
    double? lat,
    double? lng,
    String? restaurantId,
    String? userId,
    String? type,
    int? limit,
  }) async {
    final data = await _remote.getFeed(
      tab: tab,
      cursor: cursor,
      lat: lat,
      lng: lng,
      restaurantId: restaurantId,
      userId: userId,
      type: type,
      limit: limit ?? 5,
    );
    final contents = (data['contents'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(VideoFeedItem.fromJson)
        .toList();
    final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? {};

    return (
      items: contents,
      nextCursor: meta['next_cursor']?.toString(),
      hasMore: meta['has_more'] == true,
    );
  }

  Future<VideoFeedItem> getVideo(String videoId) async {
    final data = await _remote.getVideo(videoId);
    return VideoFeedItem.fromJson(data);
  }

  Future<int> like(String videoId) async {
    final data = await _remote.like(videoId);
    return (data['likes_count'] as num).toInt();
  }

  Future<int> unlike(String videoId) async {
    final data = await _remote.unlike(videoId);
    return (data['likes_count'] as num).toInt();
  }

  /// Saves the video and returns its new save count — null from a server
  /// that doesn't report it yet (the save itself still went through).
  Future<int?> save(String videoId) async {
    final data = await _remote.save(videoId);
    return (data['saves_count'] as num?)?.toInt();
  }

  /// The reverse of [save].
  Future<int?> unsave(String videoId) async {
    final data = await _remote.unsave(videoId);
    return (data['saves_count'] as num?)?.toInt();
  }

  /// Counts a view (shown as "18.4K views" in search). Best effort: a failed
  /// or throttled request is ignored, it must never disturb playback.
  Future<void> recordView(String videoId) async {
    try {
      await _remote.recordView(videoId);
    } catch (_) {}
  }
}
