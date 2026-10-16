import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// The full record of a restaurant shown in the feed, for its average
/// rating and category: a feed item's own `restaurant` only carries id,
/// name and picture. Fetched once per restaurant and kept, since the same
/// few restaurants repeat down the feed. Null if it can't be loaded.
// TODO(backend): send `avg_rating` and `category` on the feed's `restaurant`
// object, then this lookup can go.
final feedRestaurantProvider = FutureProvider.family<Restaurant?, String>((
  ref,
  id,
) async {
  try {
    return await ref.read(restaurantRepositoryProvider).show(id);
  } catch (_) {
    return null;
  }
});
