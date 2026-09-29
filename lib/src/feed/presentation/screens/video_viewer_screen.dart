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

/// Single-video playback for entry points outside the swipeable feed (e.g.
/// tapping a thumbnail in a restaurant's video grid) — no pagination, same
/// like/comment actions as the main feed.
class VideoViewerScreen extends HookConsumerWidget {
  final VideoFeedItem video;
  const VideoViewerScreen({required this.video, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = useState(video);
    final videoManager = useMemoized(() => VideoControllerManager());
    useEffect(() => videoManager.dispose, [videoManager]);
    useListenable(videoManager);
    useEffect(() {
      videoManager.syncWindow([item.value], 0, tabIsVisible: true);
      return null;
    }, [item.value]);
    useEffect(() {
      ref.read(feedRepositoryProvider).recordView(video.id);
      return null;
    }, [video.id]);

    Future<void> handleLike() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to like videos',
      )) {
        return;
      }
      final original = item.value;
      final optimistic = original.copyWith(
        likedByMe: !original.likedByMe,
        likesCount: original.likedByMe
            ? original.likesCount - 1
            : original.likesCount + 1,
      );
      item.value = optimistic;
      try {
        final repo = ref.read(feedRepositoryProvider);
        final likesCount = optimistic.likedByMe
            ? await repo.like(original.id)
            : await repo.unlike(original.id);
        item.value = item.value.copyWith(likesCount: likesCount);
      } catch (_) {
        if (context.mounted) item.value = original;
      }
    }

    Future<void> handleSave() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to save videos',
      )) {
        return;
      }
      final original = item.value;
      final optimistic = original.copyWith(savedByMe: !original.savedByMe);
      item.value = optimistic;
      try {
        final repo = ref.read(feedRepositoryProvider);
        if (optimistic.savedByMe) {
          await repo.save(original.id);
        } else {
          await repo.unsave(original.id);
        }
      } catch (_) {
        if (context.mounted) item.value = original;
      }
    }

    Future<void> handleFollow() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow this account',
      )) {
        return;
      }
      final restaurantId = item.value.restaurant?.id;
      if (restaurantId == null) return;

      final original = item.value;
      final wasFollowing = original.isFollowingRestaurant;
      item.value = original.copyWith(isFollowingRestaurant: !wasFollowing);
      try {
        final social = ref.read(socialRemoteDataSourceProvider);
        if (wasFollowing) {
          await social.unfollowRestaurant(restaurantId);
        } else {
          await social.followRestaurant(restaurantId);
        }
      } catch (_) {
        if (context.mounted) item.value = original;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FeedVideoPage(
            item: item.value,
            controller: videoManager.controllerFor(item.value.id),
            failed: videoManager.hasFailed(item.value.id),
            onRetry: () => videoManager.retry(item.value),
            onDoubleTapLike: () {
              if (!item.value.likedByMe) handleLike();
            },
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
          Positioned(
            right: 12,
            bottom: context.sc(50),
            child: FeedActionRail(
              item: item.value,
              onLike: handleLike,
              onComment: () => showCommentsSheet(
                context,
                videoId: item.value.id,
                onCountChanged: (delta) => item.value = item.value.copyWith(
                  commentsCount: item.value.commentsCount + delta,
                ),
              ),
              onSave: handleSave,
              onShare: () => shareVideo(item.value),
              onFollowTap: handleFollow,
              onAvatarTap: () {},
            ),
          ),
          Positioned(
            left: context.sc(14),
            right: 90,
            bottom: context.sc(14),
            child: FeedInfoOverlay(
              item: item.value,
              onFollowTap: handleFollow,
              onUserTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
