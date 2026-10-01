import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

/// The one look for every profile video grid (personal and restaurant):
/// 3 columns, rounded tiles, a play badge in the middle and the like count
/// bottom-left. Actions on your own videos live in a long-press sheet
/// ([showVideoTileActions]) instead of buttons on every tile.
abstract final class VideoGrid {
  static const delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.78,
  );

  static const double radius = 14;
}

class VideoGridTile extends StatelessWidget {
  final String? thumbnailUrl;
  final int likesCount;

  /// A review's star rating, shown bottom-right.
  final num? rating;

  /// Small pink heart top-right when it's in the viewer's favorites.
  final bool isFavorite;

  /// In a Delete tab: dimmed, with a trash icon instead of the play badge.
  final bool trashed;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Stagger for the fade-in, so a page of tiles appears in sequence.
  final int fadeDelayMs;

  const VideoGridTile({
    required this.thumbnailUrl,
    required this.likesCount,
    this.rating,
    this.isFavorite = false,
    this.trashed = false,
    this.onTap,
    this.onLongPress,
    this.fadeDelayMs = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl;
    return _FadeIn(
      delayMs: fadeDelayMs,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VideoGrid.radius),
            boxShadow: ProfileTheme.cardShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VideoGrid.radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumb != null)
                  CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _ThumbPlaceholder(),
                    errorWidget: (_, _, _) => const _ThumbPlaceholder(),
                  )
                else
                  const _ThumbPlaceholder(),
                if (trashed)
                  ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                // Bottom scrim so the counts stay readable.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x8C000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: _Stat(
                    icon: Icons.favorite_rounded,
                    text: formatCount(likesCount),
                  ),
                ),
                if (rating != null)
                  Positioned(
                    right: 8,
                    bottom: 6,
                    child: _Stat(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xffFFC83D),
                      text: '$rating',
                    ),
                  ),
                if (isFavorite && !trashed)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: ProfileTheme.pink,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                    ),
                  ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trashed
                          ? Icons.delete_outline_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing placeholder tiles while a grid's first page loads.
class VideoGridSkeleton extends HookWidget {
  const VideoGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      ctrl.repeat(reverse: true);
      return null;
    }, [ctrl]);
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
        gridDelegate: VideoGrid.delegate,
        itemCount: 6,
        itemBuilder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(VideoGrid.radius),
          ),
        ),
      ),
    );
  }
}

/// One row in the long-press sheet.
class VideoTileAction {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;
  const VideoTileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
}

/// TikTok-style sheet of actions for one of your own videos, opened by a
/// long press on its tile.
Future<void> showVideoTileActions(
  BuildContext context,
  List<VideoTileAction> actions,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  action.icon,
                  color: action.destructive
                      ? const Color(0xffE5484D)
                      : ProfileTheme.textPrimary(sheetContext),
                ),
                title: Text(
                  action.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: action.destructive
                        ? const Color(0xffE5484D)
                        : ProfileTheme.textPrimary(sheetContext),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  action.onTap();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _Stat({
    required this.icon,
    required this.text,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const Gap(4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: ProfileTheme.coverFallback),
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
