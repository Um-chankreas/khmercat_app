import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_icon_tab_strip.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_stats_row.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_info_panel.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_videos_grid.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/unpublished_banner.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// The Profile tab while the user is acting as a restaurant — the same look
/// as their personal profile tab (full-bleed cover, camera buttons on the
/// cover and logo, edit button, stats card, pinned icon tabs), plus the
/// restaurant's category.
class RestaurantOwnerProfileTab extends HookConsumerWidget {
  final String restaurantId;
  const RestaurantOwnerProfileTab({required this.restaurantId, super.key});

  static const double _coverAspectRatio = 16 / 9;
  static const double _avatarSize = 84;
  static const double _pinnedHeaderHeight = 60;
  static const double _contentGap = (_avatarSize + 12) / 2 + 8;
  static final double _tabBarHeight = ProfileTabBar.heightFor(withLabels: true);

  static final _icons = [
    AssetsName.feeds,
    AssetsName.review,
    AssetsName.delete,
    AssetsName.profileinfo,
  ];
  static const _labels = ['Videos', 'Reviews', 'Delete', 'Info'];
  static const _videos = 0;
  static const _reviews = 1;
  static const _deleted = 2;
  static const _info = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = restaurantProfileControllerProvider(restaurantId);
    final state = ref.watch(provider);
    final selected = useState(_videos);
    // Grids stay alive once opened, so switching tabs doesn't refetch.
    final visited = useState<Set<int>>({_videos});
    // Bumped on every delete so the (kept-alive) Delete tab reloads.
    final deletedVersion = useState(0);
    final scrollController = useScrollController();
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;

    final restaurant = state.restaurant;
    if (restaurant == null) {
      return ColoredBox(
        color: pageBackground,
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ProfileTheme.purple),
              )
            : ProfileEmptyTabBody(
                icon: Icons.storefront_outlined,
                title: 'Restaurant unavailable',
                message: state.errorMessage ?? 'Not found',
              ),
      );
    }

    /// Uploads a new logo/cover, then refreshes this page and the switcher
    /// list (which feeds the bottom bar's avatar).
    Future<void> uploadImage(ProfileImageKind kind) {
      final isCover = kind == ProfileImageKind.cover;
      return changeProfileImage(
        context,
        ref,
        kind,
        uploader: (file, onProgress) async {
          await ref
              .read(restaurantRepositoryProvider)
              .uploadImage(
                restaurantId,
                file,
                cover: isCover,
                onProgress: onProgress,
              );
          await ref.read(provider.notifier).load();
          await ref
              .read(myRestaurantsControllerProvider.notifier)
              .reloadQuietly();
        },
      );
    }

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final coverHeight = MediaQuery.sizeOf(context).width / _coverAspectRatio;
    final expandedHeaderHeight = coverHeight + _contentGap;
    final titleFadeDistance =
        expandedHeaderHeight - statusBarHeight - _pinnedHeaderHeight;

    // Videos / Reviews grids: 16px between the tab bar and the grid.
    Widget pane(int index, Widget child) => Visibility(
      visible: selected.value == index,
      maintainState: true,
      child: Padding(padding: const EdgeInsets.only(top: 16), child: child),
    );

    return ColoredBox(
      color: pageBackground,
      child: RefreshIndicator(
        color: ProfileTheme.purple,
        onRefresh: () => ref.read(provider.notifier).load(),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            ListenableBuilder(
              listenable: scrollController,
              builder: (context, _) {
                final opacity = !scrollController.hasClients
                    ? 0.0
                    : scrollController.offset.clamp(0.0, titleFadeDistance) /
                          titleFadeDistance;
                return SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: expandedHeaderHeight - statusBarHeight,
                  toolbarHeight: _pinnedHeaderHeight,
                  backgroundColor: Color.lerp(
                    Colors.transparent,
                    pageBackground,
                    opacity,
                  ),
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  centerTitle: false,
                  titleSpacing: context.sc(16),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: SizedBox(
                      height: expandedHeaderHeight,
                      child: ColoredBox(
                        color: pageBackground,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: IgnorePointer(
                            ignoring: opacity >= 1,
                            child: CoverAvatarHeader(
                              coverUrl: restaurant.coverPicture,
                              avatarUrl: restaurant.profilePicture,
                              name: restaurant.name,
                              coverHeight: coverHeight,
                              avatarSize: _avatarSize,
                              coverRadius: 0,
                              coverTint: ProfileTheme.coverMoodTint,
                              topLeft: _CoverCategoryLabel(
                                category: restaurant.category?.name,
                              ),
                              coverAction: ProfileEditIconButton(
                                icon: Icons.photo_camera_rounded,
                                size: 34,
                                onTap: () =>
                                    uploadImage(ProfileImageKind.cover),
                              ),
                              avatarBadge: ProfileEditIconButton(
                                icon: Icons.photo_camera_rounded,
                                size: 26,
                                ringed: true,
                                onTap: () =>
                                    uploadImage(ProfileImageKind.avatar),
                              ),
                              belowFoldAction: ProfileEditIconButton(
                                icon: Icons.edit_rounded,
                                onTap: () => AppRouter.router.pushNamed(
                                  AppRoute.editRestaurant.name,
                                  pathParameters: {'id': restaurantId},
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: _PinnedTitle(restaurant: restaurant, opacity: opacity),
                  actions: [
                    ProfileCircleButton(
                      iconAsset: AssetsName.settings,
                      dark: true,
                      onTap: () =>
                          AppRouter.router.pushNamed(AppRoute.settings.name),
                    ),
                    Gap(context.sc(16)),
                  ],
                );
              },
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: pageBackground,
                child: _RestaurantInfo(restaurant: restaurant),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: FixedSliverHeaderDelegate(
                height: _tabBarHeight,
                child: Container(
                  color: pageBackground,
                  alignment: Alignment.center,
                  child: ProfileTabBar(
                    icons: _icons,
                    labels: _labels,
                    selectedIndex: selected.value,
                    onChanged: (i) {
                      selected.value = i;
                      if (!visited.value.contains(i)) {
                        visited.value = {...visited.value, i};
                      }
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  pane(
                    _videos,
                    RestaurantVideosGrid(
                      restaurantId: restaurantId,
                      canManage: true,
                      onDeleted: () {
                        deletedVersion.value++;
                        // Refresh the posts count in the stats card.
                        ref.read(provider.notifier).load();
                      },
                      emptyTitle: 'No videos yet',
                      emptyMessage:
                          'Tap + to post your first video as this restaurant.',
                    ),
                  ),
                  if (visited.value.contains(_reviews))
                    pane(
                      _reviews,
                      RestaurantVideosGrid(
                        restaurantId: restaurantId,
                        type: 'review',
                        emptyTitle: 'No reviews yet',
                        emptyMessage: 'Customer reviews will show up here.',
                      ),
                    ),
                  if (visited.value.contains(_deleted))
                    pane(
                      _deleted,
                      RestaurantVideosGrid(
                        key: ValueKey(deletedVersion.value),
                        restaurantId: restaurantId,
                        deleted: true,
                        emptyTitle: 'Nothing deleted',
                        emptyMessage:
                            'Deleted videos stay here for 30 days, then '
                            'they\'re removed for good.',
                      ),
                    ),
                  if (selected.value == _info)
                    RestaurantInfoPanel(
                      restaurant: restaurant,
                      onOpenMenu: () => AppRouter.router.pushNamed(
                        AppRoute.restaurantMenu.name,
                        pathParameters: {'id': restaurantId},
                      ),
                      onEdit: () => AppRouter.router.pushNamed(
                        AppRoute.editRestaurant.name,
                        pathParameters: {'id': restaurantId},
                      ),
                    ),
                  const Gap(16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category shown top-left on the cover, where the personal profile shows
/// the @username.
class _CoverCategoryLabel extends StatelessWidget {
  final String? category;
  const _CoverCategoryLabel({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
        const Gap(6),
        Flexible(
          child: Text(
            category ?? 'Restaurant',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _PinnedTitle extends StatelessWidget {
  final Restaurant restaurant;
  final double opacity;
  const _PinnedTitle({required this.restaurant, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: opacity < 0.5,
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            ClipOval(
              child: ImageUserCircleProfile(
                imageUrl: restaurant.profilePicture,
                name: restaurant.name,
                size: 32,
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
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
                    restaurant.category?.name ?? 'Restaurant',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ProfileTheme.textSecondary(context),
                    ),
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

/// Name, category chip (+ open status and rating), description and the
/// stats card — mirrors the personal profile's info block.
class _RestaurantInfo extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantInfo({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = restaurant;
    final description = r.description?.trim();
    final muted = ProfileTheme.textSecondary(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          const Gap(6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(
                icon: Icons.restaurant_menu_rounded,
                label: r.category?.name ?? 'No category',
                color: ProfileTheme.deepPurple,
              ),
              if (r.isOpen != null)
                _Chip(
                  icon: Icons.circle,
                  label: r.isOpen! ? 'Open now' : 'Closed',
                  color: r.isOpen!
                      ? const Color(0xff22A45D)
                      : const Color(0xffE5484D),
                ),
              if (r.avgRating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xffFFC83D),
                    ),
                    const Gap(3),
                    Text(
                      r.avgRating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ProfileTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const Gap(8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: ProfileTheme.textPrimary(context).withValues(alpha: 0.7),
              ),
            ),
          ],
          if (r.address?.trim().isNotEmpty == true) ...[
            const Gap(6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 15,
                  color: ProfileTheme.pink,
                ),
                const Gap(4),
                Expanded(
                  child: Text(
                    r.address!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              ],
            ),
          ],
          if (!r.isPublished) ...[
            const Gap(12),
            UnpublishedBanner(restaurant: r),
          ],
          const Gap(14),
          ProfileStatsRow(
            stats: [
              ProfileStat(
                value: r.followersCount ?? 0,
                label: l.statFollowers,
                icon: Icons.people_alt_rounded,
              ),
              ProfileStat(
                value: r.videosCount,
                label: l.statPosts,
                icon: Icons.grid_view_rounded,
              ),
              ProfileStat(
                value: r.reviewsCount,
                label: 'Reviews',
                icon: Icons.star_rounded,
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: icon == Icons.circle ? 8 : 13, color: color),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
