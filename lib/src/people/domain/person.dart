import 'package:khmer_cat_app/core/config/app_config.dart';

/// Someone in a followers / following / reviewers list.
class Person {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;

  /// The signed-in viewer themself (no Follow button).
  final bool isMe;

  /// The viewer already follows them.
  final bool isFollowing;

  /// Only in a restaurant's reviewers list: their reviews of it.
  final int? reviewsCount;

  const Person({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
    this.isMe = false,
    this.isFollowing = false,
    this.reviewsCount,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    profilePicture: switch (json['profile_thumbnail'] ??
        json['profile_picture']) {
      final String url when url.isNotEmpty => AppConfig.fixMediaUrl(url),
      _ => null,
    },
    isMe: json['is_me'] == true,
    isFollowing: json['is_following'] == true,
    reviewsCount: (json['reviews_count'] as num?)?.toInt(),
  );

  Person copyWith({bool? isFollowing}) => Person(
    id: id,
    name: name,
    username: username,
    profilePicture: profilePicture,
    isMe: isMe,
    isFollowing: isFollowing ?? this.isFollowing,
    reviewsCount: reviewsCount,
  );
}
