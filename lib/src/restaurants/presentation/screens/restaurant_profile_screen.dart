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
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_switcher_sheet.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_videos_grid.dart';

class RestaurantProfileScreen extends ConsumerWidget {
  final String restaurantId;
  const RestaurantProfileScreen({required this.restaurantId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProfileControllerProvider(restaurantId));
    final myRestaurants = ref.watch(myRestaurantsControllerProvider);
    final isOwner =
        myRestaurants.valueOrNull?.restaurants.any(
          (r) => r.id == restaurantId,
        ) ??
        false;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
        ),
      );
    }
    if (state.restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: ProfileEmptyTabBody(
          icon: Icons.storefront_outlined,
          title: 'Restaurant unavailable',
          message: state.errorMessage ?? 'Not found',
        ),
      );
    }

    final restaurant = state.restaurant!;
    final address = restaurant.address?.trim();
    final description = restaurant.description?.trim();

    Future<void> onFollow() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow this restaurant',
      )) {
        return;
      }
      ref
          .read(restaurantProfileControllerProvider(restaurantId).notifier)
          .toggleFollow();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CoverAvatarHeader(
              coverUrl: restaurant.coverPicture,
              avatarUrl: restaurant.profilePicture,
              name: restaurant.name,
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
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: ProfileTheme.ink,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (restaurant.category != null)
                        _Pill(
                          icon: Icons.restaurant_menu_rounded,
                          label: restaurant.category!.name,
                          color: ProfileTheme.purple,
                        ),
                      if (isOwner)
                        const _Pill(
                          icon: Icons.verified_user_rounded,
                          label: 'Your restaurant',
                          color: ProfileTheme.pink,
                        ),
                    ],
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const Gap(12),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: ProfileTheme.ink,
                      ),
                    ),
                  ],
                  const Gap(18),
                  // Only `followersCount` is real today — Following (a
                  // restaurant doesn't follow anything) and Likes (no
                  // aggregate endpoint) show 0 until there's real data.
                  ProfileStatsRow(
                    stats: [
                      const ProfileStat(
                        value: 0,
                        label: 'Following',
                        icon: Icons.person_add_alt_1_rounded,
                      ),
                      ProfileStat(
                        value: restaurant.followersCount ?? 0,
                        label: 'Followers',
                        icon: Icons.people_alt_rounded,
                      ),
                      const ProfileStat(
                        value: 0,
                        label: 'Likes',
                        icon: Icons.favorite_rounded,
                      ),
                    ],
                  ),
                  const Gap(14),
                  if (isOwner)
                    ProfileCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.dashboard_customize_rounded,
                                size: 18,
                                color: ProfileTheme.purple,
                              ),
                              Gap(8),
                              Text(
                                'Manage restaurant',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ProfileTheme.ink,
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Expanded(
                                child: ProfileGradientButton(
                                  text: 'Post video',
                                  icon: Icons.videocam_rounded,
                                  onTap: () => AppRouter.router.pushNamed(
                                    AppRoute.cameraRecord.name,
                                  ),
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: ProfileOutlineButton(
                                  text: 'Menu',
                                  icon: Icons.menu_book_rounded,
                                  onTap: () =>
                                      AppService.showToast('Coming soon'),
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          ProfileOutlineButton(
                            text: 'Switch restaurant',
                            icon: Icons.swap_horiz_rounded,
                            onTap: () => showRestaurantSwitcherSheet(context),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ProfileFollowButton(
                            isFollowing: state.isFollowingLocally,
                            onTap: onFollow,
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: ProfileOutlineButton(
                            text: 'Menu',
                            icon: Icons.menu_book_rounded,
                            onTap: () => AppService.showToast('Coming soon'),
                          ),
                        ),
                      ],
                    ),
                  if (address != null && address.isNotEmpty) ...[
                    const Gap(14),
                    ProfileCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: ProfileInfoTile(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: address,
                        color: ProfileTheme.pink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(22),
            // Videos and Reviews both show real videos (posts vs. review
            // uploads for this restaurant); Shared/Liked have no backend
            // support yet so they're honest placeholders. There's no rating
            // system in the backend at all yet, so Reviews is video-only —
            // no star widget, since there'd be nowhere to save it.
            ProfileIconTabStrip(
              icons: [
                AssetsName.feeds,
                AssetsName.comment,
                AssetsName.share,
                AssetsName.heart,
              ],
              labels: const ['Videos', 'Reviews', 'Shared', 'Liked'],
              bodyBuilder: (context, index) => switch (index) {
                0 => RestaurantVideosGrid(
                  restaurantId: restaurantId,
                  emptyTitle: 'No videos yet',
                  emptyMessage:
                      'Videos posted by this restaurant show up here.',
                ),
                1 => RestaurantVideosGrid(
                  restaurantId: restaurantId,
                  type: 'review',
                  emptyTitle: 'No reviews yet',
                  emptyMessage: 'Be the first to review this restaurant.',
                ),
                2 => ProfileEmptyTabBody(
                  asset: AssetsName.share,
                  title: 'Nothing shared',
                  message: 'Shared videos aren\'t available here yet.',
                ),
                _ => ProfileEmptyTabBody(
                  asset: AssetsName.heart,
                  title: 'Nothing liked',
                  message: 'Liked videos aren\'t available here yet.',
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

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
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
