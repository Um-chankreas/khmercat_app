import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

/// FAKE DATA for the restaurant profile, standing in for fields the API
/// doesn't send yet. Each real value wins when present; delete the fallback
/// here once the endpoint exists.
///
/// API still needed:
///  - GET /restaurants/{id}: `following_count`, `open_days_label`
///    ("daily" / "Mon – Sat") and `delivery_links` [{name, url}].
///  - GET /restaurants/{id}/reviews: `summary` {avg, total, counts{1..5}}
///    plus a page of reviews {id, user{id,name,profile_picture}, rating,
///    comment, media_thumbnail_url?, created_at}.
///  - POST /restaurants/{id}/reviews {rating, comment, media?} for "Write a
///    review".
abstract final class RestaurantProfileMock {
  static const followingCount = 12;
  static const openDaysLabel = 'daily';

  static const deliveryLinks = [
    DeliveryLink(name: 'Grab', url: 'https://food.grab.com'),
    DeliveryLink(name: 'foodpanda', url: 'https://www.foodpanda.com'),
    DeliveryLink(name: 'WOWNOW', url: 'https://wownow.asia'),
  ];

  static final reviewSummary = ReviewSummary(
    average: 4.8,
    counts: const {5: 3, 4: 1, 3: 0, 2: 0, 1: 0},
  );

  static final reviews = [
    WallReview(
      id: '1',
      name: 'Sreyneang',
      rating: 5,
      comment:
          'The grilled seafood is so fresh and the dipping sauce is the best '
          'I have had in Toul Kork.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      hasMedia: true,
    ),
    WallReview(
      id: '2',
      name: 'Dara',
      rating: 5,
      comment:
          'Good rice porridge in the morning and fair prices. It gets busy at '
          'lunch, so come early.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    WallReview(
      id: '3',
      name: 'Pisey',
      rating: 4,
      comment:
          'Tasty food and friendly staff. Parking is a little tight on the '
          'weekend.',
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
    ),
  ];
}

class ReviewSummary {
  final double average;

  /// Star (1–5) → number of reviews.
  final Map<int, int> counts;
  const ReviewSummary({required this.average, required this.counts});

  int get total => counts.values.fold(0, (a, b) => a + b);
  int get maxCount => counts.values.fold(0, (a, b) => a > b ? a : b);
}

/// A written review on the restaurant's wall.
class WallReview {
  final String id;
  final String name;
  final String? avatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  /// Has an attached photo / video (a thumbnail comes with the API).
  final bool hasMedia;
  final String? mediaThumbnailUrl;
  const WallReview({
    required this.id,
    required this.name,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.avatarUrl,
    this.hasMedia = false,
    this.mediaThumbnailUrl,
  });
}
