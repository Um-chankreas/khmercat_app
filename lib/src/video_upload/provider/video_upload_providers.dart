// lib/features/video_upload/providers/video_upload_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import '../data/video_upload_repository.dart';

final videoUploadRepositoryProvider = Provider<VideoUploadRepository>((ref) {
  return VideoUploadRepository(ref.watch(apiClientProvider));
});
