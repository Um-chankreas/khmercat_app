import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
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

  /// Reloads the list without a loading flash (e.g. after editing a
  /// restaurant's name or logo, so the switcher and bottom bar update).
  Future<void> reloadQuietly() async {
    try {
      state = AsyncData(await ref.read(restaurantRepositoryProvider).mine());
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(restaurantRepositoryProvider).mine(),
    );
  }

  /// Switches the app's active profile to a restaurant.
  Future<bool> switchTo(String restaurantId) async {
    try {
      await _switch(restaurantId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Switches back to the user's personal profile, which the API only
  /// allows with the account [password]. Returns null on success, otherwise
  /// the message to show (e.g. "Incorrect password.").
  Future<String?> switchToPersonal(String password) async {
    try {
      await _switch(null, password: password);
      return null;
    } on ApiException catch (e) {
      return e.fieldError('password') ?? e.message;
    } catch (_) {
      return 'Could not switch profile. Please try again.';
    }
  }

  Future<void> _switch(String? restaurantId, {String? password}) async {
    final current = state.valueOrNull;
    final newActiveId = await ref
        .read(restaurantRepositoryProvider)
        .switchTo(restaurantId, password: password);
    if (current != null) {
      state = AsyncData((
        activeRestaurantId: newActiveId,
        restaurants: current.restaurants,
      ));
    }
  }
}

final myRestaurantsControllerProvider =
    AsyncNotifierProvider<MyRestaurantsController, MyRestaurants>(
      MyRestaurantsController.new,
    );

/// The restaurant the user is currently acting as, or null when they're
/// using their personal profile (also null for guests / while loading).
final activeRestaurantProvider = Provider<Restaurant?>((ref) {
  final data = ref.watch(myRestaurantsControllerProvider).valueOrNull;
  final id = data?.activeRestaurantId;
  if (data == null || id == null) return null;
  for (final r in data.restaurants) {
    if (r.id == id) return r;
  }
  return null;
});
