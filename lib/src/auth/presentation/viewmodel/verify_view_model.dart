// lib/features/auth/presentation/viewmodels/verify_email_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';

class VerifyEmailState {
  final bool isVerifying;
  final bool isResending;
  final bool verified;
  final String? errorMessage;
  final int resendCooldownSeconds;

  const VerifyEmailState({
    this.isVerifying = false,
    this.isResending = false,
    this.verified = false,
    this.errorMessage,
    this.resendCooldownSeconds = 0,
  });

  VerifyEmailState copyWith({
    bool? isVerifying,
    bool? isResending,
    bool? verified,
    String? errorMessage,
    int? resendCooldownSeconds,
  }) {
    return VerifyEmailState(
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      verified: verified ?? this.verified,
      errorMessage:
          errorMessage, // always overwrite, don't fallback — so it can be cleared
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
    );
  }
}

class VerifyEmailViewModel extends Notifier<VerifyEmailState> {
  Timer? _cooldownTimer;

  @override
  VerifyEmailState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const VerifyEmailState();
  }

  Future<void> verify({required String userId, required String code}) async {
    state = state.copyWith(isVerifying: true, errorMessage: null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyEmail(userId: userId, otp: code);
      ref.read(authControllerProvider.notifier).setAuthenticated(result.user);
      state = state.copyWith(isVerifying: false, verified: true);
    } catch (e) {
      state = state.copyWith(isVerifying: false, errorMessage: e.toString());
    }
  }

  Future<void> resend({required String userId}) async {
    if (state.resendCooldownSeconds > 0) return;

    state = state.copyWith(isResending: true, errorMessage: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerificationCode(userId: userId);
      state = state.copyWith(isResending: false);

      _startCooldown();
    } catch (e) {
      state = state.copyWith(isResending: false, errorMessage: e.toString());
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel(); // cancel any previous timer first
    state = state.copyWith(resendCooldownSeconds: 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
      } else {
        state = state.copyWith(
          resendCooldownSeconds: state.resendCooldownSeconds - 1,
        );
      }
    });
  }
}

final verifyEmailViewModelProvider =
    NotifierProvider<VerifyEmailViewModel, VerifyEmailState>(
      VerifyEmailViewModel.new,
    );
