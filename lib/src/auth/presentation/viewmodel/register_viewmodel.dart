import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/auth.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';

class RegisterViewModel extends AsyncNotifier<Auth?> {
  @override
  FutureOr<Auth?> build() => null;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repo.register(name: name, email: email, password: password),
    );
    state = result;
    result.whenData((auth) {
      ref.read(authControllerProvider.notifier).setAuthenticated(auth.user);
    });
  }
}

final registerViewModelProvider =
    AsyncNotifierProvider<RegisterViewModel, Auth?>(RegisterViewModel.new);
