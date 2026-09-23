import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';

import '../data/datasources/restaurant_remote_datasource.dart';
import '../data/repositories/restaurant_repository.dart';

final restaurantRemoteDataSourceProvider = Provider<RestaurantRemoteDataSource>(
  (ref) {
    return RestaurantRemoteDataSource(ref.watch(apiClientProvider));
  },
);

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(restaurantRemoteDataSourceProvider));
});
