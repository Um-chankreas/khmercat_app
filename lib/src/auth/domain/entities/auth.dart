import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';

class Auth {
  final String token;
  final User user;

  /// True when this login brought a deactivated account back.
  final bool reactivated;

  Auth({required this.token, required this.user, this.reactivated = false});
}
