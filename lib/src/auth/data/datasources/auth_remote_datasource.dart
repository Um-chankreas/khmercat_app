import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/src/auth/data/model/auth_model.dart';

import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient _client;
  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final json = await _client.post(
      ApiRoute.login,
      body: {'email': email, 'password': password},
    );
    return json.dataMap;
  }

  /// No email-OTP step in the currently wired-up flow — this returns
  /// `{ token, user }` immediately, same shape as [login].
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      ApiRoute.register,
      body: {'name': name, 'email': email, 'password': password},
    );
    return json.dataMap;
  }

  Future<AuthModel> verifyEmail({
    required String userId,
    required String otp,
  }) async {
    final json = await _client.post(
      ApiRoute.verifyEmail,
      body: {'user_id': userId, 'otp': otp},
    );
    return AuthModel.fromJson(json.dataMap);
  }

  Future<void> resendVerificationCode({required String userId}) async {
    await _client.post(ApiRoute.resendOTP, body: {'user_id': userId});
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final json = await _client.get(ApiRoute.getUserAccount);
    return json.dataMap;
  }

  Future<void> logout() async {
    await _client.post(ApiRoute.logout);
  }
}
