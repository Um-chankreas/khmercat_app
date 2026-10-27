import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/profile_qr_screen.dart';
import 'package:khmer_cat_app/core/components/halal_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_shared_widgets.dart'
    hide ProfileGradientButton;
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';
import 'package:khmer_cat_app/src/holidays/presentation/holiday_poster_card.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/expandable_text.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_info_panel.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_videos_grid.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/unpublished_banner.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';
import 'package:khmer_cat_app/src/people/presentation/people_list_screen.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/approval_banner.dart';

/// The Profile tab while the user is acting as a restaurant — the same look
/// as their personal profile tab (full-bleed cover, camera buttons on the
/// cover and logo, edit button, stats card, pinned icon tabs), plus the
/// restaurant's category.
class RestaurantOwnerProfileTab extends HookConsumerWidget {
  final String restaurantId;
  const RestaurantOwnerProfileTab({required this.restaurantId, super.key});

  static const double _avatarSize = 86;

  static const _videos = 0;
  static const _reviews = 1;
  static const _info = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = restaurantProfileControllerProvider(restaurantId);
    final state = ref.watch(provider);
    final selected = useState(_videos);
    // Grids stay alive once opened, so switching tabs doesn't refetch.
    final visited = useState<Set<int>>({_videos});
    final scrollController = useScrollController();
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;
    final l = AppLocalizations.of(context);

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
                title: l.restaurantUnavailable,
                message: state.errorMessage ?? l.notFound,
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

    final width = MediaQuery.sizeOf(context).width;

    // Videos / Reviews grids: 16px between the tab bar and the grid.
    Widget pane(int index, Widget child) => Visibility(
      visible: selected.value == index,
      maintainState: true,
      child: Padding(padding: const EdgeInsets.only(top: 16), child: child),
    );

    void openEdit() => AppRouter.router.pushNamed(
      AppRoute.editRestaurant.name,
      pathParameters: {'id': restaurantId},
    );

    final subtitle = [
      restaurant.category?.name,
      restaurant.address?.trim(),
    ].where((x) => x != null && x.isNotEmpty).join(' · ');

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: ColoredBox(
        color: pageBackground,
        child: RefreshIndicator(
          color: ProfileTheme.purple,
          onRefresh: () => ref.read(provider.notifier).load(),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              ProfileCollapsingHeader(
                scrollController: scrollController,
                coverUrl: restaurant.coverPicture,
                avatarUrl: restaurant.profilePicture,
                name: restaurant.name,
                subtitle: restaurant.category?.name,
                coverHeight: width * 0.45,
                avatarSize: _avatarSize,
                coverRadius: 0,
                lightControls: true,
                coverAction: ProfileChangeCoverButton(
                  onTap: () => uploadImage(ProfileImageKind.cover),
                ),
                avatarBadge: ProfileEditIconButton(
                  icon: Icons.photo_camera_rounded,
                  size: 26,
                  ringed: true,
                  onTap: () => uploadImage(ProfileImageKind.avatar),
                ),
                actions: [
                  // Same menu button as the personal profile tab.
                  ProfileCircleButton(
                    iconAsset: AssetsName.menu,
                    iconSize: 16,
                    padding: 8,
                    onTap: () =>
                        AppRouter.router.pushNamed(AppRoute.settings.name),
                  ),
                  const Gap(6),
                ],
                // The Edit pill under the avatar and the menu button on
                // the right; the name follows below.
                belowFoldHeight: 54,
                belowFoldAction: SizedBox(
                  width: width - 40,
                  height: 54,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        width: 98,
                        top: 25,
                        child: Center(child: _EditPill(onTap: openEdit)),
                      ),
                      // Its QR code, like a person's profile has, left of the menu.
                      Positioned(
                        right: 36,
                        top: 0,
                        child: ProfileRaisedCircleButton(
                          asset: AssetsName.qrCode,
                          tooltip: l.qrCodeTooltip,
                          onTap: () => openRestaurantQr(
                            context,
                            name: restaurant.name,
                            restaurantId: restaurantId,
                            category: restaurant.category?.name,
                            avatarUrl: restaurant.profilePicture,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        top: 0,
                        child: ProfileRaisedCircleButton(
                          asset: AssetsName.foodMenu,
                          iconSize: 18,
                          iconColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          tooltip: l.menuTitle,
                          onTap: () => AppRouter.router.pushNamed(
                            AppRoute.restaurantMenu.name,
                            pathParameters: {'id': restaurantId},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameBlock(
                        name: restaurant.name,
                        subtitle: subtitle,
                        isHalal: restaurant.isHalal,
                      ),
                      const Gap(12),
                      _RestaurantInfo(
                        restaurant: restaurant,
                        onRemovePoster: (holiday) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dialog) => AlertDialog(
                              title: Text(l.removePosterTitle),
                              content: Text(l.removePosterMessage),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialog, false),
                                  child: Text(l.cancelAction),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialog, true),
                                  child: Text(
                                    l.removeAction,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await ref
                                .read(restaurantRepositoryProvider)
                                .deleteHoliday(holiday.id);
                            await ref.read(provider.notifier).refreshQuietly();
                          } catch (_) {
                            AppService.showToast(
                              l.removePosterFailed,
                              isError: true,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(14)),
              // Pinned under the app bar so the tabs stay reachable while
              // scrolling through a long grid.
              SliverPersistentHeader(
                pinned: true,
                delegate: FixedSliverHeaderDelegate(
                  height: 48,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ProfileUnderlineTabs(
                      tabs: [
                        // Same icons as the public restaurant profile's tabs.
                        ProfileUnderlineTab(
                          asset: AssetsName.feeds,
                          label: l.profileTabPosts,
                        ),
                        ProfileUnderlineTab(
                          asset: AssetsName.review,
                          label: l.restaurantTabReviews,
                        ),
                        ProfileUnderlineTab(
                          asset: AssetsName.lcInfo,
                          label: l.restaurantTabInfo,
                        ),
                      ],
                      selected: selected.value,
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
              SliverFillBelowPinned(
                pinnedHeight:
                    // The collapsed app bar and the tabs.
                    MediaQuery.paddingOf(context).top +
                    ProfileCollapsingHeader.pinnedHeaderHeight +
                    48,
                child: Column(
                  children: [
                    pane(
                      _videos,
                      RestaurantVideosGrid(
                        restaurantId: restaurantId,
                        canManage: true,
                        onDeleted: () {
                          // Refresh the posts count in the stats row.
                          ref.read(provider.notifier).load();
                        },
                        emptyTitle: l.restaurantNoPostsTitle,
                        emptyMessage: l.restaurantNoPostsOwner,
                      ),
                    ),
                    if (visited.value.contains(_reviews))
                      pane(
                        _reviews,
                        RestaurantVideosGrid(
                          restaurantId: restaurantId,
                          type: 'review',
                          emptyTitle: l.noReviewersYet,
                          emptyMessage: l.restaurantReviewsEmpty,
                        ),
                      ),
                    if (selected.value == _info)
                      RestaurantInfoPanel(
                        restaurant: restaurant,
                        showAbout: false,
                        onOpenMenu: () => AppRouter.router.pushNamed(
                          AppRoute.restaurantMenu.name,
                          pathParameters: {'id': restaurantId},
                        ),
                        onEdit: () => AppRouter.router.pushNamed(
                          AppRoute.editRestaurant.name,
                          pathParameters: {'id': restaurantId},
                        ),
                      ),
                    // Clear of the floating nav bar.
                    Gap(24 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The restaurant name's style under the avatar.
TextStyle _headerNameStyle(BuildContext context) => TextStyle(
  fontSize: 18,
  height: 1.15,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.3,
  color: ProfileTheme.textPrimary(context),
);

/// Name under the avatar, then Halal and category · address on one line.
class _NameBlock extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isHalal;
  const _NameBlock({
    required this.name,
    required this.subtitle,
    required this.isHalal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always the full name, wrapping if it's long.
        Text(name, style: _headerNameStyle(context)),
        if (isHalal || subtitle.isNotEmpty) ...[
          const Gap(6),
          // Halal, then category · address, on one line.
          Row(
            children: [
              if (isHalal) ...[const HalalBadge(), const Gap(8)],
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: ProfileTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Approval / unpublished banners, then Posts · Reviews · Followers ·
/// Following.
class _RestaurantInfo extends StatelessWidget {
  final Restaurant restaurant;
  final ValueChanged<RestaurantHoliday> onRemovePoster;
  const _RestaurantInfo({
    required this.restaurant,
    required this.onRemovePoster,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = restaurant;
    final about = r.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About, under the logo — as on the public profile.
        if (about != null && about.isNotEmpty) ...[
          ExpandableText(
            text: about,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
        ],
        // Its upcoming holiday poster.
        if (r.upcomingHoliday != null) ...[
          const Gap(14),
          HolidayPosterCard(
            holiday: r.upcomingHoliday!,
            restaurantName: r.name,
            onRemove: () => onRemovePoster(r.upcomingHoliday!),
          ),
        ],
        if (ApprovalBanner.appliesTo(r)) ...[
          const Gap(12),
          ApprovalBanner(restaurant: r),
        ],
        if (!r.isPublished) ...[
          const Gap(12),
          UnpublishedBanner(restaurant: r),
        ],
        const Gap(14),
        ProfileStatsRow(
          stats: [
            (_compact(r.videosCount), l.statPosts),
            (_compact(r.reviewsCount), l.statReviews),
            (_compact(r.followersCount ?? 0), l.statFollowers),
            (_compact(r.followingCount ?? 0), l.statFollowing),
          ],
          onTaps: [
            null,
            () => openPeopleList(context, PeopleList.restaurantReviewers(r.id)),
            () => openPeopleList(context, PeopleList.restaurantFollowers(r.id)),
            () => openPeopleList(context, PeopleList.restaurantFollowing(r.id)),
          ],
        ),
      ],
    );
  }
}

/// "✎ Edit" on the pastel wash, centered under the avatar.
class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xffF0A6CE), Color(0xffA9C1F5)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 15, color: ProfileTheme.ink),
            const Gap(3),
            Text(
              AppLocalizations.of(context).editAction,
              style: const TextStyle(
                fontSize: 13,
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

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
