import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/profile_qr_screen.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_tiles.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_shared_widgets.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/users/presentation/user_profile_controller.dart';
import 'package:khmer_cat_app/src/users/presentation/widgets/user_videos_grid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:khmer_cat_app/src/people/presentation/people_list_screen.dart';

class UserProfileScreen extends HookConsumerWidget {
  final String username;
  const UserProfileScreen({required this.username, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final tab = useState(0);
    final visited = useState<Set<int>>({0});
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

    Future<void> changeImage(ProfileImageKind kind) async {
      await changeProfileImage(context, ref, kind);
      if (!context.mounted) return;
      ref
          .read(userProfileControllerProvider(username).notifier)
          .refreshQuietly();
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
      (
        SocialLinks.telegram(profile.telegramUsername),
        AssetsName.telegram,
        'Telegram',
      ),
    ].where((l) => l.$1 != null).map((l) => (l.$1!, l.$2, l.$3)).toList();

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            ProfileCollapsingHeader(
              scrollController: scrollController,
              coverUrl: profile.coverPicture,
              avatarUrl: profile.profilePicture,
              name: profile.name,
              subtitle: '@${profile.username}',
              // 16:9
              coverHeight: MediaQuery.sizeOf(context).width * 9 / 16,
              avatarSize: 90,
              coverRadius: 0,
              centerAvatar: true,
              // Your own profile: change the cover and the photo in place.
              coverAction: isMe
                  ? ProfileChangeCoverButton(
                      onTap: () => changeImage(ProfileImageKind.cover),
                    )
                  : null,
              avatarBadge: isMe
                  ? ProfileChangeCoverButton(
                      size: 30,
                      tooltip: 'Change photo',
                      onTap: () => changeImage(ProfileImageKind.avatar),
                    )
                  : null,
              lightControls: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              actions: [
                ProfileCircleButton(
                  iconAsset: AssetsName.qrCode,
                  onTap: () => openProfileQr(
                    context,
                    name: profile.name,
                    username: profile.username,
                    avatarUrl: profile.profilePicture,
                  ),
                ),
                // These go straight into the app bar, which adds no spacing.
                const Gap(10),
                ProfileCircleButton(
                  icon: Icons.ios_share_rounded,
                  onTap: share,
                ),
                const Gap(6),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Name (+ verified), then "Personal" and the @handle.
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: ProfileTheme.textPrimary(context),
                      ),
                    ),
                    const Gap(10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        const ProfileTypeChip(isRestaurant: false),
                        Text(
                          '@${profile.username}',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: ProfileTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const Gap(12),
                      Text(
                        bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: ProfileTheme.textPrimary(context),
                        ),
                      ),
                    ],
                    const Gap(_section),
                    ProfileStatsRow(
                      stats: [
                        (_compact(profile.postsCount), 'Posts'),
                        (_compact(profile.followersCount ?? 0), 'Followers'),
                        (_compact(profile.followingCount), 'Following'),
                      ],
                      onTaps: [
                        null,
                        () => openPeopleList(
                          context,
                          PeopleList.userFollowers(profile.username),
                        ),
                        () => openPeopleList(
                          context,
                          PeopleList.userFollowing(profile.username),
                        ),
                      ],
                    ),
                    const Gap(_section),
                    // Follow (or Edit profile) and the social circles.
                    Row(
                      children: [
                        Expanded(
                          child: isMe
                              ? ProfileGradientButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit profile',
                                  onTap: () => AppRouter.router.pushNamed(
                                    AppRoute.editProfile.name,
                                  ),
                                )
                              : ProfileGradientButton(
                                  icon: state.isFollowingLocally
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  label: state.isFollowingLocally
                                      ? 'Following'
                                      : 'Follow',
                                  filled: !state.isFollowingLocally,
                                  onTap: onFollow,
                                ),
                        ),
                        for (final l in socialLinks) ...[
                          const Gap(16),
                          ProfileLinkCircle(
                            label: l.$3,
                            asset: l.$2,
                            onTap: () => SocialLinks.open(l.$1),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(_section)),
            // Pinned under the app bar so the tabs stay reachable while
            // scrolling through a long grid.
            SliverPersistentHeader(
              pinned: true,
              delegate: FixedSliverHeaderDelegate(
                height: 48,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ProfileUnderlineTabs(
                    showBaseline: false,
                    tabs: [
                      ProfileUnderlineTab(
                        asset: AssetsName.feeds,
                        label: 'Posts',
                      ),
                      ProfileUnderlineTab(
                        asset: AssetsName.review,
                        label: 'Review',
                      ),
                      ProfileUnderlineTab(
                        asset: AssetsName.bookmarkout,
                        label: 'Saved',
                      ),
                    ],
                    selected: tab.value,
                    onChanged: (i) {
                      tab.value = i;
                      if (!visited.value.contains(i)) {
                        visited.value = {...visited.value, i};
                      }
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(16)),
            // The grids stay alive once opened (no refetch when switching
            // back). Saved has no public backend listing (a user's saves
            // are owner-only), so it's an honest placeholder.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Visibility(
                    visible: tab.value == 0,
                    maintainState: true,
                    child: UserVideosGrid(
                      userId: profile.id,
                      emptyTitle: 'No videos yet',
                      emptyMessage:
                          'Videos posted by this account show up here.',
                    ),
                  ),
                  if (visited.value.contains(1))
                    Visibility(
                      visible: tab.value == 1,
                      maintainState: true,
                      child: UserVideosGrid(
                        userId: profile.id,
                        type: 'review',
                        emptyTitle: 'No review videos yet',
                        emptyMessage:
                            'Food reviews from this account show up here.',
                      ),
                    ),
                  if (tab.value == 2)
                    ProfileEmptyTabBody(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Nothing saved yet',
                      message: 'Saved videos aren\'t available here yet.',
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Gap(24 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical gap between the profile's blocks.
const _section = 20.0;

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
