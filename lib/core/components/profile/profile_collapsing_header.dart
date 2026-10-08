import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Collapsing cover-photo [SliverAppBar] that solidifies into a pinned
/// toolbar showing a small avatar + name once scrolled past the fold — the
/// same header behavior as the signed-in user's own profile tab
/// ([ProfileTab]), reused here for read-only user/restaurant profiles. Place
/// as the first sliver in a [CustomScrollView] driven by [scrollController].
class ProfileCollapsingHeader extends StatelessWidget {
  final ScrollController scrollController;
  final String? coverUrl;
  final String? avatarUrl;
  final String name;

  /// Shown under the name in the pinned title once collapsed (e.g.
  /// "@username" or a category label) — omit for none.
  final String? subtitle;
  final VoidCallback? onBack;

  /// Extra buttons in the top-right corner, always visible (e.g. share).
  final List<Widget> actions;
  final double coverHeight;
  final double avatarSize;
  final double coverRadius;
  final Gradient? coverTint;

  /// Small badge on the avatar (e.g. a storefront for restaurants).
  final Widget? avatarBadge;

  /// Buttons level with the avatar, right-aligned (e.g. Follow / View menu).
  final Widget? belowFoldAction;

  /// Button on the cover photo, bottom-right (e.g. "Change cover").
  final Widget? coverAction;

  /// Centers the avatar under the cover.
  final bool centerAvatar;

  /// Height of [belowFoldAction].
  final double belowFoldHeight;

  /// White circle buttons (as on a plain cover) instead of dark glass.
  final bool lightControls;

  /// Height of the toolbar row once pinned — tall enough for avatar + two
  /// lines of text without clipping.
  static const double pinnedHeaderHeight = 60;

  const ProfileCollapsingHeader({
    required this.scrollController,
    required this.name,
    this.coverUrl,
    this.avatarUrl,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.coverHeight = 200,
    this.avatarSize = 104,
    this.coverRadius = 28,
    this.coverTint,
    this.avatarBadge,
    this.belowFoldAction,
    this.coverAction,
    this.centerAvatar = false,
    this.belowFoldHeight = CoverAvatarHeader.actionHeight,
    this.lightControls = false,
    super.key,
  });

  /// 0 at the top of the scroll, 1 once scrolled past [fadeDistance].
  static double _pinnedTitleOpacity(
    ScrollController controller,
    double fadeDistance,
  ) {
    if (!controller.hasClients) return 0;
    return controller.offset.clamp(0.0, fadeDistance) / fadeDistance;
  }

  @override
  Widget build(BuildContext context) {
    // See the identical comment in `ProfileTab` — `SliverAppBar` (with the
    // default `primary: true`) silently adds MediaQuery's top padding (the
    // status bar) on top of whatever `expandedHeight` it's given, so we
    // subtract it back out here to land on the intended total height.
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final gap = CoverAvatarHeader.contentGap(avatarSize);
    final expandedHeaderHeight =
        coverHeight +
        (belowFoldAction != null &&
                CoverAvatarHeader.belowFoldExtent(belowFoldHeight) > gap
            ? CoverAvatarHeader.belowFoldExtent(belowFoldHeight)
            : gap);
    final titleFadeDistance =
        expandedHeaderHeight - statusBarHeight - pinnedHeaderHeight;

    // This header's backdrop should blend into the page itself, not read
    // as a raised card — so it uses the scaffold's background color, not
    // ProfileTheme.surface (which is deliberately a slightly lighter tone,
    // reserved for actual cards like ProfileCard/ProfileTabBar).
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;

    // The bar, cover and avatar are built once; only the two _ScrollFade
    // wrappers listen to the scroll controller, so scrolling repaints an
    // opacity instead of rebuilding the whole header every frame.
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeaderHeight - statusBarHeight,
      toolbarHeight: pinnedHeaderHeight,
      // Solid page color underneath at all times: the cover + avatar fade
      // out over it as you scroll (see below), so nothing grey or
      // half-transparent ever shows through mid-collapse.
      backgroundColor: pageBackground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      leading: onBack == null
          ? null
          : Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: ProfileCircleButton(
                  icon: Icons.arrow_back_rounded,
                  dark: !lightControls,
                  onTap: onBack!,
                ),
              ),
            ),
      // Our own flexible space (not FlexibleSpaceBar, whose built-in fade
      // let the bar's color bleed through as a grey band): the full header,
      // clipped to the bar's current height and faded out in step with the
      // pinned title fading in — so the big avatar never slides over the
      // title.
      flexibleSpace: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: expandedHeaderHeight,
          maxHeight: expandedHeaderHeight,
          child: _ScrollFade(
            controller: scrollController,
            distance: titleFadeDistance,
            fadeOut: true,
            child: RepaintBoundary(
              child: Align(
                alignment: Alignment.topCenter,
                child: CoverAvatarHeader(
                  coverUrl: coverUrl,
                  avatarUrl: avatarUrl,
                  name: name,
                  coverHeight: coverHeight,
                  avatarSize: avatarSize,
                  coverRadius: coverRadius,
                  coverTint: coverTint,
                  avatarBadge: avatarBadge,
                  belowFoldAction: belowFoldAction,
                  coverAction: coverAction,
                  centerAvatar: centerAvatar,
                  belowFoldHeight: belowFoldHeight,
                ),
              ),
            ),
          ),
        ),
      ),
      title: _ScrollFade(
        controller: scrollController,
        distance: titleFadeDistance,
        fadeOut: false,
        child: _PinnedTitle(
          avatarUrl: avatarUrl,
          name: name,
          subtitle: subtitle,
        ),
      ),
      actions: actions,
    );
  }
}

/// Fades [child] with the scroll: out ([fadeOut]) as the header collapses,
/// or in for the pinned title. Only this rebuilds on scroll; [child] is
/// passed through untouched. Taps are ignored while mostly invisible.
class _ScrollFade extends StatelessWidget {
  final ScrollController controller;
  final double distance;
  final bool fadeOut;
  final Widget child;
  const _ScrollFade({
    required this.controller,
    required this.distance,
    required this.fadeOut,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      child: child,
      builder: (context, child) {
        final t = ProfileCollapsingHeader._pinnedTitleOpacity(
          controller,
          distance,
        );
        final opacity = fadeOut ? (1 - t * 1.15).clamp(0.0, 1.0) : t;
        return IgnorePointer(
          ignoring: fadeOut ? t >= 1 : t < 0.5,
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}

class _PinnedTitle extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? subtitle;

  const _PinnedTitle({
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: ImageUserCircleProfile(
            imageUrl: avatarUrl,
            name: name,
            size: 32,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ProfileTheme.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
