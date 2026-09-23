import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/video_feed_item.dart';

/// How long we'll wait for a video to start buffering before treating it as
/// failed — otherwise a slow/unreachable server just spins forever with no
/// feedback.
const _initTimeout = Duration(seconds: 20);

/// Keeps a small window (current ± 1) of live [VideoPlayerController]
/// instances alive and buffering, so the next/previous video is already
/// ready by the time the user swipes to it — instead of only ever starting
/// playback on-demand right as a page becomes visible, which is what made
/// scrolling feel like it snaps onto a blank/loading video every time.
/// Controllers outside the window get disposed to avoid memory blowup.
class VideoControllerManager extends ChangeNotifier {
  final Map<String, VideoPlayerController> _controllers = {};
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

  VideoPlayerController? controllerFor(String videoId) => _controllers[videoId];
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
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _failed.clear();
      return;
    }

    final windowIndices = <int>{
      activeIndex - 1,
      activeIndex,
      activeIndex + 1,
    }.where((i) => i >= 0 && i < items.length).toSet();
    final windowIds = windowIndices.map((i) => items[i].id).toSet();

    _controllers.removeWhere((id, controller) {
      if (windowIds.contains(id)) return false;
      controller.dispose();
      return true;
    });
    _failed.removeWhere((id) => !windowIds.contains(id));

    for (final i in windowIndices) {
      _load(items[i]);
    }

    _applyPlaybackState(items, activeIndex, tabIsVisible);
  }

  void _load(VideoFeedItem item) {
    if (_controllers.containsKey(item.id) || _failed.contains(item.id)) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.videoUrl),
    )..setLooping(true);
    _controllers[item.id] = controller;

    controller
        .initialize()
        .timeout(_initTimeout)
        .then((_) {
          if (_disposed) return;
          // Re-apply using the last known window/active state — syncWindow
          // may already have run and skipped this controller while it was
          // still loading.
          _applyPlaybackState(_lastItems, _lastActiveIndex, _lastTabVisible);
          notifyListeners();
        })
        .catchError((_) {
          if (_disposed) return;
          _controllers.remove(item.id)?.dispose();
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

    for (final entry in _controllers.entries) {
      final controller = entry.value;
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
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
