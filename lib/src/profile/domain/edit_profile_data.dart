// lib/src/profile/domain/edit_profile_data.dart
import 'package:khmer_cat_app/core/config/app_config.dart';

class SocialLinks {
  final String? facebook;
  final String? tiktok;
  final String? telegram;

  const SocialLinks({this.facebook, this.tiktok, this.telegram});

  factory SocialLinks.fromJson(Map<String, dynamic>? json) => SocialLinks(
    facebook: json?['facebook'] as String?,
    tiktok: json?['tiktok'] as String?,
    telegram: json?['telegram'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'facebook': facebook,
    'tiktok': tiktok,
    'telegram': telegram,
  };
}

/// GET/PUT /profile/edit — the signed-in user's editable profile fields.
class EditProfileData {
  final String id;
  final String name;
  final String username;
  final String? bio;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final SocialLinks socialLinks;

  EditProfileData({
    required this.id,
    required this.name,
    required this.username,
    this.bio,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.socialLinks = const SocialLinks(),
  });

  factory EditProfileData.fromJson(Map<String, dynamic> json) =>
      EditProfileData(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        bio: json['bio'] as String?,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: (json['avatar_url'] as String?) != null
            ? AppConfig.fixMediaUrl(json['avatar_url'] as String)
            : null,
        socialLinks: SocialLinks.fromJson(
          json['social_links'] as Map<String, dynamic>?,
        ),
      );
}
