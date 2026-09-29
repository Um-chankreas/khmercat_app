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

  /// PUT /restaurants/{id} — owner/manager only; send just what changed.
  /// Returns the updated restaurant.
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final json = await _client.put(ApiRoute.restaurant(id), body: fields);
    return json.dataMap;
  }

  /// DELETE /restaurants/{id} — owner only, confirmed with their password.
  Future<void> delete(String id, String password) async {
    await _client.delete(ApiRoute.restaurant(id), body: {'password': password});
  }

  /// GET /restaurants/{id}/menu — public.
  Future<Map<String, dynamic>> menu(String id) async {
    final json = await _client.get(ApiRoute.restaurantMenu(id));
    return json.dataMap;
  }

  /// POST /restaurants/{id}/menu — appends pages (multipart `images[n]`).
  Future<Map<String, dynamic>> uploadMenuPages(
    String id,
    List<File> files, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      ApiRoute.restaurantMenu(id),
      files: {for (var i = 0; i < files.length; i++) 'images[$i]': files[i]},
      onProgress: onProgress,
    );
    return json.dataMap;
  }

  Future<Map<String, dynamic>> deleteMenuPage(String id, String pageId) async {
    final json = await _client.delete(ApiRoute.restaurantMenuPage(id, pageId));
    return json.dataMap;
  }

  /// POST /restaurants/{id}/avatar or /cover — multipart image upload.
  Future<Map<String, dynamic>> uploadImage(
    String id,
    File file, {
    required bool cover,
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      cover ? ApiRoute.restaurantCover(id) : ApiRoute.restaurantAvatar(id),
      files: {cover ? 'cover' : 'avatar': file},
      onProgress: onProgress,
    );
    return json.dataMap;
  }

  Future<Map<String, dynamic>> mine() async {
    final json = await _client.get(ApiRoute.myRestaurants);
    return json.dataMap;
  }

  /// Null [restaurantId] switches back to the personal profile, which
  /// needs the account [password].
  Future<String?> switchTo(String? restaurantId, {String? password}) async {
    final json = await _client.post(
      ApiRoute.switchRestaurant,
      body: {'restaurant_id': restaurantId, 'password': ?password},
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
