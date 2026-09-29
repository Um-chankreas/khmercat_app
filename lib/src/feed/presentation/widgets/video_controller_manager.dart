import 'dart:async';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' show ClientException;
import 'package:video_player/video_player.dart';

import '../../domain/video_feed_item.dart';

/// How long we'll wait for a video to start buffering before treating it as
/// failed — otherwise a slow/unreachable server just spins forever with no
/// feedback.
const _initTimeout = Duration(seconds: 20);

/// A separate, size-capped disk cache for feed videos (as opposed to
/// flutter_cache_manager's default 200-object cache, which for multi-MB
/// video files could balloon into gigabytes). 40 videos is generous for
/// "the ones you might scroll back to this session" without becoming a
/// storage problem, and a video not rewatched within a week ages out.
final _feedVideoCacheManager = CacheManager(
  Config(
    'feedVideoCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 40,
  ),
);

/// Keeps a small window (current ± 1) of live [VideoPlayerController]
/// instances alive and buffering, so the next/previous video is already
/// ready by the time the user swipes to it — instead of only ever starting
/// playback on-demand right as a page becomes visible, which is what made
/// scrolling feel like it snaps onto a blank/loading video every time.
/// Controllers outside the window get disposed to avoid memory blowup.
///
/// Videos are streamed from the network on first play exactly as before —
/// [CachedVideoPlayerPlus] wraps the same [VideoPlayerController] and starts
/// playback from the network URL immediately, then downloads a copy to disk
/// in the background. Only *replays* (looping, scrolling back to a video
/// you already opened, or coming back to this tab) benefit, by loading from
/// that local file instead of re-fetching over the network.
class VideoControllerManager extends ChangeNotifier {
  final Map<String, CachedVideoPlayerPlus> _players = {};
  final Set<String> _failed = {};
  bool _disposed = false;

  // Cached from the last syncWindow call so a controller that finishes
  // buffering *after* that call can re-check "should I actually be playing
  // now?" — without this, the video that finishes initializing later than
  // the synchronous play-check (always true for whichever video is loading
  // for the very first time) just sits there paused on its first frame.
  List<VideoFeedItem> _lastItems = const [];
  int _lastActiveIndex = -1;
  bool _lastTabVisible = false;

  VideoPlayerController? controllerFor(String videoId) {
    final player = _players[videoId];
    if (player == null || !player.isInitialized) return null;
    return player.controller;
  }

  bool hasFailed(String videoId) => _failed.contains(videoId);

  void syncWindow(
    List<VideoFeedItem> items,
    int activeIndex, {
    required bool tabIsVisible,
  }) {
    if (items.isEmpty) return;

    _lastItems = items;
    _lastActiveIndex = activeIndex;
    _lastTabVisible = tabIsVisible;

    // Off the Home tab entirely (another bottom-nav tab, or a pushed route
    // on top) — fully tear down every live controller instead of just
    // pausing the window. A paused controller still holds its native
    // decoder Surface open, which on some Android devices/OS builds bleeds
    // a black frame across whatever screen is actually on top; nothing
    // needs to keep buffering while the user can't see any of it anyway.
    if (!tabIsVisible) {
      for (final player in _players.values) {
        player.dispose();
      }
      _players.clear();
      _failed.clear();
      return;
    }

    final windowIndices = <int>{
      activeIndex - 1,
      activeIndex,
      activeIndex + 1,
    }.where((i) => i >= 0 && i < items.length).toSet();
    final windowIds = windowIndices.map((i) => items[i].id).toSet();

    _players.removeWhere((id, player) {
      if (windowIds.contains(id)) return false;
      player.dispose();
      return true;
    });
    _failed.removeWhere((id) => !windowIds.contains(id));

    for (final i in windowIndices) {
      _load(items[i]);
    }

    _applyPlaybackState(items, activeIndex, tabIsVisible);
  }

  void _load(VideoFeedItem item) {
    if (_players.containsKey(item.id) || _failed.contains(item.id)) return;

    // A pending upload plays straight from the file on this device.
    final localPath = item.localFilePath;
    final player = localPath != null
        ? CachedVideoPlayerPlus.file(File(localPath))
        : CachedVideoPlayerPlus.networkUrl(
            Uri.parse(item.videoUrl),
            cacheManager: _feedVideoCacheManager,
          );
    _players[item.id] = player;

    // The package caches the file with a fire-and-forget download that has
    // no error handler, so a dropped connection mid-download surfaced as an
    // "Unhandled Exception". Unhandled async errors go to the zone they were
    // created in, so running initialize() in this zone catches exactly
    // those. The chain's own catchError below is registered in the same
    // zone, so real playback failures still reach it.
    runZonedGuarded(() => _initialize(item, player), _onBackgroundCacheError);
  }

  /// Only the background cache download lands here; the video already plays
  /// from the network and just gets cached on a later view.
  static void _onBackgroundCacheError(Object error, StackTrace stack) {
    if (error is ClientException ||
        error is IOException ||
        error is HttpExceptionWithStatus) {
      debugPrint('Video cache download failed (will retry later): $error');
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'video_controller_manager',
      ),
    );
  }

  void _initialize(VideoFeedItem item, CachedVideoPlayerPlus player) {
    player
        .initialize()
        .timeout(_initTimeout)
        .then((_) async {
          if (_disposed) return;
          await player.controller.setLooping(true);
          if (_disposed) return;
          // Re-apply using the last known window/active state — syncWindow
          // may already have run and skipped this controller while it was
          // still loading.
          _applyPlaybackState(_lastItems, _lastActiveIndex, _lastTabVisible);
          notifyListeners();
        })
        .catchError((_) {
          if (_disposed) return;
          _players.remove(item.id)?.dispose();
          _failed.add(item.id);
          notifyListeners();
        });
  }

  void _applyPlaybackState(
    List<VideoFeedItem> items,
    int activeIndex,
    bool tabIsVisible,
  ) {
    final activeId = (activeIndex >= 0 && activeIndex < items.length)
        ? items[activeIndex].id
        : null;

    for (final entry in _players.entries) {
      final player = entry.value;
      if (!player.isInitialized) continue;
      final controller = player.controller;
      if (!controller.value.isInitialized) continue;

      final shouldPlay = tabIsVisible && entry.key == activeId;
      if (shouldPlay && !controller.value.isPlaying) {
        controller.play();
      } else if (!shouldPlay && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void retry(VideoFeedItem item) {
    _failed.remove(item.id);
    _load(item);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    super.dispose();
  }
}
