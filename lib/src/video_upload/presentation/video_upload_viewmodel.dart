// lib/features/video_upload/presentation/video_upload_viewmodel.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/feed_tab.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/presentation/viewmodel/feed_controller.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/video_upload/provider/video_upload_providers.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import '../domain/video_upload_state.dart';

const _maxUploadBytes = 100 * 1024 * 1024; // backend's own 100MB limit

// After upload the server still processes the video in the background, and
// GET /videos/{id} 404s until it's ready — poll for up to ~5 minutes.
const _readyPollInterval = Duration(seconds: 5);
const _readyPollAttempts = 60;

class VideoUploadViewModel extends Notifier<VideoUploadState> {
  final _compressor = VVideoCompressor();

  @override
  VideoUploadState build() => const VideoUploadState();

  Future<void> pickVideo() async {
    state = state.copyWith(stage: UploadStage.picking);

    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) {
      state = const VideoUploadState(); // user cancelled
      return;
    }

    final file = File(picked.path);
    final sizeBytes = await file.length();

    state = VideoUploadState(
      stage: UploadStage.idle,
      originalPath: file.path,
      originalSizeBytes: sizeBytes,
    );
  }

  Future<void> setPickedFile(File file) async {
    final sizeBytes = await file.length();
    state = VideoUploadState(
      stage: UploadStage.idle,
      originalPath: file.path,
      originalSizeBytes: sizeBytes,
    );
  }

  // Last requested upload params — kept so an upload that failed after the
  // user already left the upload screen can be retried from the nav bar
  // without them having to re-enter everything.
  String? _caption;
  bool _postAsRestaurant = false;
  String? _restaurantId;
  Restaurant? _restaurant;
  int? _rating;

  /// Id of the current upload's temporary feed item (see [_showPending]).
  String? _pendingId;

  /// Reviewing a restaurant (restaurantId required) vs a restaurant posting
  /// its own video (restaurantId optional — backend falls back to the
  /// user's active restaurant). These hit different endpoints entirely.
  ///
  /// Fire-and-forget: callers typically leave the upload screen right after
  /// calling this. The provider isn't autoDispose, so it keeps running and
  /// progress is surfaced on the bottom-nav create button.
  Future<void> compressAndUpload({
    String? caption,
    required bool postAsRestaurant,
    String? restaurantId,
    Restaurant? restaurant,
    int? rating,
  }) {
    _pendingId = null;
    _restaurant = restaurant;
    _caption = caption;
    _rating = rating;
    _postAsRestaurant = postAsRestaurant;
    _restaurantId = restaurantId;
    return _run();
  }

  /// Retries the last upload with the same params and picked file.
  Future<void> retry() => _run();

  Future<void> _run() async {
    final caption = _caption;
    final postAsRestaurant = _postAsRestaurant;
    final restaurantId = _restaurantId;
    final rating = _rating;

    if (state.originalPath == null) return;
    if (!postAsRestaurant && (restaurantId == null || restaurantId.isEmpty)) {
      state = state.copyWith(
        stage: UploadStage.error,
        errorMessage: 'Please select a restaurant to review.',
      );
      return;
    }

    if (!postAsRestaurant && (rating == null || rating < 1 || rating > 5)) {
      state = state.copyWith(
        stage: UploadStage.error,
        errorMessage: 'Please give a rating from 1 to 5.',
      );
      return;
    }

    _showPending(caption: caption, rating: rating);
    _loadPendingThumbnail();

    final stopwatch = Stopwatch()..start();
    state = state.copyWith(
      stage: UploadStage.compressing,
      compressionProgress: 0,
    );

    try {
      final result = await _compressor.compressVideo(
        state.originalPath!,
        const VVideoCompressionConfig(quality: VVideoCompressQuality.medium),
        onProgress: (progress) {
          state = state.copyWith(compressionProgress: progress / 100);
        },
      );

      stopwatch.stop();

      if (result == null) {
        _failPending();
        state = state.copyWith(
          stage: UploadStage.error,
          errorMessage: 'Compression failed.',
        );
        return;
      }

      if (result.compressedSizeBytes > _maxUploadBytes) {
        _failPending();
        state = state.copyWith(
          stage: UploadStage.error,
          errorMessage:
              'This video is too large even after compression (max 100MB). '
              'Try a shorter clip.',
        );
        return;
      }

      state = state.copyWith(
        stage: UploadStage.uploading,
        compressedPath: result.compressedFilePath,
        compressedSizeBytes: result.compressedSizeBytes,
        compressionDuration: stopwatch.elapsed,
        uploadProgress: 0,
      );

      final repo = ref.read(videoUploadRepositoryProvider);
      final file = File(result.compressedFilePath);
      void onProgress(int sent, int total) {
        if (total > 0) state = state.copyWith(uploadProgress: sent / total);
      }

      final uploaded = postAsRestaurant
          ? await repo.uploadRestaurantVideo(
              file: file,
              restaurantId: restaurantId,
              caption: caption,
              onProgress: onProgress,
            )
          : await repo.uploadReview(
              file: file,
              restaurantId: restaurantId!,
              rating: rating!,
              caption: caption,
              onProgress: onProgress,
            );

      state = state.copyWith(
        stage: UploadStage.success,
        uploadedVideoId: uploaded.id,
        uploadedVideoStatus: uploaded.status,
      );
      final pendingId = _pendingId;
      _pendingId = null;
      if (pendingId != null) _swapInWhenReady(uploaded.id, pendingId);
    } on ApiException catch (e) {
      // e.message is just the generic "Validation failed" on a 422 — the
      // actual per-field reason lives in e.errors.
      _failPending();
      state = state.copyWith(
        stage: UploadStage.error,
        errorMessage: e.isValidationError ? e.allErrorsMessage : e.message,
      );
    } catch (e) {
      _failPending();
      state = state.copyWith(
        stage: UploadStage.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// A small frame for the feed's posting indicator. Best effort — the
  /// indicator shows a plain tile until (or if never) this arrives.
  Future<void> _loadPendingThumbnail() async {
    final pendingId = _pendingId;
    final path = state.originalPath;
    if (pendingId == null || path == null) return;
    try {
      final thumb = await _compressor.getVideoThumbnail(
        path,
        const VVideoThumbnailConfig(timeMs: 500, maxWidth: 160),
      );
      if (thumb != null) {
        _feed.setPendingThumbnail(pendingId, thumb.thumbnailPath);
      }
    } catch (_) {}
  }

  FeedController get _feed =>
      ref.read(feedControllerProvider(FeedTab.forYou).notifier);

  /// Puts the picked video at the top of the For You feed straight away,
  /// playing from the local file, until the real one is ready.
  void _showPending({String? caption, int? rating}) {
    final user = ref.read(currentUserProvider);
    final path = state.originalPath;
    if (user == null || path == null) return;
    final id = _pendingId ??=
        'pending-${DateTime.now().microsecondsSinceEpoch}';
    final restaurant = _restaurant;
    _feed.insertPending(
      VideoFeedItem(
        id: id,
        caption: caption ?? '',
        videoUrl: path,
        localFilePath: path,
        aspectRatio: 9 / 16,
        commentsCount: 0,
        likesCount: 0,
        likedByMe: false,
        user: FeedAuthor(
          id: user.id,
          name: user.name,
          username: user.username,
          profilePicture: user.profilePicture,
        ),
        restaurant: restaurant == null
            ? null
            : FeedRestaurant(
                id: restaurant.id,
                name: restaurant.name,
                profilePicture: restaurant.profilePicture,
              ),
        createdAt: DateTime.now(),
        rating: rating?.toDouble(),
      ),
    );
  }

  /// Upload failed — take the temporary item out of the feed (a retry puts
  /// it back under the same id).
  void _failPending() {
    final id = _pendingId;
    if (id != null) _feed.removePending(id);
  }

  Future<void> _swapInWhenReady(String videoId, String pendingId) async {
    final repo = ref.read(feedRepositoryProvider);
    for (var i = 0; i < _readyPollAttempts; i++) {
      await Future<void>.delayed(_readyPollInterval);
      try {
        _feed.replacePending(pendingId, await repo.getVideo(videoId));
        return;
      } catch (_) {
        // 404 while the server is still processing — keep waiting.
      }
    }
    // Never became ready (processing failed or is very slow) — stop showing
    // the local copy; a later refresh picks the video up if it does finish.
    _feed.removePending(pendingId);
  }

  void reset() {
    _caption = null;
    _postAsRestaurant = false;
    _restaurantId = null;
    _restaurant = null;
    _rating = null;
    state = const VideoUploadState();
  }
}

final videoUploadViewModelProvider =
    NotifierProvider<VideoUploadViewModel, VideoUploadState>(
      VideoUploadViewModel.new,
    );
