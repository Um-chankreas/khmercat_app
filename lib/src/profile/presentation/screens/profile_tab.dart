// lib/src/profile/presentation/screens/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/profile_qr_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_pinned_header.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_shared_widgets.dart'
    hide ProfileGradientButton;
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/people/presentation/people_list_screen.dart';
import 'package:khmer_cat_app/src/profile/domain/my_profile_summary.dart';
import 'package:khmer_cat_app/src/profile/presentation/viewmodel/my_profile_summary_controller.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_posts_grid.dart';

/// The signed-in user's own profile (the Profile tab when not acting as a
/// restaurant): cover with settings and change-cover buttons; the avatar
/// with an Edit pill, name and @handle beside it, and a QR button; bio;
/// phone / email and the social links; Posts · Likes · Followers ·
/// Following; then Videos / Favorites grids.
class ProfileTab extends HookConsumerWidget {
  const ProfileTab({super.key});

  static const double _avatarSize = 86;
  static const _videos = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final tab = useState(_videos);
    // Grids are kept once opened, so switching back doesn't reload them.
    final visited = useState<Set<int>>({_videos});
    final scrollController = useScrollController();

    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      return const _GuestProfilePrompt();
    }

    final user = authState.user!;
    final l = AppLocalizations.of(context);
    final summary = ref.watch(myProfileSummaryControllerProvider(user.id));
    final width = MediaQuery.sizeOf(context).width;
    final bio = (summary?.bio ?? user.bio)?.trim();

    void openEdit() => AppRouter.router.pushNamed(AppRoute.editProfile.name);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            ProfileCollapsingHeader(
              scrollController: scrollController,
              coverUrl: user.coverPicture,
              avatarUrl: user.profilePicture,
              name: user.name,
              subtitle: '@${user.username}',
              coverHeight: width * 0.45,
              avatarSize: _avatarSize,
              coverRadius: 0,
              lightControls: true,
              topLeft: ProfileChangeCoverButton(
                size: 32,
                onTap: () =>
                    changeProfileImage(context, ref, ProfileImageKind.cover),
              ),
              actions: [
                ProfileCircleButton(
                  iconAsset: AssetsName.menu,
                  iconSize: 16,
                  padding: 8,
                  onTap: () =>
                      AppRouter.router.pushNamed(AppRoute.settings.name),
                ),
                const Gap(6),
              ],
              // Name + @handle beside the avatar, the Edit pill under it,
              // and the QR button on the right.
              belowFoldHeight: 53,
              belowFoldAction: SizedBox(
                // Screen width minus the side margins.
                width: width - 40,
                height: 53,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      // Right of the avatar (98px with its ring) + a gap.
                      left: 110,
                      right: 50,
                      top: 0,
                      child: _NameBlock(user: user),
                    ),
                    Positioned(
                      left: 0,
                      width: 98,
                      top: 25,
                      child: Center(child: _EditPill(onTap: openEdit)),
                    ),
                    Positioned(
                      // 14px from the screen edge (this row's edge is 20px
                      // in), in line with the settings button above.
                      right: -6,
                      top: 0,
                      child: ProfileRaisedCircleButton(
                        asset: AssetsName.qrCode,
                        tooltip: 'My QR code',
                        onTap: () => openProfileQr(
                          context,
                          name: user.name,
                          username: user.username,
                          avatarUrl: user.profilePicture,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                // The header already leaves a gap under the Edit pill.
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProfileDetails(user: user, bio: bio, summary: summary),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(14)),
            // Pinned under the collapsed header so the tabs stay reachable
            // while scrolling through a long grid.
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
                        icon: Icons.play_circle_outline_rounded,
                        label: l.profileTabVideos,
                      ),
                      ProfileUnderlineTab(
                        icon: Icons.favorite_border_rounded,
                        label: l.profileTabFavorites,
                      ),
                    ],
                    selected: tab.value,
                    onChanged: (i) {
                      tab.value = i;
                      visited.value = {...visited.value, i};
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(12)),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Visibility(
                    visible: tab.value == _videos,
                    maintainState: true,
                    child: ProfilePostsGrid(
                      userId: user.id,
                      flag: null,
                      emptyAsset: AssetsName.feeds,
                      emptyMessage: l.emptyPosts,
                    ),
                  ),
                  if (visited.value.contains(1))
                    Visibility(
                      visible: tab.value == 1,
                      maintainState: true,
                      child: ProfilePostsGrid(
                        userId: user.id,
                        flag: 'favorite',
                        emptyAsset: AssetsName.heartout,
                        emptyMessage: l.emptyFavorites,
                      ),
                    ),
                ],
              ),
            ),
            // Clear of the floating nav bar.
            SliverToBoxAdapter(
              child: Gap(24 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================

/// Name over the @handle, beside the avatar.
class _NameBlock extends StatelessWidget {
  final User user;
  const _NameBlock({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        const Gap(4),
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

/// Bio; phone and email beside the social links; then the stats.
class _ProfileDetails extends StatelessWidget {
  final User user;
  final String? bio;
  final MyProfileSummary? summary;
  const _ProfileDetails({
    required this.user,
    required this.bio,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = summary;
    final phone = s?.phone;
    final email = (s?.email.isNotEmpty ?? false) ? s!.email : user.email;
    final links = s?.socialLinks;
    final socials = [
      (SocialLinks.facebook(links?.facebook), AssetsName.facebook, 'Facebook'),
      (SocialLinks.telegram(links?.telegram), AssetsName.telegram, 'Telegram'),
    ].where((x) => x.$1 != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bio != null && bio!.isNotEmpty) ...[
          Text(
            bio!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          const Gap(14),
        ],
        if (phone != null || email.isNotEmpty || socials.isNotEmpty) ...[
          for (final (i, line) in [
            if (phone != null)
              _ContactLine(asset: AssetsName.telephone, text: phone),
            if (email.isNotEmpty)
              _ContactLine(asset: AssetsName.mail, text: email),
            for (final (uri, asset, _) in socials)
              _ContactLine(
                asset: asset,
                text: _displayLink(uri!),
                isLink: true,
                onTap: () => SocialLinks.open(uri),
              ),
          ].indexed) ...[if (i > 0) const Gap(8), line],
          const Gap(18),
        ],
        ProfileStatsRow(
          stats: [
            (_compact(s?.postsCount ?? 0), l.statPosts),
            (_compact(s?.likesCount ?? 0), l.statLikes),
            (_compact(s?.followersCount ?? 0), l.statFollowers),
            (_compact(s?.followingCount ?? 0), l.statFollowing),
          ],
          onTaps: [
            null,
            null,
            () => openPeopleList(
              context,
              PeopleList.userFollowers(user.username),
            ),
            () => openPeopleList(
              context,
              PeopleList.userFollowing(user.username),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small icon and text: the phone number, email, or a social link.
/// Links keep their brand-colored logo, show in purple and open on tap.
class _ContactLine extends StatelessWidget {
  final String asset;
  final String text;
  final bool isLink;
  final VoidCallback? onTap;
  const _ContactLine({
    required this.asset,
    required this.text,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(
            asset,
            width: 16,
            height: 16,
            color: isLink ? null : primary,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLink ? FontWeight.w600 : null,
                color: isLink ? ProfileTheme.purple : primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [uri] without the scheme or "www.", e.g. "facebook.com/name".
String _displayLink(Uri uri) {
  final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  final path = uri.path.endsWith('/')
      ? uri.path.substring(0, uri.path.length - 1)
      : uri.path;
  return '$host$path';
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
          gradient: ProfileTheme.brandGradient,
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

// =============================================================================

class _GuestProfilePrompt extends StatelessWidget {
  const _GuestProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
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
