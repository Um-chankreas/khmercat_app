import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_tiles.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_social_widgets.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_info_panel.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_switcher_sheet.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_videos_grid.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/unpublished_banner.dart';
import 'package:share_plus/share_plus.dart';

const _orange = Color(0xffFF8A3D);
const _gold = Color(0xffFFC83D);

class RestaurantProfileScreen extends HookConsumerWidget {
  final String restaurantId;
  const RestaurantProfileScreen({required this.restaurantId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final tab = useState(0);
    final showTop = useState(false);
    useEffect(() {
      void onScroll() {
        final show =
            scrollController.hasClients && scrollController.offset > 700;
        if (show != showTop.value) showTop.value = show;
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);
    final visitedTabs = useState<Set<int>>({0});
    final state = ref.watch(restaurantProfileControllerProvider(restaurantId));
    final myRestaurants = ref.watch(myRestaurantsControllerProvider);
    final isOwner =
        myRestaurants.valueOrNull?.restaurants.any(
          (r) => r.id == restaurantId,
        ) ??
        false;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
        ),
      );
    }
    if (state.restaurant == null) {
      return Scaffold(
        appBar: AppBar(surfaceTintColor: Colors.transparent),
        body: ProfileEmptyTabBody(
          icon: Icons.storefront_outlined,
          title: 'Restaurant unavailable',
          message: state.errorMessage ?? 'Not found',
        ),
      );
    }

    final restaurant = state.restaurant!;
    final r = restaurant;
    final description = r.description?.trim();
    // Derived from real follower data rather than a backend flag.
    final isPopular = (r.followersCount ?? 0) >= 1000;
    final opens = RestaurantInfoPanel.hm(r.openingTime);
    final closes = RestaurantInfoPanel.hm(r.closingTime);

    // Round brand buttons for the links the restaurant has set (each
    // preceded by a 10px gap, so they can follow any leading button).
    // Social links the restaurant has set (brand logo + link).
    final socialLinks = [
      (SocialLinks.facebook(r.facebookUrl), AssetsName.facebook, 'Facebook'),
      (SocialLinks.tiktok(r.tiktokUrl), AssetsName.tiktok, 'TikTok'),
      (
        SocialLinks.telegram(r.telegramUsername),
        AssetsName.telegram,
        'Telegram',
      ),
    ].where((l) => l.$1 != null).map((l) => (l.$1!, l.$2, l.$3)).toList();

    // Visitor shortcuts: exact pin when we have one, else the address.
    final phone = r.phone?.trim();
    final address = r.address?.trim();
    final mapQuery = r.latitude != null && r.longitude != null
        ? '${r.latitude},${r.longitude}'
        : (address != null && address.isNotEmpty ? address : null);
    final Uri? directions = mapQuery == null
        ? null
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': mapQuery,
          });
    final Uri? call = phone == null || phone.isEmpty
        ? null
        : Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));

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

    void openMenu() => AppRouter.router.pushNamed(
      AppRoute.restaurantMenu.name,
      pathParameters: {'id': restaurantId},
    );

    return Scaffold(
      floatingActionButton: _BackToTop(
        visible: showTop.value,
        onTap: () => scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        ),
      ),
      body: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          ProfileCollapsingHeader(
            scrollController: scrollController,
            coverUrl: restaurant.coverPicture,
            avatarUrl: restaurant.profilePicture,
            name: restaurant.name,
            subtitle: restaurant.category?.name,
            // Slightly shorter than 16:9 so content starts higher.
            coverHeight: MediaQuery.sizeOf(context).width * 0.5,
            avatarSize: 86,
            coverRadius: 0,
            // Storefront badge on the logo: marks this as a restaurant at a
            // glance (people's avatars never have it).
            avatarBadge: const _StorefrontBadge(),
            onBack: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            actions: [
              ProfileCircleButton(
                icon: Icons.ios_share_rounded,
                dark: true,
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: [
                      '${r.name} on Khmer Cat',
                      if (r.category != null) r.category!.name,
                      if (r.menuUrl != null) 'Menu: ${r.menuUrl}',
                    ].join('\n'),
                    subject: r.name,
                  ),
                ),
              ),
              const Gap(14),
            ],
          ),
          SliverToBoxAdapter(
            child: _FadeSlideIn(
             child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                  const Gap(8),
                  // Category, open status, and badges.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Storefront chip = restaurant (people get a
                      // person "Personal" chip instead).
                      ProfileTypeChip(
                        isRestaurant: true,
                        label: r.category?.name,
                      ),
                      if (r.isOpen != null)
                        OpenStatusPill(
                          open: r.isOpen!,
                          detail: r.isOpen!
                              ? (closes == null ? null : 'until $closes')
                              : (opens == null ? null : 'opens $opens'),
                        ),
                      if (isPopular)
                        const _Pill(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Popular',
                          color: _orange,
                        ),
                      if (isOwner)
                        const _Pill(
                          icon: Icons.verified_user_rounded,
                          label: 'Your restaurant',
                          color: ProfileTheme.deepPurple,
                        ),
                    ],
                  ),
                  const Gap(10),
                  _StatsLine(restaurant: r),
                  if (description != null && description.isNotEmpty) ...[
                    const Gap(10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],
                  const Gap(16),

                  if (isOwner && !r.isPublished) ...[
                    const Gap(14),
                    UnpublishedBanner(restaurant: r),
                  ],
                  // ---- Action tiles: equal width, icon over label.
                  const Gap(16),
                  Row(
                    children: [
                      for (final (i, tile)
                          in (isOwner
                                  ? [
                                      ProfileActionTile(
                                        icon: Icons.videocam_rounded,
                                        label: 'Post video',
                                        primary: true,
                                        onTap: () => AppRouter.router.pushNamed(
                                          AppRoute.cameraRecord.name,
                                        ),
                                      ),
                                      ProfileActionTile(
                                        icon: Icons.edit_rounded,
                                        label: 'Edit',
                                        onTap: () => AppRouter.router.pushNamed(
                                          AppRoute.editRestaurant.name,
                                          pathParameters: {'id': restaurantId},
                                        ),
                                      ),
                                      ProfileActionTile(
                                        icon: Icons.menu_book_rounded,
                                        label: 'Menu',
                                        onTap: openMenu,
                                      ),
                                      ProfileActionTile(
                                        icon: Icons.swap_horiz_rounded,
                                        label: 'Switch',
                                        onTap: () =>
                                            showRestaurantSwitcherSheet(
                                              context,
                                            ),
                                      ),
                                    ]
                                  : [
                                      ProfileActionTile(
                                        icon: state.isFollowingLocally
                                            ? Icons.check_rounded
                                            : Icons.person_add_alt_1_rounded,
                                        label: state.isFollowingLocally
                                            ? 'Following'
                                            : 'Follow',
                                        primary: !state.isFollowingLocally,
                                        onTap: onFollow,
                                      ),
                                      ProfileActionTile(
                                        icon: Icons.menu_book_rounded,
                                        label: 'Menu',
                                        onTap: openMenu,
                                      ),
                                      if (directions != null)
                                        ProfileActionTile(
                                          icon: Icons.directions_rounded,
                                          label: 'Directions',
                                          onTap: () =>
                                              SocialLinks.open(directions),
                                        ),
                                      if (call != null)
                                        ProfileActionTile(
                                          icon: Icons.call_rounded,
                                          label: 'Call',
                                          onTap: () => SocialLinks.open(call),
                                        ),
                                    ])
                              .indexed) ...[
                        if (i > 0) const Gap(8),
                        Expanded(child: tile),
                      ],
                    ],
                  ),

                  // ---- Social strip
                  if (socialLinks.isNotEmpty) ...[
                    const Gap(12),
                    ProfileSocialStrip(links: socialLinks),
                  ],
                ],
              ),
             ),
            ),
          ),
          const SliverToBoxAdapter(child: Gap(8)),
          // Pinned under the app bar so the tabs stay reachable while
          // scrolling through a long grid.
          SliverPersistentHeader(
            pinned: true,
            delegate: FixedSliverHeaderDelegate(
              height: 62,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ProfileSegmentTabs(
              // The app's own icons, same as the owner's Profile tab.
              tabs: [
                ProfileSegmentTab(asset: AssetsName.feeds, label: 'Videos'),
                ProfileSegmentTab(asset: AssetsName.review, label: 'Reviews'),
                ProfileSegmentTab(asset: AssetsName.profileinfo, label: 'Info'),
              ],
              selected: tab.value,
              onChanged: (i) {
                tab.value = i;
                if (!visitedTabs.value.contains(i)) {
                  visitedTabs.value = {...visitedTabs.value, i};
                }
              },
              compact: true,
            ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Gap(6)),
          SliverToBoxAdapter(
            // Both grids stay alive once opened and are only shown/hidden,
            // so switching tabs doesn't refetch, flash a skeleton, or
            // cross-fade one grid over the other. A hidden grid takes no
            // space. Reviews loads the first time its tab is opened.
            child: Column(
              children: [
                _TabPane(
                  visible: tab.value == 0,
                  child: RestaurantVideosGrid(
                    restaurantId: restaurantId,
                    emptyTitle: 'No videos yet',
                    emptyMessage:
                        'Videos posted by this restaurant show up here.',
                  ),
                ),
                if (visitedTabs.value.contains(1))
                  _TabPane(
                    visible: tab.value == 1,
                    child: RestaurantVideosGrid(
                      restaurantId: restaurantId,
                      type: 'review',
                      emptyTitle: 'No reviews yet',
                      emptyMessage: 'Be the first to review this restaurant.',
                    ),
                  ),
                // Info: hours, service, contact, about. Owners also get
                // "Add …" links for anything missing.
                if (tab.value == 2)
                  RestaurantInfoPanel(
                    restaurant: r,
                    showSocial: false,
                    topPadding: 0,
                    onOpenMenu: openMenu,
                    onEdit: isOwner
                        ? () => AppRouter.router.pushNamed(
                            AppRoute.editRestaurant.name,
                            pathParameters: {'id': restaurantId},
                          )
                        : null,
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

/// ★ 3.5 (4 reviews) · 1 follower · 2 posts — one quiet line.
class _StatsLine extends StatelessWidget {
  final Restaurant restaurant;
  const _StatsLine({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    final strong = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      color: primary,
    );
    final soft = TextStyle(fontSize: 13.5, color: muted);
    final followers = r.followersCount ?? 0;
    String plural(int n, String word) =>
        '${_compact(n)} $word${n == 1 ? '' : 's'}';

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            // Filled gold once rated; an empty grey star until then.
            child: r.avgRating != null
                ? const Icon(Icons.star_rounded, size: 17, color: _gold)
                : Icon(Icons.star_border_rounded, size: 17, color: muted),
          ),
          const TextSpan(text: ' '),
          if (r.avgRating != null) ...[
            TextSpan(text: r.avgRating!.toStringAsFixed(1), style: strong),
            TextSpan(
              text: ' (${plural(r.reviewsCount, 'review')})',
              style: soft,
            ),
          ] else
            TextSpan(text: 'No reviews yet', style: soft),
          TextSpan(text: '  ·  ', style: soft),
          TextSpan(text: _compact(followers), style: strong),
          TextSpan(
            text: followers == 1 ? ' follower' : ' followers',
            style: soft,
          ),
          TextSpan(text: '  ·  ', style: soft),
          TextSpan(text: _compact(r.videosCount), style: strong),
          TextSpan(text: r.videosCount == 1 ? ' post' : ' posts', style: soft),
        ],
      ),
    );
  }
}

/// Keeps [child]'s state (and loaded data) while hidden; a hidden pane takes
/// no space. Shown panes fade in quickly.
class _TabPane extends StatelessWidget {
  final bool visible;
  final Widget child;
  const _TabPane({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      maintainState: true,
      // Same widget tree whether shown or hidden (no key change), so the
      // grid is never rebuilt from scratch; opacity eases 0 -> 1 on show.
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

/// Pink storefront badge on a restaurant's logo.
class _StorefrontBadge extends StatelessWidget {
  const _StorefrontBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: ProfileTheme.pinkPurple,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2.5,
        ),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

/// One-time fade + slight upward slide for the header content.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  const _FadeSlideIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

/// Small round button that appears after scrolling down.
class _BackToTop extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _BackToTop({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: IgnorePointer(
          ignoring: !visible,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: ProfileTheme.pinkPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ProfileTheme.purple.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
