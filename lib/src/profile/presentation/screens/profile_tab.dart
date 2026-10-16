// lib/src/profile/presentation/screens/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
import 'package:khmer_cat_app/core/components/profile/profile_collapsing_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_shared_widgets.dart'
    hide ProfileGradientButton;
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
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
/// with an Edit pill, name and @handle beside it, and a QR button; bio,
/// phone / email with the social links; Posts · Likes · Followers ·
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
              coverAction: ProfileChangeCoverButton(
                onTap: () =>
                    changeProfileImage(context, ref, ProfileImageKind.cover),
              ),
              actions: [
                ProfileCircleButton(
                  icon: Icons.settings_outlined,
                  onTap: () =>
                      AppRouter.router.pushNamed(AppRoute.settings.name),
                ),
                const Gap(6),
              ],
              // Name + @handle beside the avatar, the Edit pill under it,
              // and the QR button on the right.
              belowFoldHeight: 54,
              belowFoldAction: SizedBox(
                // Screen width minus the side margins.
                width: width - 40,
                height: 54,
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
                      // Under the cover's camera button, 14px from the edge
                      // (this row's edge is 20px in).
                      right: -6,
                      top: 0,
                      child: _OutlinedCircleButton(
                        icon: Icons.qr_code_2_rounded,
                        tooltip: 'My QR code',
                        // TODO(backend): profiles have no public link to
                        // encode yet.
                        onTap: () => AppService.showToast(l.comingSoon),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _ProfileDetails(user: user, bio: bio, summary: summary),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(14)),
            SliverToBoxAdapter(
              child: ProfileUnderlineTabs(
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
      (SocialLinks.tiktok(links?.tiktok), AssetsName.tiktok, 'TikTok'),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (phone != null)
                      _ContactLine(icon: Icons.phone_outlined, text: phone),
                    if (phone != null && email.isNotEmpty) const Gap(8),
                    if (email.isNotEmpty)
                      _ContactLine(
                        icon: Icons.mail_outline_rounded,
                        text: email,
                      ),
                  ],
                ),
              ),
              for (final (uri, asset, label) in socials) ...[
                const Gap(10),
                _SocialCircle(
                  asset: asset,
                  tooltip: label,
                  onTap: () => SocialLinks.open(uri!),
                ),
              ],
            ],
          ),
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

/// A small line icon and text: the phone number or email.
class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: primary),
        const Gap(8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: primary),
          ),
        ),
      ],
    );
  }
}

/// Grey circle with a platform icon, opening that profile.
class _SocialCircle extends StatelessWidget {
  final String asset;
  final String tooltip;
  final VoidCallback onTap;
  const _SocialCircle({
    required this.asset,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ProfileTheme.textSecondary(context).withValues(alpha: 0.12),
          ),
          child: Image.asset(asset, width: 20, height: 20),
        ),
      ),
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

/// Round outlined button on the page (not the cover), e.g. QR.
class _OutlinedCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _OutlinedCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, size: 20, color: ProfileTheme.textPrimary(context)),
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
