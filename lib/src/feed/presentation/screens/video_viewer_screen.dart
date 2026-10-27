import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';
import '../../domain/video_feed_item.dart';
import '../../providers/feed_providers.dart';
import '../widgets/feed_action_rail.dart';
import '../widgets/feed_info_overlay.dart';
import '../widgets/feed_video_page.dart';
import '../widgets/share_video.dart';
import '../widgets/video_controller_manager.dart';
import 'comments_sheet.dart';
import 'package:khmer_cat_app/src/feed/presentation/widgets/video_options_sheet.dart';

/// What the video viewer opens: [videos] to swipe through, starting at
/// [initialIndex]. Pass this as the route's `extra`; a lone [VideoFeedItem]
/// works too and opens just that video.
class VideoViewerArgs {
  final List<VideoFeedItem> videos;
  final int initialIndex;
  const VideoViewerArgs({required this.videos, this.initialIndex = 0});
}

/// Full-screen playback for entry points outside the main feed — a
/// restaurant's or a user's video grid, search, a notification. Swipe up and
/// down through the videos it was opened with, with the same like / comment
/// / save / follow actions as the feed.
class VideoViewerScreen extends HookConsumerWidget {
  final List<VideoFeedItem> videos;
  final int initialIndex;
  const VideoViewerScreen({
    required this.videos,
    this.initialIndex = 0,
    super.key,
  });

  /// Builds the screen from a route's `extra`.
  factory VideoViewerScreen.fromExtra(Object? extra) => switch (extra) {
    VideoViewerArgs(:final videos, :final initialIndex) => VideoViewerScreen(
      videos: videos,
      initialIndex: initialIndex.clamp(0, videos.length - 1),
    ),
    final VideoFeedItem video => VideoViewerScreen(videos: [video]),
    _ => throw ArgumentError('VideoViewerScreen needs a video to show'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local copies, so likes / saves / follows show up right away.
    final items = useState(videos);
    final index = useState(initialIndex);
    final pages = usePageController(initialPage: initialIndex);
    final videoManager = useMemoized(() => VideoControllerManager());
    useEffect(() => videoManager.dispose, [videoManager]);
    useListenable(videoManager);
    // Plays the current video and preloads its neighbours.
    useEffect(() {
      videoManager.syncWindow(items.value, index.value, tabIsVisible: true);
      return null;
    }, [items.value, index.value]);
    // Counts a view for each video as it comes on screen.
    final currentId = items.value[index.value].id;
    useEffect(() {
      ref.read(feedRepositoryProvider).recordView(currentId);
      return null;
    }, [currentId]);

    VideoFeedItem? byId(String id) =>
        items.value.where((v) => v.id == id).firstOrNull;
    void replace(VideoFeedItem updated) => items.value = [
      for (final v in items.value) v.id == updated.id ? updated : v,
    ];

    Future<void> handleLike(String id) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to like videos',
      )) {
        return;
      }
      final original = byId(id);
      if (original == null) return;
      final optimistic = original.copyWith(
        likedByMe: !original.likedByMe,
        likesCount: original.likedByMe
            ? original.likesCount - 1
            : original.likesCount + 1,
      );
      replace(optimistic);
      try {
        final repo = ref.read(feedRepositoryProvider);
        final likesCount = optimistic.likedByMe
            ? await repo.like(id)
            : await repo.unlike(id);
        if (context.mounted) {
          replace(byId(id)!.copyWith(likesCount: likesCount));
        }
      } catch (_) {
        if (context.mounted) replace(original);
      }
    }

    Future<void> handleSave(String id) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to save videos',
      )) {
        return;
      }
      final original = byId(id);
      if (original == null) return;
      final optimistic = original.copyWith(
        savedByMe: !original.savedByMe,
        savesCount: original.savedByMe
            ? (original.savesCount - 1).clamp(0, original.savesCount)
            : original.savesCount + 1,
      );
      replace(optimistic);
      try {
        final repo = ref.read(feedRepositoryProvider);
        final savesCount = optimistic.savedByMe
            ? await repo.save(id)
            : await repo.unsave(id);
        if (context.mounted) {
          replace(byId(id)!.copyWith(savesCount: savesCount));
        }
      } catch (_) {
        if (context.mounted) replace(original);
      }
    }

    /// Follows (or unfollows) the video's restaurant — on every video of
    /// that restaurant in the list, not just this one.
    Future<void> handleFollow(String id) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow this account',
      )) {
        return;
      }
      final restaurantId = byId(id)?.restaurant?.id;
      if (restaurantId == null) return;

      final before = items.value;
      final follow = !byId(id)!.isFollowingRestaurant;
      items.value = [
        for (final v in before)
          v.restaurant?.id == restaurantId
              ? v.copyWith(isFollowingRestaurant: follow)
              : v,
      ];
      try {
        final social = ref.read(socialRemoteDataSourceProvider);
        if (follow) {
          await social.followRestaurant(restaurantId);
        } else {
          await social.unfollowRestaurant(restaurantId);
        }
      } catch (_) {
        if (context.mounted) items.value = before;
      }
    }

    // The restaurant strip sits above the system gesture area; the other
    // overlays sit above the strip.
    final barBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pages,
            scrollDirection: Axis.vertical,
            itemCount: items.value.length,
            onPageChanged: (i) => index.value = i,
            itemBuilder: (context, i) {
              final item = items.value[i];
              final overlayBottom = barBottom;
              return Stack(
                fit: StackFit.expand,
                children: [
                  FeedVideoPage(
                    item: item,
                    controller: videoManager.controllerFor(item.id),
                    failed: videoManager.hasFailed(item.id),
                    onRetry: () => videoManager.retry(item),
                    onDoubleTapLike: () {
                      if (!item.likedByMe) handleLike(item.id);
                    },
                    onLongPress: () => showVideoOptionsSheet(
                      context,
                      ref,
                      item,
                      controller: videoManager.controllerFor(item.id),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black45],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // The rail sits on top of the info block, so the
                  // restaurant pill can run out to the rail's right edge.
                  Positioned(
                    left: context.sc(14),
                    right: 12,
                    bottom: overlayBottom + context.sc(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FeedActionRail(
                            item: item,
                            onLike: () => handleLike(item.id),
                            onComment: () => showCommentsSheet(
                              context,
                              videoId: item.id,
                              onCountChanged: (delta) {
                                final current = byId(item.id);
                                if (current == null) return;
                                replace(
                                  current.copyWith(
                                    commentsCount:
                                        current.commentsCount + delta,
                                  ),
                                );
                              },
                            ),
                            onSave: () => handleSave(item.id),
                            onShare: () => shareVideo(item),
                            onFollowTap: () => handleFollow(item.id),
                            onAvatarTap: () {},
                          ),
                        ),
                        SizedBox(height: context.sc(14)),
                        FeedInfoOverlay(
                          item: item,
                          onUserTap: () {},
                          restaurant: item.restaurant == null
                              ? null
                              : FeedRestaurantBar(
                                  item: item,
                                  onFollowTap: () => handleFollow(item.id),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Back stays put while the videos move under it.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
