// lib/features/feed/presentation/widgets/feed_info_overlay.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/rating/rating_badge.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import '../../domain/video_feed_item.dart';
import '../../providers/feed_restaurant_provider.dart';

const _ink = Color(0xff1F1B3A);
const _plum = Color(0xff3A3350);
const _shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

/// Bottom-left overlay:
///   1. Reviewer byline ("@username · time").
///   2. The expandable caption (its own #hashtags stay tappable).
/// The video's restaurant gets its own strip underneath: see
/// [FeedRestaurantBar].
class FeedInfoOverlay extends StatelessWidget {
  final VideoFeedItem item;
  final VoidCallback onUserTap;
  final ValueChanged<String>? onHashtagTap;

  const FeedInfoOverlay({
    required this.item,
    required this.onUserTap,
    this.onHashtagTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = item.createdAt;

    // Fades + rises in on every new video (re-triggers because the key
    // changes), so the overlay feels alive as you swipe instead of just
    // appearing — small touch, but it's what makes the feed feel premium
    // rather than static.
    return TweenAnimationBuilder<double>(
      key: ValueKey(item.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Reviewer byline — just "@username · time", no avatar (the
          // avatar moved onto the action rail on the right).
          GestureDetector(
            onTap: onUserTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '@${item.user.username}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      letterSpacing: -0.1,
                      shadows: _shadow,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (createdAt != null) ...[
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  Text(
                    timeAgo(createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      shadows: _shadow,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (item.caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ExpandableCaption(
              key: ValueKey(item.id),
              text: item.caption,
              onHashtagTap:
                  onHashtagTap ??
                  (tag) => AppService.showToast('#$tag search is coming soon'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-width frosted strip along the bottom of a video for its restaurant:
/// the shop icon in a gradient ring, name over rating · category, and a
/// Follow pill. Tapping
/// anywhere but the pill opens the restaurant.
class FeedRestaurantBar extends ConsumerWidget {
  final VideoFeedItem item;
  final VoidCallback onFollowTap;
  final VoidCallback? onTap;

  const FeedRestaurantBar({
    required this.item,
    required this.onFollowTap,
    this.onTap,
    super.key,
  });

  static const double height = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = item.restaurant!;
    // The feed item only has the restaurant's name; its average rating and
    // category arrive a moment later from the restaurant's own record.
    // Until then (or if that fails) a review shows the review's rating.
    final details = ref.watch(feedRestaurantProvider(restaurant.id)).value;
    final rating = details?.avgRating ?? item.rating;
    final category = details?.category?.name ?? restaurant.categoryName;
    const meta = TextStyle(
      color: Colors.white,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // Frosted: the video shows through, blurred, under a dark plum tint.
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: _plum.withValues(alpha: 0.45),
            child: Row(
              children: [
                const _RestaurantIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (rating != null || category != null) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            if (rating != null)
                              RatingBadge(
                                rating: rating,
                                iconSize: 13,
                                style: meta.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            if (rating != null && category != null)
                              const Text('  ·  ', style: meta),
                            if (category != null)
                              Flexible(
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: meta,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _FollowChip(
                  following: item.isFollowingRestaurant,
                  onTap: onFollowTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shop icon in white on a dark plum disc, inside a ring of the pale
/// pink → blue brand wash (the same wash as the Follow pill).
class _RestaurantIcon extends StatelessWidget {
  const _RestaurantIcon();

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.backgroundGradientLR,
      ),
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _plum),
        child: Image.asset(
          AssetsName.shop,
          width: 16,
          height: 16,
          color: Colors.white,
          // A 512px PNG; decode it at its on-screen size.
          cacheWidth: (16 * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
  }
}

/// "+ Follow" on the pale pink → blue brand wash; a quiet outlined
/// "✓ Following" once followed.
class _FollowChip extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;
  const _FollowChip({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = following ? Colors.white : _ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
        decoration: BoxDecoration(
          gradient: following ? null : AppColors.backgroundGradientLR,
          color: following ? Colors.white.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(20),
          border: following
              ? Border.all(color: Colors.white.withValues(alpha: 0.6))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 3),
            Text(
              following ? 'Following' : 'Follow',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caption clamped to 2 lines with an animated "more / less" toggle when it
/// overflows. #hashtags are picked out in a bright accent and tappable.
class _ExpandableCaption extends StatefulWidget {
  final String text;
  final ValueChanged<String> onHashtagTap;
  const _ExpandableCaption({
    required this.text,
    required this.onHashtagTap,
    super.key,
  });

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  static const _base = TextStyle(
    color: Colors.white,
    fontSize: 13.5,
    height: 1.35,
    shadows: _shadow,
  );
  static final _hashtag = RegExp(r'#[^\s#]+');

  bool _expanded = false;
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TextSpan _buildSpan() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _hashtag.allMatches(widget.text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      }
      final tag = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onHashtagTap(tag.substring(1));
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: tag,
          recognizer: recognizer,
          style: const TextStyle(
            color: Color(0xffFF6DB8),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      last = m.end;
    }
    if (last < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(last)));
    }
    return TextSpan(style: _base, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = _buildSpan();
        final painter = TextPainter(
          text: span,
          maxLines: 2,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: overflows
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Keep a long caption from swallowing the whole video.
                maxHeight: _expanded ? 180 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: _expanded
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: _base,
                        children: [
                          ...span.children!,
                          // Collapsed text ends in an ellipsis, so the toggle
                          // only goes inline once everything is showing.
                          if (overflows && _expanded)
                            const TextSpan(
                              text: '  less',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      maxLines: _expanded ? null : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (overflows && !_expanded)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'more',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: _shadow,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
