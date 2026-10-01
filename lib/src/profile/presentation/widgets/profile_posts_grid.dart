import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/components/profile/video_grid_tile.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/profile/domain/profile_post.dart';
import 'package:khmer_cat_app/src/profile/presentation/viewmodel/my_profile_summary_controller.dart';
import 'package:khmer_cat_app/src/profile/providers/profile_providers.dart';

/// 3-column grid backing the profile's Videos / Favorite / Delete tabs.
/// [flag] selects which list GET /profile/{userId}/posts returns: `null` for
/// the user's own posts, `'favorite'`, or `'deleted'`. Loads page by page via
/// a sentinel under the grid, same shape as [RestaurantVideosGrid].
class ProfilePostsGrid extends HookConsumerWidget {
  final String userId;
  final String? flag;
  final String emptyAsset;
  final String emptyMessage;

  const ProfilePostsGrid({
    required this.userId,
    required this.flag,
    required this.emptyAsset,
    required this.emptyMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = useState<List<ProfilePost>>([]);
    final nextPage = useState<int?>(1);
    final hasMore = useState(true);
    final loading = useState(false);
    final failed = useState(false);
    final firstLoadDone = useState(false);

    Future<void> loadMore({bool reset = false}) async {
      if (!reset && (loading.value || !hasMore.value)) return;
      loading.value = true;
      failed.value = false;
      try {
        final result = await ref
            .read(profileRepositoryProvider)
            .getPosts(userId, flag: flag, page: reset ? 1 : nextPage.value!);
        if (!context.mounted) return;
        items.value = reset ? result.items : [...items.value, ...result.items];
        nextPage.value = result.nextPage;
        hasMore.value = result.hasMore;
      } catch (_) {
        if (context.mounted) failed.value = true;
      } finally {
        if (context.mounted) {
          loading.value = false;
          firstLoadDone.value = true;
        }
      }
    }

    useEffect(() {
      firstLoadDone.value = false;
      Future.microtask(() => loadMore(reset: true));
      return null;
    }, [userId, flag]);

    Future<void> handleToggleFavorite(ProfilePost post) async {
      final previous = items.value;
      items.value = items.value
          .map(
            (p) => p.id == post.id ? p.copyWith(isFavorite: !p.isFavorite) : p,
          )
          .toList();
      try {
        final updated = await ref
            .read(profileRepositoryProvider)
            .toggleFavorite(userId, post.id);
        // The Favorite tab should only ever show favorited posts.
        items.value = flag == 'favorite' && !updated.isFavorite
            ? items.value.where((p) => p.id != post.id).toList()
            : items.value.map((p) => p.id == updated.id ? updated : p).toList();
      } catch (_) {
        if (!context.mounted) return;
        items.value = previous;
        AppService.showToast('Failed to update favorite.', isError: true);
      }
    }

    Future<void> handleDelete(ProfilePost post) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete video?'),
          content: const Text(
            'It will be moved to Delete for 30 days, then removed permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final previous = items.value;
      items.value = items.value.where((p) => p.id != post.id).toList();
      try {
        await ref.read(profileRepositoryProvider).deletePost(userId, post.id);
        ref
            .read(myProfileSummaryControllerProvider(userId).notifier)
            .decrementPostsCount();
        if (context.mounted) AppService.showToast('Video deleted.');
      } catch (_) {
        if (!context.mounted) return;
        items.value = previous;
        AppService.showToast('Failed to delete video.', isError: true);
      }
    }

    if (!firstLoadDone.value) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: VideoGridSkeleton(),
      );
    }

    if (items.value.isEmpty) {
      if (failed.value) {
        return _RetryBox(onRetry: () => loadMore(reset: true));
      }
      return ProfileEmptyTabBody(asset: emptyAsset, message: emptyMessage);
    }

    return Column(
      children: [
        const Gap(16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: VideoGrid.delegate,
            itemCount: items.value.length,
            itemBuilder: (context, index) {
              final post = items.value[index];
              final trashed = flag == 'deleted';
              return VideoGridTile(
                // Stagger only within a page's worth of tiles.
                fadeDelayMs: (index % 12) * 40,
                thumbnailUrl: post.thumbnailUrl,
                likesCount: post.likesCount,
                rating: post.rating,
                isFavorite: post.isFavorite,
                trashed: trashed,
                onTap: trashed
                    ? null
                    : () => AppRouter.router.pushNamed(
                        AppRoute.videoViewer.name,
                        pathParameters: {'id': post.id},
                        extra: post.toVideoFeedItem(),
                      ),
                onLongPress: trashed
                    ? null
                    : () => showVideoTileActions(context, [
                        VideoTileAction(
                          icon: post.isFavorite
                              ? Icons.heart_broken_rounded
                              : Icons.favorite_border_rounded,
                          label: post.isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          onTap: () => handleToggleFavorite(post),
                        ),
                        if (flag == null)
                          VideoTileAction(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            destructive: true,
                            onTap: () => handleDelete(post),
                          ),
                      ]),
              );
            },
          ),
        ),
        if (failed.value)
          _RetryBox(onRetry: () => loadMore())
        else if (hasMore.value)
          _LoadMoreSentinel(
            key: ValueKey(items.value.length),
            onVisible: loadMore,
          )
        else
          const Gap(20),
      ],
    );
  }
}

class _LoadMoreSentinel extends StatefulWidget {
  final VoidCallback onVisible;
  const _LoadMoreSentinel({required this.onVisible, super.key});

  @override
  State<_LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<_LoadMoreSentinel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: ProfileTheme.purple,
        ),
      ),
    );
  }
}

class _RetryBox extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryBox({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Text(
            'Couldn\'t load videos.',
            style: TextStyle(color: ProfileTheme.muted),
          ),
          const Gap(8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: ProfileTheme.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
