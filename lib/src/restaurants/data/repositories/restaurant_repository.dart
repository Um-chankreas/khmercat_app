import 'dart:io';

import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

import '../datasources/restaurant_remote_datasource.dart';

typedef MyRestaurants = ({
  String? activeRestaurantId,
  List<Restaurant> restaurants,
});
typedef CreatedRestaurant = ({UserModel user, Restaurant restaurant});

class RestaurantRepository {
  final RestaurantRemoteDataSource _remote;
  RestaurantRepository(this._remote);

  Future<Restaurant> show(String id) async {
    return Restaurant.fromJson(await _remote.show(id));
  }

  Future<MyRestaurants> mine() async {
    final data = await _remote.mine();
    final restaurants = (data['restaurants'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Restaurant.fromJson)
        .toList();
    return (
      activeRestaurantId: data['active_restaurant_id']?.toString(),
      restaurants: restaurants,
    );
  }

  Future<String?> switchTo(String restaurantId) {
    return _remote.switchTo(restaurantId);
  }

  Future<CreatedRestaurant> create({
    required String name,
    required String categoryId,
    required File profilePicture,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    File? coverPicture,
    void Function(int sent, int total)? onProgress,
  }) async {
    final data = await _remote.create(
      name: name,
      categoryId: categoryId,
      profilePicture: profilePicture,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      coverPicture: coverPicture,
      onProgress: onProgress,
    );
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      restaurant: Restaurant.fromJson(
        data['restaurant'] as Map<String, dynamic>,
      ),
    );
  }
}
