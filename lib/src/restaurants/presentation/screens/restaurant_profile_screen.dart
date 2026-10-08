import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_shared_widgets.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/data/restaurant_profile_mock.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_info_panel.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_review_wall.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_videos_grid.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/unpublished_banner.dart';
import 'package:share_plus/share_plus.dart';

const _orange = Color(0xffFF8A3D);
const _gold = Color(0xffFFC83D);
const _crimson = Color(0xffB0125A);

/// Vertical gap between the profile's blocks.
const _section = 20.0;

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
      return const Scaffold(body: _ProfileSkeleton());
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
    final hours = opens != null && closes != null
        ? '${_h12(opens)} – ${_h12(closes)}, '
              '${r.openDaysLabel ?? RestaurantProfileMock.openDaysLabel}'
        : null;

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
    final deliveryLinks = r.deliveryLinks.isNotEmpty
        ? r.deliveryLinks
        : RestaurantProfileMock.deliveryLinks;

    // Visitor shortcuts: exact pin when we have one, else the address.
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
    // "1.2 km away": the API's figure, else measured from the device.
    final meters = r.distanceKm != null
        ? r.distanceKm! * 1000
        : distanceTo(ref.watch(locationProvider), r);

    final Widget? hoursRow = hours != null || r.isOpen != null
        ? _DetailRow(
            iconAsset: AssetsName.lcClock,
            trailing: r.isOpen == null ? null : OpenStatusPill(open: r.isOpen!),
            child: Text(hours ?? '', style: _detailStyle(context)),
          )
        : null;
    final Widget? addressRow = address != null && address.isNotEmpty
        ? _DetailRow(
            iconAsset: AssetsName.lcPin,
            trailing: directions == null
                ? null
                : _DirectionsButton(onTap: () => SocialLinks.open(directions)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address, style: _detailStyle(context)),
                if (meters != null) ...[
                  const Gap(2),
                  Text(
                    '${formatDistance(meters)} away',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: ProfileTheme.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          )
        : null;

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

    Future<void> onWriteReview() async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to write a review',
      )) {
        return;
      }
      AppService.showToast('Writing reviews is coming soon.');
    }

    void openEdit() => AppRouter.router.pushNamed(
      AppRoute.editRestaurant.name,
      pathParameters: {'id': restaurantId},
    );

    void openMenu() => AppRouter.router.pushNamed(
      AppRoute.restaurantMenu.name,
      pathParameters: {'id': restaurantId},
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Scaffold(
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
              coverHeight: MediaQuery.sizeOf(context).width * 0.45,
              avatarSize: 86,
              coverRadius: 0,
              lightControls: true,
              // Name + rating beside the avatar. Visitors also get the
              // Follow pill under the avatar and a View menu button.
              belowFoldHeight: 54,
              belowFoldAction: SizedBox(
                // Screen width minus the side margins.
                width: MediaQuery.sizeOf(context).width - 40,
                height: 54,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      // Right of the avatar (98px with its ring) + a gap.
                      left: 110,
                      right: 56,
                      top: 0,
                      child: _HeaderTitle(restaurant: r),
                    ),
                    // Centered under the avatar, overlapping its edge: Edit
                    // for the team, Follow for visitors.
                    Positioned(
                      left: 0,
                      width: 98,
                      top: 25,
                      child: Center(
                        child: isOwner
                            ? _AvatarPill(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: openEdit,
                              )
                            : _AvatarPill(
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
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _MenuCircleButton(onTap: openMenu),
                    ),
                  ],
                ),
              ),
              coverAction: isOwner
                  ? ProfileChangeCoverButton(onTap: openEdit)
                  : null,
              onBack: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              actions: [
                ProfileCircleButton(
                  icon: Icons.ios_share_rounded,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FadeSlideIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPopular) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (isPopular)
                                  const _Pill(
                                    icon: Icons.local_fire_department_rounded,
                                    label: 'Popular',
                                    color: _orange,
                                  ),
                              ],
                            ),
                          ],
                          if (description != null &&
                              description.isNotEmpty) ...[
                            const Gap(12),
                            _ExpandableText(
                              text: description,
                              style: TextStyle(
                                fontSize: 15.5,
                                height: 1.45,
                                color: ProfileTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(_section),
                    _FadeSlideIn(
                      index: 1,
                      child: _StatsRow(
                        restaurant: r,
                        following:
                            r.followingCount ??
                            RestaurantProfileMock.followingCount,
                      ),
                    ),
                    if (isOwner && !r.isPublished) ...[
                      const Gap(_section),
                      UnpublishedBanner(restaurant: r),
                    ],
                    // Visitors see the hours first, then the address; the
                    // team sees the address first, and a prompt to add hours.
                    if (!isOwner && hoursRow != null) ...[
                      const Gap(_section),
                      _FadeSlideIn(index: 3, child: hoursRow),
                    ],
                    if (addressRow != null) ...[
                      const Gap(_section),
                      _FadeSlideIn(index: 4, child: addressRow),
                    ],
                    if (isOwner) ...[
                      const Gap(_section),
                      _FadeSlideIn(
                        index: 5,
                        child:
                            hoursRow ??
                            _DetailRow(
                              iconAsset: AssetsName.lcClock,
                              trailing: _AddLink(onTap: openEdit),
                              child: Text(
                                'Opening hours not added yet',
                                style: _detailStyle(context).copyWith(
                                  color: ProfileTheme.textSecondary(context),
                                ),
                              ),
                            ),
                      ),
                    ],
                    if (deliveryLinks.isNotEmpty || socialLinks.isNotEmpty) ...[
                      const Gap(_section),
                      _FadeSlideIn(
                        index: 6,
                        child: _LinksPanel(
                          delivery: [
                            for (final d in deliveryLinks)
                              _ChipLink(
                                label: d.name,
                                initial: d.name,
                                onTap: () => SocialLinks.open(Uri.parse(d.url)),
                              ),
                          ],
                          social: [
                            for (final l in socialLinks)
                              _ChipLink(
                                label: l.$3,
                                asset: l.$2,
                                onTap: () => SocialLinks.open(l.$1),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                    tabs: [
                      ProfileUnderlineTab(
                        asset: AssetsName.feeds,
                        label: 'Videos',
                      ),
                      ProfileUnderlineTab(
                        asset: AssetsName.review,
                        label: 'Vlogs',
                      ),
                      ProfileUnderlineTab(
                        asset: AssetsName.comment,
                        label: 'Reviews',
                      ),
                    ],
                    selected: tab.value,
                    onChanged: (i) {
                      tab.value = i;
                      if (!visitedTabs.value.contains(i)) {
                        visitedTabs.value = {...visitedTabs.value, i};
                      }
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(16)),
            SliverToBoxAdapter(
              // The video grids stay alive once opened and are only shown or
              // hidden, so switching tabs doesn't refetch or flash a skeleton.
              // A hidden grid takes no space.
              child: Column(
                children: [
                  _TabPane(
                    visible: tab.value == 0,
                    child: RestaurantVideosGrid(
                      restaurantId: restaurantId,
                      emptyTitle: 'No videos yet',
                      emptyMessage:
                          'Videos posted by this restaurant show up here.',
                      pillLabel: (v) =>
                          '${formatCount(v.likesCount)} '
                          'like${v.likesCount == 1 ? '' : 's'}',
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
                        pillLabel: (v) => v.user.name,
                      ),
                    ),
                  if (tab.value == 2)
                    RestaurantReviewWall(
                      summary: RestaurantProfileMock.reviewSummary,
                      reviews: RestaurantProfileMock.reviews,
                      onWrite: onWriteReview,
                    ),
                ],
              ),
            ),
            // Room for the back-to-top button and the gesture bar.
            SliverToBoxAdapter(
              child: Gap(24 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text clamped to [maxLines] with an inline "… more" that expands it.
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _ExpandableText({required this.text, required this.style});

  static const maxLines = 3;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final more = widget.style.copyWith(
      fontWeight: FontWeight.w700,
      color: _crimson,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        TextPainter layout(String t, {bool withMore = false}) => TextPainter(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: t),
              if (withMore) TextSpan(text: '… more', style: more),
            ],
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: _ExpandableText.maxLines,
        )..layout(maxWidth: c.maxWidth);

        if (_expanded || !layout(widget.text).didExceedMaxLines) {
          return Text(widget.text, style: widget.style);
        }
        // Longest prefix that still fits, with "… more", in maxLines.
        var lo = 0, hi = widget.text.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          final fits = !layout(
            widget.text.substring(0, mid).trimRight(),
            withMore: true,
          ).didExceedMaxLines;
          if (fits) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }
        return GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text.rich(
            TextSpan(
              style: widget.style,
              children: [
                TextSpan(text: widget.text.substring(0, lo).trimRight()),
                TextSpan(text: '… more', style: more),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Name and rating line beside the avatar.
class _HeaderTitle extends StatelessWidget {
  final Restaurant restaurant;
  const _HeaderTitle({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        const Gap(6),
        _RatingCategoryLine(
          rating: restaurant.avgRating,
          category: restaurant.category?.name,
        ),
      ],
    );
  }
}

/// "+ Add" link in the accent color.
class _AddLink extends StatelessWidget {
  final VoidCallback onTap;
  const _AddLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '+ Add',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: _crimson,
          ),
        ),
      ),
    );
  }
}

/// Soft grey panel holding the delivery and social chips.
class _LinksPanel extends StatelessWidget {
  final List<_ChipLink> delivery;
  final List<_ChipLink> social;
  const _LinksPanel({required this.delivery, required this.social});

  @override
  Widget build(BuildContext context) {
    Widget group(String title, List<_ChipLink> chips) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        const Gap(10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileTheme.textSecondary(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (delivery.isNotEmpty) group('Order delivery', delivery),
          if (delivery.isNotEmpty && social.isNotEmpty) const Gap(16),
          if (social.isNotEmpty) group('Follow us', social),
        ],
      ),
    );
  }
}

/// White pill: a small circle with a logo or initial, then the name.
class _ChipLink extends StatelessWidget {
  final String label;
  final String? asset;
  final String? initial;
  final VoidCallback onTap;
  const _ChipLink({
    required this.label,
    required this.onTap,
    this.asset,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProfileTheme.textSecondary(
                  context,
                ).withValues(alpha: 0.12),
              ),
              child: asset != null
                  ? Image.asset(asset!, width: 16, height: 16)
                  : Text(
                      (initial ?? '?').characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
            ),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "7:00" / "21:00" → "7:00 AM" / "9:00 PM".
String _h12(String hm) {
  final parts = hm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m ${h < 12 ? 'AM' : 'PM'}';
}

TextStyle _detailStyle(BuildContext context) => TextStyle(
  fontSize: 15.5,
  height: 1.4,
  fontWeight: FontWeight.w500,
  color: ProfileTheme.textPrimary(context),
);

/// "★ 4.8 · Khmer Food" — either part may be missing.
class _RatingCategoryLine extends StatelessWidget {
  final double? rating;
  final String? category;
  const _RatingCategoryLine({required this.rating, required this.category});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rating != null) ...[
          const Icon(Icons.star_rounded, size: 17, color: _gold),
          const Gap(4),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
        ],
        if (rating != null && category != null)
          Text('  ·  ', style: TextStyle(fontSize: 14.5, color: muted)),
        if (category != null)
          Text(category!, style: TextStyle(fontSize: 14.5, color: muted)),
      ],
    );
  }
}

/// Small pill ("+ Follow", "Edit") that straddles the avatar's bottom edge:
/// gradient when [filled], otherwise outlined.
class _AvatarPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _AvatarPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ProfileTheme.ink : ProfileTheme.textPrimary(context);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xffF0A6CE), Color(0xffA9C1F5)],
                )
              : null,
          color: filled ? null : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: scheme.onSurface.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const Gap(3),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round outlined button that opens the menu.
class _MenuCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'View menu',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.14)),
          ),
          child: Icon(
            Icons.description_outlined,
            size: 20,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

/// Lucide icon in the left gutter, content, optional trailing widget.
class _DetailRow extends StatelessWidget {
  final String iconAsset;
  final Widget child;
  final Widget? trailing;
  const _DetailRow({
    required this.iconAsset,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          child: Image.asset(
            iconAsset,
            width: 20,
            height: 20,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        Expanded(child: child),
        if (trailing != null) ...[const Gap(10), trailing!],
      ],
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DirectionsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xffB0125A).withValues(alpha: 0.08),
        ),
        child: const Center(
          child: Icon(
            Icons.directions_outlined,
            size: 22,
            color: Color(0xffB0125A),
          ),
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
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(100),
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

/// Posts · Reviews · Followers · Following on a soft pink→lavender card.
/// Numbers count up on first show and glide to new values (e.g. after
/// following).
class _StatsRow extends StatelessWidget {
  final Restaurant restaurant;
  final int following;
  const _StatsRow({required this.restaurant, required this.following});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final followers = r.followersCount ?? 0;

    Widget stat(int value, String label) => Expanded(
      child: _Stat(
        value: value.toDouble(),
        format: (v) => _compact(v.round()),
        label: label,
      ),
    );

    // Thin pink → purple → blue line between the stats.
    const divider = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ProfileTheme.pink, ProfileTheme.purple, ProfileTheme.blue],
        ),
      ),
      child: SizedBox(width: 1.5, height: 34),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          stat(r.videosCount, r.videosCount == 1 ? 'Post' : 'Posts'),
          divider,
          stat(r.reviewsCount, r.reviewsCount == 1 ? 'Review' : 'Reviews'),
          divider,
          stat(followers, followers == 1 ? 'Follower' : 'Followers'),
          divider,
          stat(following, 'Following'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final String label;
  const _Stat({required this.value, required this.format, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              // begin: 0 counts up once; later changes glide from the
              // current value.
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                format(v),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const Gap(2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
      ],
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

/// One-time fade + slight upward slide for the header content; [index]
/// staggers blocks so they cascade in top to bottom.
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeSlideIn({required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = index * 70;
    final total = 460 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Placeholder layout while the restaurant loads: cover, avatar and a few
/// bars in the page's real positions, gently pulsing.
class _ProfileSkeleton extends HookWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      ctrl.repeat(reverse: true);
      return null;
    }, [ctrl]);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;

    Widget bar(double w, double h, {double r = 10}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: ProfileTheme.purple.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return FadeTransition(
      opacity: Tween(
        begin: 0.55,
        end: 1.0,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              bar(width, width * 0.5, r: 28),
              Positioned(
                left: 20,
                bottom: -46,
                child: Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: bar(88, 88, r: 44),
                ),
              ),
            ],
          ),
          const Gap(64),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width * 0.55, 26),
                const Gap(12),
                Row(
                  children: [
                    bar(96, 28, r: 100),
                    const Gap(8),
                    bar(80, 28, r: 100),
                  ],
                ),
                const Gap(22),
                bar(width - 32, 40),
                const Gap(22),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const Gap(8),
                      Expanded(child: bar(double.infinity, 60, r: 18)),
                    ],
                  ],
                ),
                const Gap(22),
                bar(width - 32, 44, r: 16),
              ],
            ),
          ),
        ],
      ),
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
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Container(
              width: 46,
              height: 46,
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
