import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
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

    if (!firstLoadDone.value) return const _GridSkeleton();

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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 9 / 16,
            ),
            itemCount: items.value.length,
            itemBuilder: (context, index) => _ProfilePostThumb(
              post: items.value[index],
              flag: flag,
              onToggleFavorite: () => handleToggleFavorite(items.value[index]),
              onDelete: () => handleDelete(items.value[index]),
            ),
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

class _ProfilePostThumb extends StatelessWidget {
  final ProfilePost post;
  final String? flag;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const _ProfilePostThumb({
    required this.post,
    required this.flag,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  bool get _isTrashed => flag == 'deleted';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isTrashed
          ? null
          : () => AppRouter.router.pushNamed(
              AppRoute.videoViewer.name,
              pathParameters: {'id': post.id},
              extra: post.toVideoFeedItem(),
            ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: ProfileTheme.cardShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: post.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ThumbPlaceholder(),
                  errorWidget: (_, _, _) => const _ThumbPlaceholder(play: true),
                )
              else
                const _ThumbPlaceholder(play: true),
              if (_isTrashed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const Gap(4),
                    Text(
                      formatCount(post.likesCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.rating != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xffFFB800),
                      ),
                      const Gap(2),
                      Text(
                        '${post.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isTrashed)
                const Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                )
              else ...[
                Positioned(
                  right: 6,
                  top: 6,
                  child: _RoundIconButton(
                    icon: post.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.isFavorite ? ProfileTheme.pink : Colors.white,
                    onTap: onToggleFavorite,
                  ),
                ),
                if (flag == null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _RoundIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.white,
                      onTap: onDelete,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
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

class _ThumbPlaceholder extends StatelessWidget {
  final bool play;
  const _ThumbPlaceholder({this.play = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ProfileTheme.coverFallback),
      child: play
          ? const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 30,
              ),
            )
          : null,
    );
  }
}

class _GridSkeleton extends HookWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final t = useAnimation(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    final color = ProfileTheme.purple.withValues(alpha: 0.07 + 0.08 * t);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 9 / 16,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
