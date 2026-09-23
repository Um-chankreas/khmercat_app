// lib/features/video_upload/data/video_upload_repository.dart
import 'dart:io';

import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/utils/app_log.dart';

import '../../../core/network/api_client.dart';

typedef UploadedVideo = ({String id, String status});

class VideoUploadRepository {
  final ApiClient _client;
  VideoUploadRepository(this._client);

  /// A normal user reviewing a restaurant they picked — restaurant_id is
  /// required by the backend.
  Future<UploadedVideo> uploadReview({
    required File file,
    required String restaurantId,
    required int rating,
    String? caption,
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      ApiRoute.uploadReviewVideo,
      files: {'video': file},
      fields: {
        'restaurant_id': restaurantId,
        'rating': rating.toString(),
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
      onProgress: onProgress,
    );
    return _asUploadedVideo(json.dataMap);
  }

  /// A restaurant owner/manager posting on behalf of their restaurant.
  /// Omitting restaurantId lets the backend fall back to the user's active
  /// (switched-to) restaurant.
  Future<UploadedVideo> uploadRestaurantVideo({
    required File file,
    String? restaurantId,
    String? caption,
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      ApiRoute.uploadRestaurantVideo,
      files: {'video': file},
      fields: {
        'restaurant_id': ?restaurantId,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
      onProgress: onProgress,
    );
    return _asUploadedVideo(json.dataMap);
  }

  UploadedVideo _asUploadedVideo(Map<String, dynamic> data) {
    final id = data['id'];
    final status = data['status'];
    if (id == null || status == null) {
      // Turns a raw "type 'Null' is not a subtype of type 'String'" crash
      // into a message the UI already knows how to show, and logs the
      // actual response so we can see why the shape was unexpected.
      AppLog.info('Unexpected upload response shape: $data');
      throw ApiException(
        message:
            'The upload may have gone through, but the server\'s response '
            'was missing expected data. Check the feed in a moment — if the '
            'video doesn\'t show up, try uploading again.',
      );
    }
    return (id: id.toString(), status: status as String);
  }
}
