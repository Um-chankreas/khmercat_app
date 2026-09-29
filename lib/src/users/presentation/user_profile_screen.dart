import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_tiles.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_social_widgets.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/users/presentation/user_profile_controller.dart';
import 'package:khmer_cat_app/src/users/presentation/widgets/user_videos_grid.dart';
import 'package:share_plus/share_plus.dart';

class UserProfileScreen extends HookConsumerWidget {
  final String username;
  const UserProfileScreen({required this.username, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final tab = useState(0);
    final state = ref.watch(userProfileControllerProvider(username));
    final currentUser = ref.watch(currentUserProvider);
    final isMe = currentUser?.username == username;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
        ),
      );
    }
    if (state.profile == null) {
      return Scaffold(
        appBar: AppBar(surfaceTintColor: Colors.transparent),
        body: ProfileEmptyTabBody(
          icon: Icons.person_off_outlined,
          title: 'Profile unavailable',
          message: state.errorMessage ?? 'Not found',
        ),
      );
    }

    final profile = state.profile!;
    final bio = profile.bio?.trim();

    Future<void> onFollow() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow this account',
      )) {
        return;
      }
      ref.read(userProfileControllerProvider(username).notifier).toggleFollow();
    }

    void share() => SharePlus.instance.share(
      ShareParams(
        text: '${profile.name} (@${profile.username}) on Khmer Cat',
        subject: 'Khmer Cat',
      ),
    );

    final socialLinks = [
      (
        SocialLinks.facebook(profile.facebookUrl),
        AssetsName.facebook,
        'Facebook',
      ),
      (SocialLinks.tiktok(profile.tiktokUrl), AssetsName.tiktok, 'TikTok'),
      (
        SocialLinks.telegram(profile.telegramUsername),
        AssetsName.telegram,
        'Telegram',
      ),
    ].where((l) => l.$1 != null).map((l) => (l.$1!, l.$2, l.$3)).toList();

    final tiles = isMe
        ? [
            ProfileActionTile(
              icon: Icons.edit_rounded,
              label: 'Edit profile',
              primary: true,
              onTap: () =>
                  AppRouter.router.pushNamed(AppRoute.editProfile.name),
            ),
            ProfileActionTile(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: share,
            ),
          ]
        : [
            ProfileActionTile(
              icon: state.isFollowingLocally
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_rounded,
              label: state.isFollowingLocally ? 'Following' : 'Follow',
              primary: !state.isFollowingLocally,
              onTap: onFollow,
            ),
            // TODO(backend): no direct messages yet.
            ProfileActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Message',
              onTap: () => AppService.showToast('Coming soon'),
            ),
            ProfileActionTile(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: share,
            ),
          ];

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          ProfileCollapsingHeader(
            scrollController: scrollController,
            coverUrl: profile.coverPicture,
            avatarUrl: profile.profilePicture,
            name: profile.name,
            subtitle: '@${profile.username}',
            coverHeight: MediaQuery.sizeOf(context).width * 9 / 16,
            avatarSize: 86,
            coverRadius: 0,
            onBack: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (+ verified), then the @handle — people have a
                  // handle, restaurants don't, which already sets them apart.
                  Text.rich(
                    TextSpan(
                      text: profile.name,
                      children: [
                        if (profile.isVerified)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: Color(0xff3B82F6),
                              ),
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ProfileTheme.pink,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Person chip = a person (restaurants get a storefront
                      // chip with their category instead).
                      const ProfileTypeChip(isRestaurant: false),
                      if (profile.reviewsCount > 0)
                        _Chip(
                          icon: Icons.rate_review_rounded,
                          label: 'Food reviewer',
                          color: ProfileTheme.purple,
                        ),
                      if (isMe)
                        const _Chip(
                          icon: Icons.face_rounded,
                          label: 'You',
                          color: ProfileTheme.pink,
                        ),
                    ],
                  ),
                  const Gap(10),
                  _StatsLine(
                    stats: [
                      (profile.followingCount, 'following', 'following'),
                      (profile.followersCount ?? 0, 'follower', 'followers'),
                      (profile.likesReceived, 'like', 'likes'),
                      if (profile.reviewsCount > 0)
                        (profile.reviewsCount, 'review', 'reviews'),
                    ],
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const Gap(10),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],

                  // ---- Action tiles + social strip (same as restaurants)
                  const Gap(16),
                  Row(
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const Gap(8),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  ),
                  if (socialLinks.isNotEmpty) ...[
                    const Gap(12),
                    ProfileSocialStrip(links: socialLinks),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Gap(16)),
          SliverToBoxAdapter(
            child: ProfileSegmentTabs(
              tabs: [
                ProfileSegmentTab(
                  asset: AssetsName.feeds,
                  label: 'Videos',
                  count: profile.postsCount,
                ),
                ProfileSegmentTab(
                  asset: AssetsName.heartout,
                  label: 'Favorites',
                ),
              ],
              selected: tab.value,
              onChanged: (i) => tab.value = i,
              compact: true,
            ),
          ),
          const SliverToBoxAdapter(child: Gap(16)),
          // Videos stays alive while Favorites is shown (no refetch when
          // switching back). Favorites has no public backend listing (a
          // user's saves are owner-only), so it's an honest placeholder.
          SliverToBoxAdapter(
            child: Column(
              children: [
                Visibility(
                  visible: tab.value == 0,
                  maintainState: true,
                  child: UserVideosGrid(
                    userId: profile.id,
                    emptyTitle: 'No videos yet',
                    emptyMessage: 'Videos posted by this account show up here.',
                  ),
                ),
                if (tab.value == 1)
                  ProfileEmptyTabBody(
                    asset: AssetsName.heartout,
                    title: 'No favorites yet',
                    message: 'Favorite videos aren\'t available here yet.',
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: Gap(16)),
        ],
      ),
    );
  }
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// "0 following · 3 followers · 20 likes" — one quiet line, like the
/// restaurant page's stats.
class _StatsLine extends StatelessWidget {
  /// (count, singular label, plural label)
  final List<(int, String, String)> stats;
  const _StatsLine({required this.stats});

  @override
  Widget build(BuildContext context) {
    final strong = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      color: ProfileTheme.textPrimary(context),
    );
    final soft = TextStyle(
      fontSize: 13.5,
      color: ProfileTheme.textSecondary(context),
    );
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) TextSpan(text: '  ·  ', style: soft),
            TextSpan(text: _compact(stats[i].$1), style: strong),
            TextSpan(
              text: ' ${stats[i].$1 == 1 ? stats[i].$2 : stats[i].$3}',
              style: soft,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
