import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/data/restaurant_profile_mock.dart';

const _star = Color(0xffF5B400);

/// The "Review wall" tab: rating summary with a 5→1 breakdown, a
/// "Write a review" button and the written reviews, newest first.
class RestaurantReviewWall extends StatelessWidget {
  final ReviewSummary summary;
  final List<WallReview> reviews;
  final VoidCallback onWrite;
  const RestaurantReviewWall({
    required this.summary,
    required this.reviews,
    required this.onWrite,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final line = ProfileTheme.hairlineColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(summary: summary),
          const Gap(18),
          _WriteButton(onTap: onWrite),
          const Gap(8),
          for (final (i, r) in reviews.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: line),
            _ReviewTile(review: r),
          ],
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const StarRow({required this.rating, this.size = 14, super.key});

  @override
  Widget build(BuildContext context) {
    final off = ProfileTheme.textSecondary(context).withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i <= rating ? _star : off,
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final ReviewSummary summary;
  const _Summary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final total = summary.total;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 108,
          child: Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 42,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(4),
              StarRow(rating: summary.average.round(), size: 15),
              const Gap(4),
              Text(
                '$total ${total == 1 ? 'review' : 'reviews'}',
                style: TextStyle(fontSize: 13.5, color: muted),
              ),
            ],
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                _BarRow(
                  star: star,
                  count: summary.counts[star] ?? 0,
                  max: summary.maxCount,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final int star;
  final int count;
  final int max;
  const _BarRow({required this.star, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final primary = ProfileTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$star',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  Container(height: 6, color: muted.withValues(alpha: 0.14)),
                  FractionallySizedBox(
                    widthFactor: max == 0 ? 0 : count / max,
                    child: Container(height: 6, color: _star),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          SizedBox(
            width: 14,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WriteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xffF5A6CF), Color(0xffA9C1F5)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 18, color: ProfileTheme.ink),
            Gap(8),
            Text(
              'Write a review',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final WallReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final r = review;
    final primary = ProfileTheme.textPrimary(context);
    final initial = r.name.isEmpty
        ? '?'
        : r.name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffF0B6D8), Color(0xffA9C1F5)],
              ),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.ink,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo(r.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const Gap(3),
                StarRow(rating: r.rating),
                const Gap(8),
                Text(
                  r.comment,
                  style: TextStyle(fontSize: 14.5, height: 1.4, color: primary),
                ),
                if (r.hasMedia) ...[
                  const Gap(12),
                  _Media(url: r.mediaThumbnailUrl),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Media extends StatelessWidget {
  final String? url;
  const _Media({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 88,
        height: 88,
        child: url == null
            ? const DecoratedBox(
                decoration: BoxDecoration(gradient: ProfileTheme.coverFallback),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white),
              )
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}
