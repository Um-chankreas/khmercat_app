import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';

class RestaurantProfileState {
  final Restaurant? restaurant;
  final bool isLoading;
  final bool isFollowingLocally;
  final String? errorMessage;

  const RestaurantProfileState({
    this.restaurant,
    this.isLoading = true,
    this.isFollowingLocally = false,
    this.errorMessage,
  });

  RestaurantProfileState copyWith({
    Restaurant? restaurant,
    bool? isLoading,
    bool? isFollowingLocally,
    String? errorMessage,
  }) {
    return RestaurantProfileState(
      restaurant: restaurant ?? this.restaurant,
      isLoading: isLoading ?? this.isLoading,
      isFollowingLocally: isFollowingLocally ?? this.isFollowingLocally,
      errorMessage: errorMessage,
    );
  }
}

class RestaurantProfileController
    extends FamilyNotifier<RestaurantProfileState, String> {
  @override
  RestaurantProfileState build(String restaurantId) {
    Future.microtask(load);
    return const RestaurantProfileState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final restaurant = await ref.read(restaurantRepositoryProvider).show(arg);
      state = RestaurantProfileState(restaurant: restaurant, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load this restaurant.',
      );
    }
  }

  /// No `is_following` flag comes back from GET /restaurants/{id} today, so
  /// this can only optimistically toggle for the current session — it won't
  /// reflect real follow state across reloads until the API exposes one.
  Future<void> toggleFollow() async {
    final restaurant = state.restaurant;
    if (restaurant == null) return;

    final wasFollowing = state.isFollowingLocally;
    final delta = wasFollowing ? -1 : 1;
    state = state.copyWith(
      isFollowingLocally: !wasFollowing,
      restaurant: restaurant.copyWith(
        followersCount: (restaurant.followersCount ?? 0) + delta,
      ),
    );

    try {
      final social = ref.read(socialRemoteDataSourceProvider);
      final count = wasFollowing
          ? await social.unfollowRestaurant(arg)
          : await social.followRestaurant(arg);
      state = state.copyWith(
        restaurant: state.restaurant!.copyWith(followersCount: count),
      );
    } catch (_) {
      state = state.copyWith(
        isFollowingLocally: wasFollowing,
        restaurant: restaurant,
      );
    }
  }
}

final restaurantProfileControllerProvider =
    NotifierProvider.family<
      RestaurantProfileController,
      RestaurantProfileState,
      String
    >(RestaurantProfileController.new);
