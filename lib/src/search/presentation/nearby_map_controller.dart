import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/providers/search_providers.dart';

/// The widest radius the map lets the user pick.
const nearbyMapMaxKm = 5.0;

/// The point the map searches around.
typedef MapCenter = ({double lat, double lng});

/// Restaurants within [nearbyMapMaxKm] of a point, nearest first.
///
/// There's no "restaurants near me" endpoint, and `/search` needs a query
/// or a category, so this asks for every category nearest-first and merges
/// the results. The API takes no radius, so the cut-off is applied here.
final nearbyMapProvider = FutureProvider.autoDispose
    .family<List<NearbyRestaurant>, MapCenter>((ref, center) async {
      final repo = ref.read(searchRepositoryProvider);

      var failed = 0;
      final pages = await Future.wait(
        cuisineCategoryIds.values.map((categoryId) async {
          try {
            final r = await repo.search(
              categoryId: categoryId,
              lat: center.lat,
              lng: center.lng,
              nearest: true,
            );
            return r.restaurants;
          } catch (_) {
            failed++;
            return const <Restaurant>[];
          }
        }),
      );
      // Some categories failing still leaves a useful map; all of them
      // failing is an error the screen should show.
      if (failed == cuisineCategoryIds.length) {
        throw Exception('Could not load nearby restaurants');
      }

      final byId = {for (final r in pages.expand((p) => p)) r.id: r};
      final nearby =
          <NearbyRestaurant>[
              for (final r in byId.values)
                if (r.latitude != null && r.longitude != null)
                  (
                    restaurant: r,
                    meters: Geolocator.distanceBetween(
                      center.lat,
                      center.lng,
                      r.latitude!,
                      r.longitude!,
                    ),
                  ),
            ].where((n) => n.meters! <= nearbyMapMaxKm * 1000).toList()
            ..sort((a, b) => a.meters!.compareTo(b.meters!));
      return nearby;
    });
