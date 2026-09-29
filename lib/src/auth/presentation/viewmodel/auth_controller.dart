// lib/features/auth/presentation/viewmodels/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/core/service/push_notification_provider.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';
import '../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  const AuthState({required this.status, this.user});

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(User user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Lets the network layer drop us back to guest state on an
    // unrecoverable 401 (expired token + failed refresh) without
    // core/network importing this feature directly.
    //
    // Deferred to a microtask — Riverpod forbids a provider modifying
    // another provider's state synchronously while it's still building
    // (`sessionExpiredCallbackProvider` here), which threw on every cold
    // start and could cascade into corrupted layout downstream.
    Future.microtask(() {
      ref.read(sessionExpiredCallbackProvider.notifier).state = () {
        state = const AuthState.unauthenticated();
      };
    });
    return const AuthState.initial();
  }

  /// Called once by the splash screen on app startup.
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    final repo = ref.read(authRepositoryProvider);

    if (!repo.hasStoredToken) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      // The dio interceptor already retries once via /auth/refresh-token
      // on a 401, so a failure here means the session is genuinely gone.
      final user = await repo.getCurrentUser();
      setAuthenticated(user);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  void setAuthenticated(User user) {
    state = AuthState.authenticated(user);
    // Fire-and-forget — registering the push token shouldn't block sign-in,
    // and it silently no-ops if Firebase/permission isn't set up yet.
    ref.read(pushNotificationServiceProvider).registerToken();
  }

  Future<void> logout() async {
    await ref.read(pushNotificationServiceProvider).unregisterToken();
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }

  /// Password-confirmed; throws (e.g. a wrong-password [ApiException]) and
  /// stays signed in on failure. The server drops this device's push token.
  Future<void> deactivateAccount(String password) async {
    await ref.read(authRepositoryProvider).deactivateAccount(password);
    state = const AuthState.unauthenticated();
  }

  /// Same as [deactivateAccount], but permanent.
  Future<void> deleteAccount(String password) async {
    await ref.read(authRepositoryProvider).deleteAccount(password);
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// convenience derived providers for easy global access
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authControllerProvider).user,
);
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).status == AuthStatus.authenticated,
);
