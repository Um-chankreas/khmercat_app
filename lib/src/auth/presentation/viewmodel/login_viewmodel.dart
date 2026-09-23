// lib/features/auth/presentation/viewmodels/login_viewmodel.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';

class LoginViewModel extends AsyncNotifier<Auth?> {
  @override
  FutureOr<Auth?> build() => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repo.login(email: email, password: password),
    );
    state = result;
    result.whenData((authResult) {
      ref
          .read(authControllerProvider.notifier)
          .setAuthenticated(authResult.user);
    });
  }
}

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, Auth?>(
  LoginViewModel.new,
);
