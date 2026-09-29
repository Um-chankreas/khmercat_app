import 'dart:convert';

import 'package:khmer_cat_app/core/service/storage_service.dart';
import 'package:khmer_cat_app/src/auth/data/model/auth_model.dart';
import 'package:khmer_cat_app/src/auth/data/model/user_model.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final StorageService _storage;
  AuthRepositoryImpl(this._remote, this._storage);

  Future<Auth> _persistAndReturn(AuthModel authModel) async {
    await _storage.saveToken(authModel.token);
    await _storage.saveUser(jsonEncode(authModel.user.toJson()));
    return authModel.toEntity();
  }

  @override
  Future<Auth> login({required String email, required String password}) async {
    final data = await _remote.login(email, password);
    return _persistAndReturn(AuthModel.fromJson(data));
  }

  @override
  Future<Auth> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _remote.register(
      name: name,
      email: email,
      password: password,
    );
    return _persistAndReturn(AuthModel.fromJson(data));
  }

  @override
  Future<Auth> verifyEmail({
    required String userId,
    required String otp,
  }) async {
    final authModel = await _remote.verifyEmail(userId: userId, otp: otp);
    return _persistAndReturn(authModel);
  }

  @override
  Future<void> resendVerificationCode({required String userId}) async {
    await _remote.resendVerificationCode(userId: userId);
  }

  @override
  Future<User> getCurrentUser() async {
    // GET /auth/get-user-account responds with `data: { user: {...} }`.
    final data = await _remote.getCurrentUser();
    final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveUser(jsonEncode(userModel.toJson()));
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // best-effort — always drop the local session even if this fails
    }
    await _storage.clearSession();
  }

  @override
  Future<void> deactivateAccount(String password) async {
    await _remote.deactivateAccount(password);
    await _storage.clearSession();
  }

  @override
  Future<void> deleteAccount(String password) async {
    await _remote.deleteAccount(password);
    await _storage.clearSession();
  }

  @override
  User? getCachedUser() {
    final jsonStr = _storage.getUser();
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr)).toEntity();
  }

  @override
  bool get hasStoredToken => _storage.getToken() != null;
}
