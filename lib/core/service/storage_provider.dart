// lib/core/service/storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

/// Overridden in main.dart once the secure-storage token cache has been
/// preloaded via [StorageService.init] — see main.dart.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in main.dart',
  );
});
