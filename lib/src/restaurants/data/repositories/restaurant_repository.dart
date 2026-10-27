import 'dart:io';

import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/feed/data/feed_repository.dart' show FeedPage;
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_menu.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_review.dart';

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

  Future<ReviewsPage> reviews(
    String id, {
    bool withVideoOnly = false,
    String? cursor,
  }) async => ReviewsPage.fromJson(
    await _remote.reviews(
      id,
      filter: withVideoOnly ? 'video' : null,
      cursor: cursor,
    ),
  );

  Future<RestaurantReview> postReview(
    String id, {
    required int rating,
    required String comment,
  }) async => RestaurantReview.fromJson(
    await _remote.postReview(id, rating: rating, comment: comment),
  );

  Future<int> likeReview(String reviewId, {required bool like}) =>
      _remote.likeReview(reviewId, like: like);

  Future<RestaurantReview> replyToReview(String reviewId, String text) async =>
      RestaurantReview.fromJson(await _remote.replyToReview(reviewId, text));

  Future<void> deleteReviewReply(String reviewId) =>
      _remote.deleteReviewReply(reviewId);

  Future<List<RestaurantHoliday>> postHoliday({
    required List<String> restaurantIds,
    required DateTime date,
    int days = 1,
    required String title,
    required HolidayMode mode,
    String? opensAt,
    String? closesAt,
    String? description,
    File? image,
    void Function(int sent, int total)? onProgress,
  }) async {
    final d = date;
    final data = await _remote.postHoliday(
      restaurantIds: restaurantIds,
      date:
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}',
      days: days,
      title: title,
      mode: mode.key,
      opensAt: mode == HolidayMode.special ? opensAt : null,
      closesAt: mode == HolidayMode.special ? closesAt : null,
      description: description,
      image: image,
      onProgress: onProgress,
    );
    return data
        .cast<Map<String, dynamic>>()
        .map(RestaurantHoliday.fromJson)
        .toList();
  }

  Future<void> deleteHoliday(String holidayId) =>
      _remote.deleteHoliday(holidayId);

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
