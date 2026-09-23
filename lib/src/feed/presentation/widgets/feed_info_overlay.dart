// lib/features/feed/presentation/widgets/feed_info_overlay.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import '../../domain/video_feed_item.dart';

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _blue = Color(0xff74BFFF);
const _shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

/// Bottom-left overlay: restaurant/creator (gradient-ringed avatar, name,
/// follow chip), optional rating + posted-time chips, and an expandable
/// caption whose #hashtags are tappable.
class FeedInfoOverlay extends StatelessWidget {
  final VideoFeedItem item;
  final VoidCallback onFollowTap;
  final VoidCallback onProfileTap;
  final ValueChanged<String>? onHashtagTap;

  const FeedInfoOverlay({
    required this.item,
    required this.onFollowTap,
    required this.onProfileTap,
    this.onHashtagTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        item.restaurant?.profilePicture ?? item.user.profilePicture;
    final displayName = item.restaurant != null
        ? item.restaurant!.name
        : '@${item.user.username}';
    final rating = item.rating;
    final createdAt = item.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
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
                    imageUrl: avatarUrl,
                    name: displayName,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: GestureDetector(
                onTap: onProfileTap,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    shadows: _shadow,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _FollowChip(following: item.followingLocally, onTap: onFollowTap),
          ],
        ),
        if (rating != null || createdAt != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (rating != null) _RatingChip(rating: rating),
              if (createdAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo(createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: _shadow,
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
          boxShadow: following
              ? null
              : [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
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

/// Five stars (filled to the rating, halves supported) + the number.
class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating.clamp(0, 5).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              r >= i
                  ? Icons.star_rounded
                  : r >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: 15,
              color: const Color(0xffFFC83D),
            ),
          const SizedBox(width: 5),
          Text(
            r.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
