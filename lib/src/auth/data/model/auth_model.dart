import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';

class AuthModel {
  final String token;
  final UserModel user;
  final bool reactivated;

  AuthModel({
    required this.token,
    required this.user,
    this.reactivated = false,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
    token: json['token'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    reactivated: json['reactivated'] == true,
  );

  Auth toEntity() =>
      Auth(token: token, user: user.toEntity(), reactivated: reactivated);
}
