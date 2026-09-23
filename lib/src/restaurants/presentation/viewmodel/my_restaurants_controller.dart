import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/data/repositories/restaurant_repository.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// Backs the restaurant "Page-switcher" (GET /restaurants/mine) — also used
/// to decide whether the "post as my restaurant" upload option is shown at
/// all, since that only makes sense once the user owns/manages at least one.
class MyRestaurantsController extends AsyncNotifier<MyRestaurants> {
  @override
  FutureOr<MyRestaurants> build() async {
    if (!ref.watch(isAuthenticatedProvider)) {
      return (activeRestaurantId: null, restaurants: const <Restaurant>[]);
    }
    return ref.read(restaurantRepositoryProvider).mine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(restaurantRepositoryProvider).mine(),
    );
  }

  Future<bool> switchTo(String restaurantId) async {
    final current = state.valueOrNull;
    try {
      final newActiveId = await ref
          .read(restaurantRepositoryProvider)
          .switchTo(restaurantId);
      if (current != null) {
        state = AsyncData((
          activeRestaurantId: newActiveId,
          restaurants: current.restaurants,
        ));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final myRestaurantsControllerProvider =
    AsyncNotifierProvider<MyRestaurantsController, MyRestaurants>(
      MyRestaurantsController.new,
    );
