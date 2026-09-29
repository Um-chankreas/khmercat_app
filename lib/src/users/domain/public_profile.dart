import 'package:khmer_cat_app/core/config/app_config.dart';

class PublicProfile {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;
  final String? coverPicture;
  final String? bio;
  final int? followersCount;
  final int followingCount;
  final int postsCount;
  final int likesReceived;

  // Sent by the search API.
  final bool isVerified;
  final int reviewsCount;
  final bool isFollowing;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? telegramUsername;

  PublicProfile({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    this.coverPicture,
    this.bio,
    this.followersCount,
    this.followingCount = 0,
    this.postsCount = 0,
    this.likesReceived = 0,
    this.isVerified = false,
    this.reviewsCount = 0,
    this.isFollowing = false,
    this.facebookUrl,
    this.tiktokUrl,
    this.telegramUsername,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
    coverPicture: (json['cover_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['cover_picture'] as String)
        : null,
    bio: json['bio'] as String?,
    followersCount: (json['followers_count'] as num?)?.toInt(),
    followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
    likesReceived: (json['total_likes_received'] as num?)?.toInt() ?? 0,
    isVerified: json['is_verified'] == true,
    reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    isFollowing: json['is_following'] == true,
    facebookUrl: json['facebook_url'] as String?,
    tiktokUrl: json['tiktok_url'] as String?,
    telegramUsername: json['telegram_username'] as String?,
  );

  PublicProfile copyWith({int? followersCount, bool? isFollowing}) =>
      PublicProfile(
        id: id,
        name: name,
        username: username,
        profilePicture: profilePicture,
        coverPicture: coverPicture,
        bio: bio,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount,
        postsCount: postsCount,
        likesReceived: likesReceived,
        isVerified: isVerified,
        reviewsCount: reviewsCount,
        isFollowing: isFollowing ?? this.isFollowing,
        facebookUrl: facebookUrl,
        tiktokUrl: tiktokUrl,
        telegramUsername: telegramUsername,
      );
}
