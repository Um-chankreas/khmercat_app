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
    final expandedHeaderHeight =
        coverHeight + CoverAvatarHeader.contentGap(avatarSize);
    final titleFadeDistance =
        expandedHeaderHeight - statusBarHeight - pinnedHeaderHeight;

    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, _) {
        final opacity = _pinnedTitleOpacity(
          scrollController,
          titleFadeDistance,
        );
        // This header's backdrop should blend into the page itself, not
        // read as a raised card — so it uses the scaffold's background
        // color, not ProfileTheme.surface (which is deliberately a
        // slightly lighter tone, reserved for actual cards like
        // ProfileCard/ProfileTabBar).
        final pageBackground = Theme.of(context).scaffoldBackgroundColor;

        return SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          expandedHeight: expandedHeaderHeight - statusBarHeight,
          toolbarHeight: pinnedHeaderHeight,
          // Solid page color underneath at all times: the cover + avatar
          // fade out over it as you scroll (see below), so nothing grey or
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
                      dark: true,
                      onTap: onBack!,
                    ),
                  ),
                ),
          // Our own flexible space (not FlexibleSpaceBar, whose built-in
          // fade let the bar's color bleed through as a grey band): the
          // full header, clipped to the bar's current height and faded out
          // in step with the pinned title fading in — so the big avatar
          // never slides over the title.
          flexibleSpace: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: expandedHeaderHeight,
              maxHeight: expandedHeaderHeight,
              child: IgnorePointer(
                ignoring: opacity >= 1,
                child: Opacity(
                  opacity: (1 - opacity * 1.15).clamp(0.0, 1.0),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: _PinnedTitle(
            avatarUrl: avatarUrl,
            name: name,
            subtitle: subtitle,
            opacity: opacity,
          ),
          actions: actions,
        );
      },
    );
  }
}

class _PinnedTitle extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? subtitle;
  final double opacity;

  const _PinnedTitle({
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    required this.opacity,
  });

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
        ),
      ),
    );
  }
}
