import 'package:khmer_cat_app/core/config/app_config.dart';

/// A person's rating + comment on a restaurant (one each — posting again
/// updates it), from GET /restaurants/{id}/reviews.
class RestaurantReview {
  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByMe;
  final ReviewAuthor user;
  final ReviewVideo? video;
  final ReviewReply? reply;

  const RestaurantReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.likesCount,
    required this.likedByMe,
    required this.user,
    this.video,
    this.reply,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    final video = json['video'];
    final reply = json['reply'];
    return RestaurantReview(
      id: json['id'].toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] == true,
      user: ReviewAuthor.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      video: video is Map
          ? ReviewVideo.fromJson(video.cast<String, dynamic>())
          : null,
      reply: reply is Map
          ? ReviewReply.fromJson(reply.cast<String, dynamic>())
          : null,
    );
  }

  RestaurantReview copyWith({
    int? likesCount,
    bool? likedByMe,
    ReviewReply? Function()? reply,
  }) => RestaurantReview(
    id: id,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    likesCount: likesCount ?? this.likesCount,
    likedByMe: likedByMe ?? this.likedByMe,
    user: user,
    video: video,
    reply: reply == null ? this.reply : reply(),
  );
}

class ReviewAuthor {
  final String id;
  final String name;
  final String? username;
  final String? profilePicture;
  const ReviewAuthor({
    required this.id,
    required this.name,
    this.username,
    this.profilePicture,
  });

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) => ReviewAuthor(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    username: json['username'] as String?,
    profilePicture: switch (json['profile_picture']) {
      final String url when url.isNotEmpty => AppConfig.fixMediaUrl(url),
      _ => null,
    },
  );
}

/// The review video posted with it (only once it's processed).
class ReviewVideo {
  final String id;
  final String? thumbnailUrl;
  final Duration? duration;
  const ReviewVideo({required this.id, this.thumbnailUrl, this.duration});

  factory ReviewVideo.fromJson(Map<String, dynamic> json) {
    final seconds = (json['duration_seconds'] as num?)?.toInt();
    return ReviewVideo(
      id: json['id'].toString(),
      thumbnailUrl: switch (json['thumbnail_url']) {
        final String url when url.isNotEmpty => AppConfig.fixMediaUrl(url),
        _ => null,
      },
      duration: seconds == null ? null : Duration(seconds: seconds),
    );
  }
}

/// The restaurant's answer to a review.
class ReviewReply {
  final String text;
  final DateTime? createdAt;
  const ReviewReply({required this.text, this.createdAt});

  factory ReviewReply.fromJson(Map<String, dynamic> json) => ReviewReply(
    text: json['text'] as String? ?? '',
    createdAt: DateTime.tryParse(
      json['created_at'] as String? ?? '',
    )?.toLocal(),
  );
}

class ReviewSummary {
  final double average;
  final int total;

  /// Star (1–5) → number of reviews.
  final Map<int, int> counts;
  const ReviewSummary({
    required this.average,
    required this.total,
    required this.counts,
  });

  static const empty = ReviewSummary(average: 0, total: 0, counts: {});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] as Map?) ?? const {};
    return ReviewSummary(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      counts: {
        for (var star = 1; star <= 5; star++)
          star: (counts['$star'] as num?)?.toInt() ?? 0,
      },
    );
  }

  int get maxCount => counts.values.fold(0, (a, b) => a > b ? a : b);
}

class ReviewsPage {
  final ReviewSummary summary;
  final int withVideoCount;

  /// The signed-in viewer's own review, to prefill "Write a review".
  final RestaurantReview? myReview;
  final List<RestaurantReview> items;
  final String? nextCursor;
  final bool hasMore;

  const ReviewsPage({
    required this.summary,
    required this.withVideoCount,
    required this.items,
    this.myReview,
    this.nextCursor,
    this.hasMore = false,
  });

  factory ReviewsPage.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final mine = json['my_review'];
    return ReviewsPage(
      summary: ReviewSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      withVideoCount: (json['with_video_count'] as num?)?.toInt() ?? 0,
      myReview: mine is Map
          ? RestaurantReview.fromJson(mine.cast<String, dynamic>())
          : null,
      items: (json['contents'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RestaurantReview.fromJson)
          .toList(),
      nextCursor: meta['next_cursor']?.toString(),
      hasMore: meta['has_more'] == true,
    );
  }
}
