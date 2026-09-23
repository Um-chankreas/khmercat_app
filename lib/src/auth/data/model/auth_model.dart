import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';

class AuthModel {
  final String token;
  final UserModel user;

  AuthModel({required this.token, required this.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
    token: json['token'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );

  Auth toEntity() => Auth(token: token, user: user.toEntity());
}
