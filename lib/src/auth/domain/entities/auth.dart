import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';

class Auth {
  final String token;
  final User user;

  Auth({required this.token, required this.user});
}
