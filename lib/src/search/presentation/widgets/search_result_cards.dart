import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';

// Cards for the search results screen: nearby restaurant rows, recommended
// restaurant tiles, food review video cards and popular reviewer rows.

const _star = Color(0xffFFB020);
const _openGreen = Color(0xff22C55E);
const _closedRed = Color(0xffEF4444);

/// "800m away" / "1.2 km away".
String formatAway(double km) => km < 1
    ? '${(km * 1000).round()}m away'
    : '${km.toStringAsFixed(1)} km away';

/// "1.5 km" / "800 m" — the compact form used on recommended tiles.
String formatKm(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

/// "18.4K" style counts.
String formatViews(int n) => formatCount(n).toUpperCase();

/// First part of an address ("Street 271, Phnom Penh" -> "Street 271").
String? shortAddress(String? address) {
  final first = address?.split(',').first.trim();
  return first == null || first.isEmpty ? null : first;
}

// =============================================================================
// Section header
// =============================================================================

/// Emoji + UPPERCASE title, with an optional pink action ("See all (12)") or
/// a quiet trailing label ("Sponsored").
class SearchSectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final String? trailingLabel;

  const SearchSectionHeader({
    required this.emoji,
    required this.title,
    this.actionText,
    this.onAction,
    this.trailingLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const Gap(6),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
          ),
          if (actionText != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.pink,
                  ),
                ),
              ),
            )
          else if (trailingLabel != null)
            Text(
              trailingLabel!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared bits
// =============================================================================

/// Bordered surface card with an ink ripple.
class _TapCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ProfileTheme.hairlineColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
        highlightColor: ProfileTheme.purple.withValues(alpha: 0.04),
        child: child,
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool open;
  const _OpenBadge({required this.open});

  @override
  Widget build(BuildContext context) {
    final color = open ? _openGreen : _closedRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        open ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Small dark pill laid over an image (service type, rating, duration).
class _OverlayPill extends StatelessWidget {
  final Widget child;
  const _OverlayPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        child: child,
      ),
    );
  }
}

Widget _dot(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: Text(
    '•',
    style: TextStyle(fontSize: 11, color: ProfileTheme.textSecondary(context)),
  ),
);

// =============================================================================
// Nearby restaurant row
// =============================================================================

class NearbyRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onOpened;
  const NearbyRestaurantCard({
    required this.restaurant,
    this.onOpened,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final muted = ProfileTheme.textSecondary(context);
    final subtitle = [
      r.category?.name,
      shortAddress(r.address),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' • ');

    final meta = <Widget>[
      if (r.avgRating != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 15, color: _star),
            const Gap(2),
            Text(
              r.avgRating!.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      if (r.distanceKm != null)
        Text(
          formatAway(r.distanceKm!),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ProfileTheme.pink,
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TapCard(
        onTap: () {
          onOpened?.call();
          openRestaurant(r.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: NetImage(url: r.profilePicture),
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: ProfileTheme.textPrimary(context),
                            ),
                          ),
                        ),
                        if (r.isOpen != null) ...[
                          const Gap(8),
                          _OpenBadge(open: r.isOpen!),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const Gap(3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const Gap(5),
                      Row(
                        children: [
                          for (var i = 0; i < meta.length; i++) ...[
                            if (i > 0) _dot(context),
                            meta[i],
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ProfileTheme.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Recommended restaurant tile
// =============================================================================

class RecommendedRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onOpened;

  /// Fixed width for the horizontal carousel; null fills the parent (grid).
  final double? width;
  const RecommendedRestaurantCard({
    required this.restaurant,
    this.onOpened,
    this.width = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final muted = ProfileTheme.textSecondary(context);
    // Price level and delivery time are no longer shown; the review count
    // takes their spot next to the distance.
    final details = r.reviewsCount > 0
        ? '${r.reviewsCount} review${r.reviewsCount == 1 ? '' : 's'}'
        : '';

    return SizedBox(
      width: width,
      child: _TapCard(
        onTap: () {
          onOpened?.call();
          openRestaurant(r.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: r.coverPicture ?? r.profilePicture),
                  if (r.serviceTypeLabel != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _OverlayPill(child: Text(r.serviceTypeLabel!)),
                    ),
                  if (r.avgRating != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _OverlayPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: _star,
                            ),
                            const Gap(2),
                            Text(r.avgRating!.toStringAsFixed(1)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    r.category?.name ?? r.description ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                      if (r.distanceKm != null)
                        Text(
                          formatKm(r.distanceKm!),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ProfileTheme.purple,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Food review video card
// =============================================================================

class VideoReviewCard extends StatelessWidget {
  final VideoFeedItem video;
  final VoidCallback? onOpened;
  const VideoReviewCard({required this.video, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final title = video.caption.trim().isNotEmpty
        ? video.caption.trim()
        : (video.restaurant?.name ?? 'Food review');

    return _TapCard(
      onTap: () {
        onOpened?.call();
        AppRouter.router.pushNamed(
          AppRoute.videoViewer.name,
          pathParameters: {'id': video.id},
          extra: video,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(
                  url: video.thumbnailUrl,
                  fallback: Icons.play_circle_outline_rounded,
                ),
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                if (video.durationText != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _OverlayPill(child: Text(video.durationText!)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
                const Gap(3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '@${video.user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                    ),
                    Text(
                      '${formatViews(video.viewsCount)} views',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid of [VideoReviewCard]s.
class VideoReviewGrid extends StatelessWidget {
  final List<VideoFeedItem> videos;
  final VoidCallback? onOpened;
  const VideoReviewGrid({required this.videos, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) =>
          VideoReviewCard(video: videos[i], onOpened: onOpened),
    );
  }
}

// =============================================================================
// Popular reviewers
// =============================================================================

/// Reviewer rows grouped in one bordered card, separated by hairlines.
class ReviewerList extends StatelessWidget {
  final List<PublicProfile> users;
  final ValueChanged<PublicProfile> onToggleFollow;
  final VoidCallback? onOpened;

  /// Hides the Follow button on the signed-in user's own row.
  final String? currentUserId;
  const ReviewerList({
    required this.users,
    required this.onToggleFollow,
    this.onOpened,
    this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < users.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: ProfileTheme.hairlineColor(context),
              ),
            _ReviewerRow(
              user: users[i],
              onOpened: onOpened,
              onToggleFollow: users[i].id == currentUserId
                  ? null
                  : () => onToggleFollow(users[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewerRow extends StatelessWidget {
  final PublicProfile user;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onOpened;
  const _ReviewerRow({
    required this.user,
    required this.onToggleFollow,
    this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final bio = user.bio?.split('\n').first.trim();
    final subtitle = [
      if (bio != null && bio.isNotEmpty) bio,
      '${user.reviewsCount} review${user.reviewsCount == 1 ? '' : 's'}',
    ].join(' • ');

    return InkWell(
      onTap: () {
        onOpened?.call();
        AppRouter.router.pushNamed(
          AppRoute.userProfile.name,
          pathParameters: {'username': user.username},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                gradient: ProfileTheme.pinkPurple,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ProfileTheme.surface(context),
                  shape: BoxShape.circle,
                ),
                child: ImageUserCircleProfile(
                  imageUrl: user.profilePicture,
                  name: user.name,
                  size: 40,
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
                      Flexible(
                        child: Text(
                          '@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: ProfileTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const Gap(4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: ProfileTheme.pink,
                        ),
                      ],
                    ],
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            if (onToggleFollow != null) ...[
              const Gap(10),
              _FollowButton(
                following: user.isFollowing,
                onTap: onToggleFollow!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;
  const _FollowButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: following ? null : ProfileTheme.pinkPurple,
          color: following ? ProfileTheme.purple.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: following ? ProfileTheme.textPrimary(context) : Colors.white,
          ),
        ),
      ),
    );
  }
}
