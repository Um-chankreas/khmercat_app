import 'dart:io';

import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class ProfileRemoteDataSource {
  final ApiClient _client;
  ProfileRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final json = await _client.get(ApiRoute.myProfile(userId));
    return json.dataMap;
  }

  /// [flag] is `null` (own posts), `'favorite'`, or `'deleted'`.
  /// Page-based (not cursor-based): [page] starts at 1.
  Future<Map<String, dynamic>> getPosts(
    String userId, {
    String? flag,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _client.get(
      ApiRoute.myProfilePosts(userId),
      query: {'flag': ?flag, 'page': page, 'limit': limit},
    );
    return json.dataMap;
  }

  Future<Map<String, dynamic>> toggleFavorite(
    String userId,
    String postId,
  ) async {
    final json = await _client.post(
      ApiRoute.myProfilePostFavorite(userId, postId),
    );
    return json.dataMap;
  }

  Future<void> deletePost(String userId, String postId) {
    return _client.delete(ApiRoute.myProfilePost(userId, postId));
  }

  Future<Map<String, dynamic>> getEditProfile() async {
    final json = await _client.get(ApiRoute.editProfile);
    return json.dataMap;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final json = await _client.put(ApiRoute.editProfile, body: body);
    return json.dataMap;
  }

  /// POST /profile/avatar — multipart, image in the `avatar` field.
  Future<Map<String, dynamic>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      ApiRoute.profileAvatar,
      files: {'avatar': file},
      onProgress: onProgress,
    );
    return json.dataMap;
  }

  /// POST /profile/cover — multipart, image in the `cover` field.
  Future<Map<String, dynamic>> uploadCover(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final json = await _client.uploadMultipart(
      ApiRoute.profileCover,
      files: {'cover': file},
      onProgress: onProgress,
    );
    return json.dataMap;
  }
}
