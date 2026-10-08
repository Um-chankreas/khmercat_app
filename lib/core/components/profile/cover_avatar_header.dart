import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

/// Cover photo + gradient-ring avatar overlapping its bottom edge. Used by
/// the signed-in user's own profile (with [actions] / [avatarBadge] for edit
/// affordances) and by the read-only user and restaurant profiles (just an
/// optional back button).
class CoverAvatarHeader extends StatelessWidget {
  final String? coverUrl;
  final String? avatarUrl;
  final String? name;
  final VoidCallback? onBack;

  /// Shown in the top-left corner of the cover, alongside [onBack]/[actions]
  /// — e.g. an "@username" label over the photo.
  final Widget? topLeft;

  /// Buttons stacked in the top-right corner of the cover.
  final List<Widget> actions;

  /// Button in the bottom-right corner of the cover, just above the fold
  /// (e.g. "edit cover").
  final Widget? coverAction;

  /// Small badge on the avatar's bottom-right edge.
  final Widget? avatarBadge;

  /// Button below the fold, right-aligned and vertically level with the
  /// avatar's lower half (e.g. "edit profile") — clustered with
  /// [coverAction] and [avatarBadge] as the header's edit affordances,
  /// rather than a flow child further down the page.
  final Widget? belowFoldAction;

  /// Centers the avatar instead of left-aligning it.
  final bool centerAvatar;

  /// Height reserved for [belowFoldAction] (it starts [actionGap] under the
  /// cover).
  final double belowFoldHeight;
  final double coverHeight;
  final double avatarSize;

  /// Rounding of the cover's bottom corners — a soft curve by default, or 0
  /// for a squared-off edge (e.g. the signed-in user's own profile).
  final double coverRadius;

  /// Optional color wash over the cover photo, e.g. [ProfileTheme.gradient]
  /// at a low opacity — gives the header a branded "mood" tint instead of
  /// showing the raw photo, while still reading as a photo underneath.
  final Gradient? coverTint;

  const CoverAvatarHeader({
    this.coverUrl,
    this.avatarUrl,
    this.name,
    this.onBack,
    this.topLeft,
    this.actions = const [],
    this.coverAction,
    this.avatarBadge,
    this.belowFoldAction,
    this.centerAvatar = false,
    this.belowFoldHeight = actionHeight,
    this.coverHeight = 200,
    this.avatarSize = 104,
    this.coverRadius = 28,
    this.coverTint,
    super.key,
  });

  /// Space to leave below the header so content clears the overlapping
  /// avatar (half its outer size plus breathing room).
  static double contentGap([double avatarSize = 104]) => avatarSize / 2 + 18;

  /// A [belowFoldAction] sits [actionGap] under the cover and is at most
  /// [actionHeight] tall.
  static const double actionGap = 16;
  static const double actionHeight = 44;

  /// Space below the cover that a [belowFoldAction] of [height] needs,
  /// including the same [actionGap] again before the content that follows.
  static double belowFoldExtent([double height = actionHeight]) =>
      actionGap + height + actionGap;

  @override
  Widget build(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    // How far the avatar hangs below the fold — also how much taller this
    // Stack's own hit-testable box needs to be than the cover photo itself.
    // `Clip.none` only lets Positioned children *paint* outside the Stack's
    // bounds — hit-testing always gates on the Stack's own `size` first
    // (RenderBox.hitTest checks `size.contains(position)` before ever
    // reaching hitTestChildren), so without growing the box by this amount,
    // `avatarBadge`/`belowFoldAction` are visible but can never receive
    // taps. Every `bottom:`-positioned child below is offset by this same
    // amount to land at the same on-screen spot it would if the Stack were
    // still exactly `coverHeight` tall.
    final avatarOverlap = (avatarSize + 12) / 2;
    // The box also has to reach the bottom of a below-fold action.
    final extra = belowFoldAction == null
        ? avatarOverlap
        : (avatarOverlap > actionGap + belowFoldHeight
              ? avatarOverlap
              : actionGap + belowFoldHeight);

    final avatar = ProfileRingAvatar(
      avatarUrl: avatarUrl,
      name: name,
      size: avatarSize,
      badge: avatarBadge,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: double.infinity, height: coverHeight + extra),
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(coverRadius),
          ),
          child: SizedBox(
            height: coverHeight + statusBar * 0,
            width: double.infinity,
            child: hasCover
                ? CachedNetworkImage(
                    imageUrl: coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _SoftCoverFallback(),
                    errorWidget: (_, _, _) => const _SoftCoverFallback(),
                  )
                : const _SoftCoverFallback(),
          ),
        ),
        // Only wash a real photo — the fallback gradient is already the
        // intended on-brand color, so tinting it too would just mute it.
        if (coverTint != null && hasCover)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: coverTint,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(coverRadius),
                  ),
                ),
              ),
            ),
          ),
        if (onBack != null || topLeft != null || actions.isNotEmpty)
          // Scrim so status-bar icons and the buttons stay legible over a
          // busy cover photo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBar + 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: hasCover ? 0.25 : 0.0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        if (onBack != null)
          Positioned(
            top: statusBar + 8,
            left: 14,
            child: ProfileCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack!,
            ),
          ),
        if (topLeft != null)
          Positioned(top: statusBar + 8, left: 16, child: topLeft!),
        if (actions.isNotEmpty)
          Positioned(
            top: statusBar + 8,
            right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ),
        if (coverAction != null)
          Positioned(bottom: 14 + extra, right: 14, child: coverAction!),
        Positioned(
          left: centerAvatar ? 0 : 20,
          right: centerAvatar ? 0 : null,
          bottom: extra - avatarOverlap,
          child: centerAvatar ? Center(child: avatar) : avatar,
        ),
        if (belowFoldAction != null)
          Positioned(
            right: 20,
            top: coverHeight + actionGap,
            child: belowFoldAction!,
          ),
      ],
    );
  }
}

/// Gradient-ringed avatar with an optional badge; shared by the cover header
/// and the pinned profile header.
class ProfileRingAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final double size;
  final Widget? badge;
  const ProfileRingAvatar({
    required this.avatarUrl,
    required this.name,
    required this.size,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: ProfileTheme.gradient,
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ImageUserCircleProfile(
              imageUrl: avatarUrl,
              name: name,
              size: size,
            ),
          ),
        ),
        if (badge != null) Positioned(right: 0, bottom: 2, child: badge!),
      ],
    );
  }
}

/// Round white button used over a cover photo (back, menu, camera…). Sized
/// for a nav-bar action by default; pass a smaller [padding]/[iconSize] for
/// a lighter-touch affordance like the cover/avatar camera buttons.
class ProfileCircleButton extends StatelessWidget {
  final IconData? icon;

  /// Asset image to show instead of [icon] (e.g. a custom icon from
  /// [AssetsName]). Exactly one of `icon` / `iconAsset` must be set.
  final String? iconAsset;
  final VoidCallback onTap;
  final double padding;
  final double iconSize;

  /// Frosted dark-glass style (translucent black + white icon) instead of
  /// the default opaque-white circle — for sitting on a busy/colorful cover
  /// photo rather than a plain background.
  final bool dark;
  const ProfileCircleButton({
    this.icon,
    this.iconAsset,
    required this.onTap,
    this.padding = 9,
    this.iconSize = 21,
    this.dark = false,
    super.key,
  }) : assert(
         (icon == null) != (iconAsset == null),
         'Pass exactly one of icon or iconAsset.',
       );

  @override
  Widget build(BuildContext context) {
    final tint = dark ? Colors.white : ProfileTheme.ink;
    return Material(
      color: dark
          ? Colors.black.withValues(alpha: 0.32)
          : Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        splashColor: ProfileTheme.purple.withValues(alpha: 0.15),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: iconAsset != null
              ? Image.asset(
                  iconAsset!,
                  width: iconSize,
                  height: iconSize,
                  color: tint,
                )
              : Icon(icon, size: iconSize, color: tint),
        ),
      ),
    );
  }
}

/// Small pink → purple circle icon button used for every "edit this" action
/// on the profile (cover, avatar, profile info) — a consistent gradient
/// affordance distinct from [ProfileCircleButton]'s neutral, non-editing
/// actions (share, settings).
class ProfileEditIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  /// A white ring, e.g. to separate the button from the avatar photo it
  /// overlaps.
  final bool ringed;

  const ProfileEditIconButton({
    required this.icon,
    required this.onTap,
    this.size = 34,
    this.ringed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Ink(
        decoration: BoxDecoration(
          gradient: ProfileTheme.pinkPurple,
          shape: BoxShape.circle,
          border: ringed ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.45, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Cover for a profile with no photo: the app's pink → purple → blue as a
/// soft wash on white, with the cat logo faded into the top-right corner.
class _SoftCoverFallback extends StatelessWidget {
  const _SoftCoverFallback();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) => Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1B1830) : Colors.white,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ProfileTheme.pink.withValues(alpha: isDark ? 0.35 : 0.38),
                  ProfileTheme.purple.withValues(alpha: isDark ? 0.3 : 0.28),
                  ProfileTheme.blue.withValues(alpha: isDark ? 0.35 : 0.42),
                ],
              ),
            ),
          ),
          Positioned(
            right: -c.maxWidth * 0.06,
            top: -c.maxHeight * 0.1,
            width: c.maxWidth * 0.72,
            child: Image.asset(
              AssetsName.appLogoTrsm,
              opacity: const AlwaysStoppedAnimation(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
