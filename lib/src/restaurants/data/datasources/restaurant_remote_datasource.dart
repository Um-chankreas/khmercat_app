import 'dart:io';

import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class RestaurantRemoteDataSource {
  final ApiClient _client;
  RestaurantRemoteDataSource(this._client);

  Future<Map<String, dynamic>> show(String id) async {
    final json = await _client.get(ApiRoute.restaurant(id));
    return json.dataMap;
  }

  Future<Map<String, dynamic>> mine() async {
    final json = await _client.get(ApiRoute.myRestaurants);
    return json.dataMap;
  }

  Future<String?> switchTo(String restaurantId) async {
    final json = await _client.post(
      ApiRoute.switchRestaurant,
      body: {'restaurant_id': restaurantId},
    );
    return json.dataMap['active_restaurant_id']?.toString();
  }

  /// Returns `{ user, restaurant }` — the fresh user carries the newly
  /// switched `active_restaurant_id`.
  Future<Map<String, dynamic>> create({
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
    final json = await _client.uploadMultipart(
      ApiRoute.createRestaurant,
      files: {
        'profile_picture': profilePicture,
        'cover_picture': ?coverPicture,
      },
      fields: {
        'name': name,
        'category_id': categoryId,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
      onProgress: onProgress,
    );
    return json.dataMap;
  }
}
