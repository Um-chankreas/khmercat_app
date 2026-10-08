import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/components/profile/video_grid_tile.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';

/// 3-column grid of a user's own posted videos — the user-profile mirror of
/// [RestaurantVideosGrid]. Loads page by page: a small sentinel under the
/// grid asks for the next page as it scrolls into view, so it works inside
/// a parent ListView.
class UserVideosGrid extends HookConsumerWidget {
  final String userId;
  final String emptyTitle;
  final String emptyMessage;

  /// `review` for the review videos only; null for all posts.
  final String? type;

  const UserVideosGrid({
    required this.userId,
    this.emptyTitle = 'No videos yet',
    this.emptyMessage = 'No videos yet.',
    this.type,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = useState<List<VideoFeedItem>>([]);
    final cursor = useState<String?>(null);
    final hasMore = useState(true);
    final loading = useState(false);
    final failed = useState(false);
    final firstLoadDone = useState(false);

    Future<void> loadMore({bool reset = false}) async {
      if (!reset && (loading.value || !hasMore.value)) return;
      loading.value = true;
      failed.value = false;
      try {
        final page = await ref
            .read(feedRepositoryProvider)
            .getFeed(
              tab: 'for_you',
              cursor: reset ? null : cursor.value,
              userId: userId,
              type: type,
            );
        if (!context.mounted) return;
        items.value = reset ? page.items : [...items.value, ...page.items];
        cursor.value = page.nextCursor;
        hasMore.value = page.hasMore && page.nextCursor != null;
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
    }, [userId]);

    if (!firstLoadDone.value) return const _GridSkeleton();

    if (items.value.isEmpty) {
      if (failed.value) {
        return _RetryBox(onRetry: () => loadMore(reset: true));
      }
      return ProfileEmptyTabBody(
        asset: AssetsName.feeds,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: VideoGrid.delegate,
            itemCount: items.value.length,
            itemBuilder: (context, index) {
              final video = items.value[index];
              return VideoGridTile(
                // Stagger only within a page's worth of tiles.
                fadeDelayMs: (index % 12) * 40,
                thumbnailUrl: video.thumbnailUrl,
                likesCount: video.likesCount,
                pillLabel:
                    '${formatCount(video.likesCount)} '
                    'like${video.likesCount == 1 ? '' : 's'}',
                onTap: () => AppRouter.router.pushNamed(
                  AppRoute.videoViewer.name,
                  pathParameters: {'id': video.id},
                  extra: video,
                ),
              );
            },
          ),
        ),
        if (failed.value)
          _RetryBox(onRetry: () => loadMore())
        else if (hasMore.value)
          // New key per page so the sentinel re-fires after each load.
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
