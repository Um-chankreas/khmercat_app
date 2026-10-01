import 'dart:io';

import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/feed/data/feed_repository.dart' show FeedPage;
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_menu.dart';

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

  Future<Restaurant> update(String id, Map<String, dynamic> fields) async {
    return Restaurant.fromJson(await _remote.update(id, fields));
  }

  Future<void> delete(String id, String password) =>
      _remote.delete(id, password);

  /// Show (true) or hide (false) the restaurant from the public.
  Future<Restaurant> setPublished(String id, bool published) =>
      update(id, {'is_published': published});

  Future<void> deleteVideo(String id, String videoId) =>
      _remote.deleteVideo(id, videoId);

  Future<FeedPage> deletedVideos(String id, {String? cursor}) async {
    final data = await _remote.deletedVideos(id, cursor: cursor);
    final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    return (
      items: (data['contents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoFeedItem.fromJson)
          .toList(),
      nextCursor: meta['next_cursor']?.toString(),
      hasMore: meta['has_more'] == true,
    );
  }

  Future<RestaurantMenu> menu(String id) async =>
      RestaurantMenu.fromJson(await _remote.menu(id));

  Future<RestaurantMenu> uploadMenuPages(
    String id,
    List<File> files, {
    void Function(int sent, int total)? onProgress,
  }) async => RestaurantMenu.fromJson(
    await _remote.uploadMenuPages(id, files, onProgress: onProgress),
  );

  Future<RestaurantMenu> deleteMenuPage(String id, String pageId) async =>
      RestaurantMenu.fromJson(await _remote.deleteMenuPage(id, pageId));

  Future<void> uploadImage(
    String id,
    File file, {
    required bool cover,
    void Function(int sent, int total)? onProgress,
  }) => _remote.uploadImage(id, file, cover: cover, onProgress: onProgress);

  /// Switches the active context; a null [restaurantId] means the user's
  /// personal profile. Returns the new active restaurant id (or null).
  Future<String?> switchTo(String? restaurantId, {String? password}) {
    return _remote.switchTo(restaurantId, password: password);
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
