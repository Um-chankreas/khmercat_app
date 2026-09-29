import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart'
    show timeAgo;
import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';
import 'package:khmer_cat_app/src/notifications/domain/notification_group.dart';

const _likeColor = Color(0xffFF4D67);
const _commentColor = Color(0xff4DA8FF);
const _followColor = Color(0xff8B5CF6);
const _postColor = Color(0xffE066A8);

(IconData, Color) _badgeFor(NotificationType type) => switch (type) {
  NotificationType.follow => (Icons.person_add_rounded, _followColor),
  NotificationType.like => (Icons.favorite_rounded, _likeColor),
  NotificationType.comment ||
  NotificationType.reply => (Icons.chat_bubble_rounded, _commentColor),
  NotificationType.restaurantVideo => (Icons.videocam_rounded, _postColor),
  NotificationType.unknown => (Icons.notifications_rounded, ProfileTheme.muted),
};

/// One notification row (possibly several grouped together): avatar(s)
/// with a type badge, a short sentence with bold names, an optional quoted
/// comment, the time, and on the right the video thumbnail(s) or a
/// "Follow back" button. Unread rows sit on a soft tinted card with a dot.
class NotificationTile extends StatelessWidget {
  final NotificationGroup group;
  final VoidCallback onTap;
  final VoidCallback? onFollowBack;

  const NotificationTile({
    required this.group,
    required this.onTap,
    this.onFollowBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final g = group;
    final unread = !g.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ProfileTheme.textSecondary(context);
    final preview = g.latest.commentPreview;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: unread
            ? ProfileTheme.purple.withValues(alpha: isDark ? 0.14 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatars(group: g),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        _sentence(context, g),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (preview != null && preview.isNotEmpty) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _commentColor.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                              topLeft: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: ProfileTheme.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                      const Gap(5),
                      Row(
                        children: [
                          if (unread) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                gradient: ProfileTheme.pinkPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                          ],
                          Text(
                            timeAgo(g.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: unread ? ProfileTheme.deepPurple : muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(10),
                _Trailing(group: g, onFollowBack: onFollowBack),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "@a and 3 others liked your review", "@a liked 8 of your reviews", …
  static TextSpan _sentence(BuildContext context, NotificationGroup g) {
    final base = TextStyle(
      fontSize: 14.5,
      height: 1.35,
      color: ProfileTheme.textPrimary(context),
    );
    const bold = TextStyle(fontWeight: FontWeight.w800);
    TextSpan b(String t) => TextSpan(text: t, style: bold);
    TextSpan t(String s) => TextSpan(text: s);

    final actors = g.actors;
    final first = actors.isNotEmpty ? '@${actors.first.username}' : 'Someone';
    List<InlineSpan> who() {
      if (actors.length <= 1) return [b(first)];
      if (actors.length == 2) {
        return [b(first), t(' and '), b('@${actors[1].username}')];
      }
      return [b(first), t(' and '), b('${actors.length - 1} others')];
    }

    final children = switch (g.type) {
      NotificationType.like =>
        actors.length > 1
            ? [...who(), t(' liked your review')]
            : g.videoCount > 1
            ? [
                b(first),
                t(' liked '),
                b('${g.videoCount}'),
                t(' of your reviews'),
              ]
            : [b(first), t(' liked your review')],
      NotificationType.comment => [b(first), t(' commented on your review')],
      NotificationType.reply => [b(first), t(' replied to your comment')],
      NotificationType.follow => [b(first), t(' started following you')],
      NotificationType.restaurantVideo =>
        g.items.length > 1
            ? [
                b(g.latest.restaurantName ?? 'A restaurant'),
                t(' posted '),
                b('${g.items.length}'),
                t(' new videos'),
              ]
            : [
                b(g.latest.restaurantName ?? 'A restaurant'),
                t(' posted a new video'),
              ],
      NotificationType.unknown => [
        b(g.latest.subjectName),
        t(' sent you a notification'),
      ],
    };
    return TextSpan(style: base, children: children);
  }
}

/// One avatar, or two overlapping ones for a group of people — always with
/// the type badge (heart / bubble / person / camera) on the corner.
class _Avatars extends StatelessWidget {
  final NotificationGroup group;
  const _Avatars({required this.group});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _badgeFor(group.type);
    final ring = Theme.of(context).scaffoldBackgroundColor;
    final actors = group.actors;
    final isRestaurant = group.type == NotificationType.restaurantVideo;

    Widget avatar(String? url, String name, double size) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: ImageUserCircleProfile(imageUrl: url, name: name, size: size),
    );

    final Widget faces;
    if (!isRestaurant && actors.length > 1) {
      faces = SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: avatar(actors[1].profilePicture, actors[1].name, 32),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: avatar(actors[0].profilePicture, actors[0].name, 32),
            ),
          ],
        ),
      );
    } else {
      faces = avatar(group.latest.avatarUrl, group.latest.subjectName, 46);
    }

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          faces,
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
              child: Icon(icon, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right side: "Follow back" for follows, else the video thumbnail — or two
/// stacked thumbnails with a "+N" count for a group of videos.
class _Trailing extends StatelessWidget {
  final NotificationGroup group;
  final VoidCallback? onFollowBack;
  const _Trailing({required this.group, required this.onFollowBack});

  @override
  Widget build(BuildContext context) {
    final g = group;
    if (g.type == NotificationType.follow) {
      final following = g.latest.actor?.isFollowing ?? false;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _FollowBackButton(
          following: following,
          onTap: following ? null : onFollowBack,
        ),
      );
    }

    final thumbs = g.thumbnails;
    if (thumbs.isEmpty) return const SizedBox.shrink();

    Widget thumb(String url, {double size = 48}) => ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Container(
          width: size,
          height: size,
          color: ProfileTheme.purple.withValues(alpha: 0.1),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: ProfileTheme.muted,
          ),
        ),
      ),
    );

    if (thumbs.length == 1) return thumb(thumbs.first);

    final ring = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      width: 56,
      height: 54,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(opacity: 0.6, child: thumb(thumbs[1], size: 44)),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ring, width: 2),
              ),
              child: thumb(thumbs.first, size: 44),
            ),
          ),
          if (thumbs.length > 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${thumbs.length - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowBackButton extends StatelessWidget {
  final bool following;
  final VoidCallback? onTap;
  const _FollowBackButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: following ? null : ProfileTheme.pinkPurple,
          color: following ? ProfileTheme.purple.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              following ? 'Following' : 'Follow back',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: following ? ProfileTheme.deepPurple : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
