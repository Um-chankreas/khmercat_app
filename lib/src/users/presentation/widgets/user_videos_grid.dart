import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
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

  const UserVideosGrid({
    required this.userId,
    this.emptyTitle = 'No videos yet',
    this.emptyMessage = 'No videos yet.',
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: items.value.length,
            itemBuilder: (context, index) => _FadeIn(
              // Stagger only within a page's worth of tiles.
              delayMs: (index % 12) * 40,
              child: _VideoThumb(video: items.value[index]),
            ),
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

class _FadeIn extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _FadeIn({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 320 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
      child: child,
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final VideoFeedItem video;
  const _VideoThumb({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRouter.router.pushNamed(
        AppRoute.videoViewer.name,
        pathParameters: {'id': video.id},
        extra: video,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: ProfileTheme.cardShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ThumbPlaceholder(),
                  errorWidget: (_, _, _) => const _ThumbPlaceholder(play: true),
                )
              else
                const _ThumbPlaceholder(play: true),
              // Bottom scrim so the like count stays readable.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
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
                left: 8,
                bottom: 6,
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const Gap(4),
                    Text(
                      '${video.likesCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
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
