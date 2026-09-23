// lib/src/profile/presentation/screens/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
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
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/profile/domain/my_profile_summary.dart';
import 'package:khmer_cat_app/src/profile/presentation/viewmodel/my_profile_summary_controller.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_posts_grid.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/share_profile.dart';

class ProfileTab extends HookConsumerWidget {
  const ProfileTab({super.key});

  /// Cover photo width:height ratio — 16:9, so its height tracks the
  /// screen's width instead of being a fixed pixel value.
  static const double _coverAspectRatio = 16 / 9;
  static const double _avatarSize = 84;

  /// Tall enough for a name + bio subtitle, not just a single line.
  static const double _pinnedHeaderHeight = 60;

  // Tighter than [CoverAvatarHeader.contentGap]'s shared default (used
  // as-is by the read-only user/restaurant profiles) — just enough to
  // clear the overlapping avatar (which hangs (avatarSize + 12) / 2 below
  // the fold, per [CoverAvatarHeader]'s own avatar offset) plus a flat 8px
  // gap before the name.
  static const double _contentGap = (_avatarSize + 12) / 2 + 8;

  static final double _tabBarHeight = ProfileTabBar.heightFor(withLabels: true);

  /// 0 at the top of the scroll, 1 once scrolled past [titleFadeDistance].
  static double _pinnedTitleOpacity(
    ScrollController controller,
    double titleFadeDistance,
  ) {
    if (!controller.hasClients) return 0;
    return controller.offset.clamp(0.0, titleFadeDistance) /
        titleFadeDistance;
  }

  static final _icons = [
    AssetsName.feeds,
    AssetsName.heartout,
    AssetsName.delete,
    AssetsName.profileinfo,
  ];
  static const _labels = ['Videos', 'Favorite', 'Delete', 'Info'];
  static const _videos = 0;
  static const _favorite = 1;
  static const _info = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final selected = useState(_videos);
    final scrollController = useScrollController();

    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      return const _GuestProfilePrompt();
    }

    final user = authState.user!;
    final l = AppLocalizations.of(context);
    final summary = ref.watch(myProfileSummaryControllerProvider(user.id));
    final surface = ProfileTheme.surface(context);

    final coverHeight = MediaQuery.sizeOf(context).width / _coverAspectRatio;
    final expandedHeaderHeight = coverHeight + _contentGap;
    final titleFadeDistance = expandedHeaderHeight - _pinnedHeaderHeight;

    return ColoredBox(
      color: surface,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Expands to the cover photo (via `flexibleSpace`) and collapses
          // to a plain pinned toolbar as the user scrolls, so the photo
          // shows full-bleed behind the status bar at rest instead of
          // sitting below a separate opaque strip. The collapse itself is
          // Flutter's own well-tested `flexibleSpace` mechanics — only the
          // *background widget* is ours; title/backgroundColor opacity are
          // still driven entirely by our own ScrollController math below; we
          // deliberately never read `FlexibleSpaceBarSettings` for them,
          // since that's the specific signal the old, reverted version of
          // this file found broken for a pinned-without-floating app bar
          // (see profile_pinned_header.dart).
          ListenableBuilder(
            listenable: scrollController,
            builder: (context, _) {
              final opacity = _pinnedTitleOpacity(
                scrollController,
                titleFadeDistance,
              );
              return SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: expandedHeaderHeight,
                toolbarHeight: _pinnedHeaderHeight,
                // Transparent over the cover photo at rest, solidifying to
                // [surface] in step with the pinned title fading in — so the
                // bar only opaques once it actually has pinned content (the
                // title) to show over the now-faded-out photo.
                backgroundColor: Color.lerp(Colors.transparent, surface, opacity),
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                centerTitle: false,
                titleSpacing: context.sc(16),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Align(
                    alignment: Alignment.topCenter,
                    // Ignore taps on the cover/avatar edit buttons once
                    // they've faded out with the rest of the photo — they'd
                    // otherwise sit, invisible, underneath the pinned title.
                    child: IgnorePointer(
                      ignoring: opacity >= 1,
                      child: CoverAvatarHeader(
                        coverUrl: user.coverPicture,
                        avatarUrl: user.profilePicture,
                        name: user.name,
                        coverHeight: coverHeight,
                        avatarSize: _avatarSize,
                        coverRadius: 0,
                        coverTint: ProfileTheme.coverMoodTint,
                        topLeft: Text(
                          '@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        coverAction: ProfileEditIconButton(
                          icon: Icons.photo_camera_rounded,
                          size: 34,
                          onTap: () => changeProfileImage(
                            context,
                            ref,
                            ProfileImageKind.cover,
                          ),
                        ),
                        avatarBadge: ProfileEditIconButton(
                          icon: Icons.edit_rounded,
                          size: 26,
                          ringed: true,
                          onTap: () => changeProfileImage(
                            context,
                            ref,
                            ProfileImageKind.avatar,
                          ),
                        ),
                        belowFoldAction: ProfileEditIconButton(
                          icon: Icons.edit_rounded,
                          onTap: () => AppRouter.router.pushNamed(
                            AppRoute.editProfile.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: _PinnedHeaderTitle(user: user, opacity: opacity),
                actions: [
                  ProfileCircleButton(
                    iconAsset: AssetsName.share,
                    dark: true,
                    onTap: () => shareProfile(user),
                  ),
                  const Gap(8),
                  ProfileCircleButton(
                    iconAsset: AssetsName.settings,
                    dark: true,
                    onTap: () =>
                        AppRouter.router.pushNamed(AppRoute.settings.name),
                  ),
                ],
              );
            },
          ),
          // The name/username/bio/stats block — an ordinary sliver, sized by
          // its own content, that scrolls up under the app bar above it as
          // the user scrolls. Starts right where the app bar's expanded
          // height ends, so it lines up with the cover+avatar above without
          // needing its own top gap.
          SliverToBoxAdapter(
            child: ColoredBox(
              color: surface,
              child: _ProfileInfo(user: user, summary: summary),
            ),
          ),
          // Pinned: the tabs, always visible right under the header above.
          SliverPersistentHeader(
            pinned: true,
            delegate: FixedSliverHeaderDelegate(
              height: _tabBarHeight,
              child: Container(
                color: surface,
                alignment: Alignment.center,
                child: ProfileTabBar(
                  icons: _icons,
                  labels: _labels,
                  selectedIndex: selected.value,
                  onChanged: (i) => selected.value = i,
                ),
              ),
            ),
          ),

          // ---- Only this scrolls under the pinned pieces above.
          SliverToBoxAdapter(
            child: ProfileTabBody(
              index: selected.value,
              child: selected.value == _info
                  ? _AboutPanel(user: user)
                  : ProfilePostsGrid(
                      // Own posts / favorites / deleted, same endpoint with
                      // a different flag.
                      userId: user.id,
                      flag: switch (selected.value) {
                        _favorite => 'favorite',
                        _videos => null,
                        _ => 'deleted',
                      },
                      emptyAsset: _icons[selected.value],
                      emptyMessage: switch (selected.value) {
                        _videos => l.emptyPosts,
                        _favorite => l.emptyFavorites,
                        _ => l.emptyTrash,
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================

/// The pinned replacement for the expanded header: small avatar + name +
/// bio, laid out as the [SliverAppBar.title] — the same toolbar layer
/// `actions` (the menu button) lives in, so it's genuinely always there once
/// faded in, at a fixed height, never clipped by the collapsing background.
class _PinnedHeaderTitle extends StatelessWidget {
  final User user;
  final double opacity;

  const _PinnedHeaderTitle({required this.user, required this.opacity});

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
                imageUrl: user.profilePicture,
                name: user.name,
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
                    user.name,
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
                    (user.bio?.isNotEmpty ?? false)
                        ? user.bio!
                        : '@${user.username}',
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

class _ProfileInfo extends StatelessWidget {
  final User user;
  final MyProfileSummary? summary;

  const _ProfileInfo({required this.user, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bio = user.bio;
    final hasBio = bio != null && bio.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NOTE: the design has a blue verified badge after the name, but
          // there's no `is_verified` flag on the user yet. Add an
          // `Icon(Icons.verified)` here once the backend returns one —
          // showing it unconditionally would misrepresent every account.
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          const Gap(2),
          Text(
            '@${user.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ProfileTheme.deepPurple,
            ),
          ),
          if (hasBio) ...[
            const Gap(6),
            Text(
              bio,
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
          const Gap(14),
          ProfileStatsRow(
            stats: [
              ProfileStat(
                value: summary?.followingCount ?? 0,
                label: l.statFollowing,
                icon: Icons.person_add_alt_1_rounded,
              ),
              ProfileStat(
                value: summary?.followersCount ?? 0,
                label: l.statFollowers,
                icon: Icons.people_alt_rounded,
              ),
              ProfileStat(
                value: summary?.postsCount ?? 0,
                label: l.statPosts,
                icon: Icons.grid_view_rounded,
              ),
              ProfileStat(
                value: summary?.likesCount ?? 0,
                label: l.statLikes,
                icon: Icons.favorite_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  final User user;
  const _AboutPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                ProfileInfoTile(
                  icon: Icons.person_rounded,
                  label: l.aboutName,
                  value: user.name,
                  color: ProfileTheme.pink,
                ),
                ProfileInfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: l.aboutUsername,
                  value: '@${user.username}',
                  color: ProfileTheme.purple,
                ),
                ProfileInfoTile(
                  icon: Icons.mail_rounded,
                  label: l.aboutEmail,
                  value: user.email,
                  color: ProfileTheme.blue,
                ),
                if (user.bio?.isNotEmpty == true)
                  ProfileInfoTile(
                    icon: Icons.info_rounded,
                    label: l.aboutBio,
                    value: user.bio!,
                    color: ProfileTheme.pink,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================

class _GuestProfilePrompt extends StatelessWidget {
  const _GuestProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ProfileTheme.surface(context),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProfileEmptyTabBody(
                  icon: Icons.person_outline_rounded,
                  title: 'Sign in to view your profile',
                  message:
                      'Create an account to upload, like, comment, and follow.',
                ),
                ProfileGradientButton(
                  text: 'Sign in',
                  icon: Icons.login_rounded,
                  onTap: () => AppRouter.router.pushNamed(AppRoute.login.name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
