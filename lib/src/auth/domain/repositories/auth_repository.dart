import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Auth> login({required String email, required String password});

  /// Registers and logs the user in immediately — the backend returns
  /// `{ token, user }` with no email-verification step in between.
  Future<Auth> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Auth> verifyEmail({required String userId, required String otp});
  Future<void> resendVerificationCode({required String userId});

  Future<User> getCurrentUser();

  Future<void> logout();

  // sync, local-only reads — used at startup before any network call
  User? getCachedUser();
  bool get hasStoredToken;
}
