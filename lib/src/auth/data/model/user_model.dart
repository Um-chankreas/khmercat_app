import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profilePicture;
  final String? coverPicture;
  final String? bio;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profilePicture,
    this.coverPicture,
    this.bio,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
    coverPicture: (json['cover_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['cover_picture'] as String)
        : null,
    bio: json['bio'] as String?,
    isAdmin: json['is_admin'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'profile_picture': profilePicture,
    'cover_picture': coverPicture,
    'bio': bio,
    'is_admin': isAdmin,
  };

  User toEntity() => User(
    id: id,
    name: name,
    username: username,
    email: email,
    profilePicture: profilePicture,
    coverPicture: coverPicture,
    bio: bio,
    isAdmin: isAdmin,
  );
}
