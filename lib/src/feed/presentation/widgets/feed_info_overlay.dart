// lib/features/feed/presentation/widgets/feed_info_overlay.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import '../../domain/video_feed_item.dart';

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _blue = Color(0xff74BFFF);
const _shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

/// Bottom-left overlay, split into two visually distinct identities so it's
/// never ambiguous who posted vs. which restaurant it's about:
///   1. Reviewer byline — small, muted, transparent background (avatar,
///      @username, posted-time with a clock icon).
///   2. Restaurant card — a divider below the byline, then a translucent
///      card with a bigger avatar, bold name, star rating, and the follow
///      chip, only shown when the video has a restaurant.
/// Below both: the expandable caption (its own #hashtags stay tappable).
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

          // 2. Rating pill — only shown on review videos that actually
          // carry a rating; the "recommended" label is derived from that
          // real value, not a fixed string.
          if (rating != null) ...[
            const SizedBox(height: 8),
            _RatingPill(rating: rating),
          ],

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

          // 3. Restaurant card — which restaurant this review is about.
          // A flat dark-glass card, last in the column so it sits right
          // above the tab bar / safe area, matching the reference design.
          if (restaurant != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: context.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onRestaurantTap,
                      child: Row(
                        children: [
                          _RingedAvatar(
                            imageUrl: restaurant.profilePicture,
                            name: restaurant.name,
                            size: context.sc(40),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                    shadows: _shadow,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // TODO(backend): the feed API's `restaurant`
                                // object only sends id/name/profile_picture
                                // today — address isn't in the response, so
                                // this is a static placeholder until it is.
                                const Text(
                                  'Street 271, Boeng Tumpun ...',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                // TODO(backend): same as above — category and
                                // the restaurant's aggregate rating/review
                                // count aren't in the feed response yet.
                                const Text(
                                  'Khmer Fusion  ·  ★ 4.0 (128)',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FollowChip(
                    following: item.isFollowingRestaurant,
                    onTap: onFollowTap,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "★ 4.8 / 5 · Highly Recommended" — the label is derived from the real
/// rating value (not a fixed string), so it stays honest even though the
/// surrounding restaurant card below has placeholder fields.
class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  String get _label {
    if (rating >= 4.5) return 'Highly Recommended';
    if (rating >= 3.5) return 'Recommended';
    return 'Reviewed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xffFFC83D)),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} / 5',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            '  ·  ',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small gradient-ringed circular avatar shared by the reviewer and
/// restaurant rows (restaurant's ring renders thinner/smaller since it's
/// the secondary identity of the two).
class _RingedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  const _RingedAvatar({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink, _purple, _blue],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ImageUserCircleProfile(
          imageUrl: imageUrl,
          name: name,
          size: size,
        ),
      ),
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
