import 'package:khmer_cat_app/core/config/app_config.dart';

class RestaurantCategory {
  final String id;
  final String name;
  final String? icon;

  RestaurantCategory({required this.id, required this.name, this.icon});

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) =>
      RestaurantCategory(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String?,
      );
}

class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? profilePicture;
  final String? coverPicture;
  final double? latitude;
  final double? longitude;
  final String status;
  final int? followersCount;
  final RestaurantCategory? category;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.profilePicture,
    this.coverPicture,
    this.latitude,
    this.longitude,
    required this.status,
    this.followersCount,
    this.category,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    address: json['address'] as String?,
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
    coverPicture: (json['cover_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['cover_picture'] as String)
        : null,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'pending',
    followersCount: (json['followers_count'] as num?)?.toInt(),
    category: json['category'] != null
        ? RestaurantCategory.fromJson(json['category'] as Map<String, dynamic>)
        : null,
  );

  Restaurant copyWith({int? followersCount}) => Restaurant(
    id: id,
    name: name,
    description: description,
    address: address,
    profilePicture: profilePicture,
    coverPicture: coverPicture,
    latitude: latitude,
    longitude: longitude,
    status: status,
    followersCount: followersCount ?? this.followersCount,
    category: category,
  );
}
