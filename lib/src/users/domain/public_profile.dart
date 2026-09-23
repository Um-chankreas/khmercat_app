import 'package:khmer_cat_app/core/config/app_config.dart';

class PublicProfile {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;
  final String? coverPicture;
  final String? bio;
  final int? followersCount;

  PublicProfile({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    this.coverPicture,
    this.bio,
    this.followersCount,
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
  );

  PublicProfile copyWith({int? followersCount}) => PublicProfile(
    id: id,
    name: name,
    username: username,
    profilePicture: profilePicture,
    coverPicture: coverPicture,
    bio: bio,
    followersCount: followersCount ?? this.followersCount,
  );
}
