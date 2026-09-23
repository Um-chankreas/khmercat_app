import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/data/repositories/restaurant_repository.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// 0..1 upload progress of the create request (dominated by the logo file),
/// so the form can show it on the logo and the Create button.
final createRestaurantProgressProvider = StateProvider<double>((ref) => 0);

class CreateRestaurantViewModel extends AsyncNotifier<CreatedRestaurant?> {
  @override
  FutureOr<CreatedRestaurant?> build() => null;

  Future<void> create({
    required String name,
    required String categoryId,
    required File profilePicture,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    File? coverPicture,
  }) async {
    state = const AsyncLoading();
    ref.read(createRestaurantProgressProvider.notifier).state = 0;
    final result = await AsyncValue.guard(
      () => ref
          .read(restaurantRepositoryProvider)
          .create(
            name: name,
            categoryId: categoryId,
            profilePicture: profilePicture,
            description: description,
            address: address,
            latitude: latitude,
            longitude: longitude,
            coverPicture: coverPicture,
            onProgress: (sent, total) {
              if (total > 0) {
                ref.read(createRestaurantProgressProvider.notifier).state =
                    sent / total;
              }
            },
          ),
    );
    state = result;
    result.whenData((created) {
      ref
          .read(authControllerProvider.notifier)
          .setAuthenticated(created.user.toEntity());
      ref.invalidate(myRestaurantsControllerProvider);
    });
  }
}

final createRestaurantViewModelProvider =
    AsyncNotifierProvider<CreateRestaurantViewModel, CreatedRestaurant?>(
      CreateRestaurantViewModel.new,
    );
