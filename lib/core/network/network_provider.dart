// lib/core/network/network_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/service/storage_provider.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'reverb_socket.dart';

/// Set by AuthController on startup so the network layer can flip global
/// auth state back to "unauthenticated" on a hard session expiry, without
/// core/network importing the auth feature directly.
final sessionExpiredCallbackProvider = StateProvider<void Function()?>(
  (ref) => null,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(
    baseUrl: AppConfig.baseUrl,
    storage: storage,
    onSessionExpired: () => ref.read(sessionExpiredCallbackProvider)?.call(),
  );
});

/// One shared Reverb connection for the whole app — see [ReverbSocket]'s doc
/// comment for why a single multiplexed socket instead of one per feature.
final reverbSocketProvider = Provider<ReverbSocket>((ref) => ReverbSocket());
