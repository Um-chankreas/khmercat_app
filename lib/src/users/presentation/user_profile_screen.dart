import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_icon_tab_strip.dart';
import 'package:khmer_cat_app/core/components/profile/profile_stats_row.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/users/presentation/user_profile_controller.dart';

class UserProfileScreen extends ConsumerWidget {
  final String username;
  const UserProfileScreen({required this.username, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileControllerProvider(username));
    final currentUser = ref.watch(currentUserProvider);
    final isMe = currentUser?.username == username;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
        ),
      );
    }
    if (state.profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: ProfileEmptyTabBody(
          icon: Icons.person_off_outlined,
          title: 'Profile unavailable',
          message: state.errorMessage ?? 'Not found',
        ),
      );
    }

    final profile = state.profile!;
    final bio = profile.bio?.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CoverAvatarHeader(
              coverUrl: profile.coverPicture,
              avatarUrl: profile.profilePicture,
              name: profile.name,
              onBack: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
            Gap(CoverAvatarHeader.contentGap()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: ProfileTheme.ink,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: ProfileTheme.deepPurple,
                    ),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const Gap(10),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: ProfileTheme.ink,
                      ),
                    ),
                  ],
                  const Gap(18),
                  // Only `followersCount` is real today — Following/Posts/
                  // Likes have no endpoint yet and show 0 until one exists.
                  ProfileStatsRow(
                    stats: [
                      const ProfileStat(
                        value: 0,
                        label: 'Following',
                        icon: Icons.person_add_alt_1_rounded,
                      ),
                      ProfileStat(
                        value: profile.followersCount ?? 0,
                        label: 'Followers',
                        icon: Icons.people_alt_rounded,
                      ),
                      const ProfileStat(
                        value: 0,
                        label: 'Posts',
                        icon: Icons.grid_view_rounded,
                      ),
                      const ProfileStat(
                        value: 0,
                        label: 'Likes',
                        icon: Icons.favorite_rounded,
                      ),
                    ],
                  ),
                  if (!isMe) ...[
                    const Gap(14),
                    ProfileFollowButton(
                      isFollowing: state.isFollowingLocally,
                      onTap: () async {
                        if (!await requireLogin(
                          context,
                          ref,
                          message: 'Sign in to follow this account',
                        )) {
                          return;
                        }
                        ref
                            .read(
                              userProfileControllerProvider(username).notifier,
                            )
                            .toggleFollow();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Gap(22),
            // Videos / Favorites — neither has backend support for a specific
            // user yet (the videos feed can only be filtered by restaurant,
            // and there's no per-user favorites listing), so each tab is an
            // honest placeholder rather than fake content.
            ProfileIconTabStrip(
              icons: [AssetsName.feeds, AssetsName.heartout],
              labels: const ['Videos', 'Favorites'],
              bodyBuilder: (context, index) => switch (index) {
                0 => ProfileEmptyTabBody(
                  asset: AssetsName.feeds,
                  title: 'No videos to show',
                  message: 'Videos aren\'t available here yet.',
                ),
                _ => ProfileEmptyTabBody(
                  asset: AssetsName.heartout,
                  title: 'No favorites yet',
                  message: 'Favorite videos aren\'t available here yet.',
                ),
              },
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}
