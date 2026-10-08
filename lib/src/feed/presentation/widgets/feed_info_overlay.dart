// lib/features/feed/presentation/widgets/feed_info_overlay.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import '../../domain/video_feed_item.dart';

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

/// Bottom-left overlay:
///   1. Reviewer byline — small and muted ("@username · time").
///   2. The expandable caption (its own #hashtags stay tappable).
///   3. One restaurant row — icon, name, rating star and a Follow chip —
///      only shown when the video has a restaurant.
class FeedInfoOverlay extends StatelessWidget {
  final VideoFeedItem item;
  final VoidCallback onFollowTap;
  final VoidCallback onUserTap;
  final VoidCallback? onRestaurantTap;
  final ValueChanged<String>? onHashtagTap;

  const FeedInfoOverlay({
    required this.item,
    required this.onFollowTap,
    required this.onUserTap,
    this.onRestaurantTap,
    this.onHashtagTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final restaurant = item.restaurant;
    final rating = item.rating;
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.1,
                      shadows: _shadow,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (createdAt != null) ...[
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    timeAgo(createdAt),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
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

          // 2. Restaurant row — icon, name, rating star and Follow on one
          // line, last in the column so it sits right above the tab bar.
          if (restaurant != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRestaurantTap,
                    child: Row(
                      children: [
                        const _RestaurantIcon(),
                        const SizedBox(width: 8),
                        // Name with the rating under it.
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                restaurant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  letterSpacing: -0.2,
                                  shadows: _shadow,
                                ),
                              ),
                              // TODO(backend): this is the review's own
                              // rating; the feed's `restaurant` object has no
                              // average rating yet (send `avg_rating` there
                              // to show that instead).
                              if (rating != null) ...[
                                const SizedBox(height: 1),
                                _RatingStar(rating: rating),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FollowChip(
                  following: item.isFollowingRestaurant,
                  onTap: onFollowTap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Storefront icon in a soft glass circle — marks the row as a restaurant.
class _RestaurantIcon extends StatelessWidget {
  const _RestaurantIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: const Icon(
        Icons.storefront_outlined,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}

/// "★ 4.0"
class _RatingStar extends StatelessWidget {
  final double rating;
  const _RatingStar({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: Color(0xffFFC83D)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            shadows: _shadow,
          ),
        ),
      ],
    );
  }
}

class _FollowChip extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;
  const _FollowChip({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: following
              ? null
              : const LinearGradient(colors: [_pink, _purple]),
          color: following ? Colors.black.withValues(alpha: 0.25) : null,
          borderRadius: BorderRadius.circular(20),
          border: following
              ? Border.all(color: Colors.white.withValues(alpha: 0.7))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              following ? 'Following' : 'Follow',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
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
            color: Color(0xffB9A2FF),
            fontWeight: FontWeight.w700,
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
