import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_review.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

class RestaurantReviewsState {
  final ReviewSummary summary;
  final int withVideoCount;
  final RestaurantReview? myReview;
  final List<RestaurantReview> reviews;

  /// The "With video" chip is on.
  final bool withVideoOnly;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool failed;

  const RestaurantReviewsState({
    this.summary = ReviewSummary.empty,
    this.withVideoCount = 0,
    this.myReview,
    this.reviews = const [],
    this.withVideoOnly = false,
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.failed = false,
  });

  RestaurantReviewsState copyWith({
    ReviewSummary? summary,
    int? withVideoCount,
    RestaurantReview? Function()? myReview,
    List<RestaurantReview>? reviews,
    bool? withVideoOnly,
    String? Function()? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? failed,
  }) => RestaurantReviewsState(
    summary: summary ?? this.summary,
    withVideoCount: withVideoCount ?? this.withVideoCount,
    myReview: myReview == null ? this.myReview : myReview(),
    reviews: reviews ?? this.reviews,
    withVideoOnly: withVideoOnly ?? this.withVideoOnly,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failed: failed ?? this.failed,
  );
}

/// The restaurant profile's Reviews tab, keyed by restaurant id.
class RestaurantReviewsController
    extends FamilyNotifier<RestaurantReviewsState, String> {
  /// Bumped on every reload so a slow, superseded response is dropped.
  int _generation = 0;

  @override
  RestaurantReviewsState build(String restaurantId) {
    Future.microtask(reload);
    return const RestaurantReviewsState();
  }

  /// First page for the current filter. [quiet] keeps the current list on
  /// screen (no skeleton) while it loads, e.g. after posting a review.
  Future<void> reload({bool quiet = false}) async {
    final gen = ++_generation;
    if (!quiet) state = state.copyWith(isLoading: true, failed: false);
    try {
      final page = await ref
          .read(restaurantRepositoryProvider)
          .reviews(arg, withVideoOnly: state.withVideoOnly);
      if (gen != _generation) return;
      state = state.copyWith(
        summary: page.summary,
        withVideoCount: page.withVideoCount,
        myReview: () => page.myReview,
        reviews: page.items,
        nextCursor: () => page.nextCursor,
        hasMore: page.hasMore && page.nextCursor != null,
        isLoading: false,
        failed: false,
      );
    } catch (_) {
      if (gen != _generation) return;
      state = state.copyWith(isLoading: false, failed: !quiet);
    }
  }

  void setWithVideoOnly(bool value) {
    if (value == state.withVideoOnly) return;
    state = state.copyWith(withVideoOnly: value, reviews: const []);
    reload();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final gen = _generation;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref
          .read(restaurantRepositoryProvider)
          .reviews(
            arg,
            withVideoOnly: state.withVideoOnly,
            cursor: state.nextCursor,
          );
      if (gen != _generation) return;
      state = state.copyWith(
        reviews: [...state.reviews, ...page.items],
        nextCursor: () => page.nextCursor,
        hasMore: page.hasMore && page.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (_) {
      if (gen == _generation) state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Optimistic; settles on the server's count, reverts on failure.
  Future<void> toggleLike(RestaurantReview review) async {
    final like = !review.likedByMe;
    _replace(
      review.copyWith(
        likedByMe: like,
        likesCount: review.likesCount + (like ? 1 : -1),
      ),
    );
    try {
      final count = await ref
          .read(restaurantRepositoryProvider)
          .likeReview(review.id, like: like);
      _replace(_find(review.id)?.copyWith(likesCount: count));
    } catch (_) {
      _replace(review);
    }
  }

  /// The restaurant team answers (or edits its answer to) a review.
  Future<void> reply(RestaurantReview review, String text) async {
    final updated = await ref
        .read(restaurantRepositoryProvider)
        .replyToReview(review.id, text);
    _replace(updated);
  }

  Future<void> deleteReply(RestaurantReview review) async {
    await ref.read(restaurantRepositoryProvider).deleteReviewReply(review.id);
    _replace(review.copyWith(reply: () => null));
  }

  RestaurantReview? _find(String id) =>
      state.reviews.where((r) => r.id == id).firstOrNull;

  void _replace(RestaurantReview? review) {
    if (review == null) return;
    state = state.copyWith(
      reviews: [for (final r in state.reviews) r.id == review.id ? review : r],
    );
  }
}

final restaurantReviewsControllerProvider =
    NotifierProvider.family<
      RestaurantReviewsController,
      RestaurantReviewsState,
      String
    >(RestaurantReviewsController.new);
