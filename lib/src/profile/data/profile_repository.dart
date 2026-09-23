import 'dart:io';

import 'package:khmer_cat_app/src/profile/domain/edit_profile_data.dart';
import 'package:khmer_cat_app/src/profile/domain/my_profile_summary.dart';
import 'package:khmer_cat_app/src/profile/domain/profile_post.dart';

import 'profile_remote_datasource.dart';

typedef ProfilePostsPage = ({
  List<ProfilePost> items,
  int currentPage,
  int? nextPage,
  bool hasMore,
});

class ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepository(this._remote);

  Future<MyProfileSummary> getProfile(String userId) async {
    final data = await _remote.getProfile(userId);
    return MyProfileSummary.fromJson(data);
  }

  Future<ProfilePostsPage> getPosts(
    String userId, {
    String? flag,
    int page = 1,
  }) async {
    final data = await _remote.getPosts(userId, flag: flag, page: page);
    final contents = (data['data'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ProfilePost.fromJson)
        .toList();
    final pagination =
        (data['pagination'] as Map?)?.cast<String, dynamic>() ?? {};
    final nextPage = (pagination['next_page'] as num?)?.toInt();

    return (
      items: contents,
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? page,
      nextPage: nextPage,
      hasMore: nextPage != null,
    );
  }

  Future<ProfilePost> toggleFavorite(String userId, String postId) async {
    final data = await _remote.toggleFavorite(userId, postId);
    return ProfilePost.fromJson(data);
  }

  Future<void> deletePost(String userId, String postId) {
    return _remote.deletePost(userId, postId);
  }

  Future<EditProfileData> getEditProfile() async {
    final data = await _remote.getEditProfile();
    return EditProfileData.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<EditProfileData> updateProfile({
    required String name,
    String? bio,
    required String email,
    String? phone,
    SocialLinks socialLinks = const SocialLinks(),
  }) async {
    final data = await _remote.updateProfile({
      'name': name,
      'bio': bio,
      'email': email,
      'phone': phone,
      'social_links': socialLinks.toJson(),
    });
    return EditProfileData.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) => _remote.uploadAvatar(file, onProgress: onProgress);

  Future<Map<String, dynamic>> uploadCover(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) => _remote.uploadCover(file, onProgress: onProgress);
}
