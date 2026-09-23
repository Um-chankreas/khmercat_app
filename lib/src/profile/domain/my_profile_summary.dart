// lib/src/profile/domain/my_profile_summary.dart
import 'package:khmer_cat_app/core/config/app_config.dart';

/// GET /profile/{userId} — counts for the signed-in user's own profile
/// header (Following/Followers/Posts/Likes). The rest of the header (name,
/// username, bio, avatar) already comes from the signed-in [User] entity.
class MyProfileSummary {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final String? bio;
  final String email;
  final int followingCount;
  final int followersCount;
  final int postsCount;
  final int likesCount;

  MyProfileSummary({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.bio,
    required this.email,
    required this.followingCount,
    required this.followersCount,
    required this.postsCount,
    required this.likesCount,
  });

  factory MyProfileSummary.fromJson(Map<String, dynamic> json) =>
      MyProfileSummary(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        avatar: (json['avatar'] as String?) != null
            ? AppConfig.fixMediaUrl(json['avatar'] as String)
            : null,
        bio: json['bio'] as String?,
        email: json['email'] as String? ?? '',
        followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      );
}
