// lib/core/components/navigation/app_bottom_nav_bar.dart
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';

import 'cat_create_button.dart';
import 'nav_item.dart';

/// How much room a page under an `extendBody` Scaffold should leave at the
/// bottom so its content ends at the top of the bar's flat part (the center
/// bump may overlap it). 0 when there is no bar.
double navBarInset(BuildContext context) => math.max(
  0,
  MediaQuery.paddingOf(context).bottom - AppBottomNavBar.bumpHeight,
);

/// Floating frosted-glass bar with a raised bump in the middle for the cat
/// "create" button. The bar itself has no outline; only the icons are
/// glowing pink → blue lines, and there are no labels.
///
/// The page is meant to show through it, so the Scaffold using it should
/// set `extendBody: true`. Pages that shouldn't run under the bar can pad
/// their bottom by the body's bottom inset minus [bumpHeight].
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;
  final String? avatarUrl;

  /// The user is acting as a restaurant: the avatar gets a small storefront
  /// badge (or, with no photo, becomes a storefront icon) so the current
  /// profile is always visible.
  final bool avatarIsRestaurant;

  /// The page behind is dark media (the video feed): use a faint light
  /// frost instead of the theme's surface tint.
  final bool overMedia;

  /// A background video upload is compressing/uploading.
  final bool uploadBusy;

  /// Upload progress 0..1 while uploading; null while compressing
  /// (indeterminate).
  final double? uploadProgress;

  /// The last background upload failed — the create button turns into a
  /// retry affordance.
  final bool uploadError;

  /// The last background upload just succeeded — briefly shown before reset.
  final bool uploadSuccess;

  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCreateTap,
    this.avatarUrl,
    this.avatarIsRestaurant = false,
    this.overMedia = false,
    this.uploadBusy = false,
    this.uploadProgress,
    this.uploadError = false,
    this.uploadSuccess = false,
    super.key,
  });

  /// Height of the flat part of the bar.
  static const double barHeight = 50;

  /// How far the center bump rises above the flat part.
  static const double bumpHeight = 8;

  static const double _sideMargin = 10;
  static const double _bottomMargin = 8;
  static const double _centerWidth = 76;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    const clipper = _BarClipper();

    // The same smoky grey pane on every tab. Over the dark feed a light
    // frost is enough; over a light page the same frost would come out
    // near-white, so there it is a darker, denser grey that lands on the
    // color the bar has over video. The pane is always dark, so the icons
    // always use the bright neon colors.
    final lightPage = !overMedia && !isDark;
    final tint = lightPage
        ? const Color(0xff58534F).withValues(alpha: 0.84)
        : const Color(0xffA39A92).withValues(alpha: 0.40);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _sideMargin,
        0,
        _sideMargin,
        _bottomMargin + safeBottom,
      ),
      child: SizedBox(
        height: barHeight + bumpHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Frosted glass in the bar's shape.
            ClipPath(
              clipper: clipper,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: ColoredBox(color: tint),
              ),
            ),
            const IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _BarEdgePainter()),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Flat(
                    child: NavItem(
                      imagePath: AssetsName.navHome,
                      label: l.navHome,
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                ),
                Expanded(
                  child: _Flat(
                    child: NavItem(
                      imagePath: AssetsName.navSearch,
                      label: l.navSearch,
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                ),
                // Uses the full height, bump included.
                SizedBox(
                  width: _centerWidth,
                  child: CatCreateButton(
                    label: 'Create',
                    onTap: onCreateTap,
                    busy: uploadBusy,
                    progress: uploadProgress,
                    error: uploadError,
                    success: uploadSuccess,
                  ),
                ),
                Expanded(
                  child: _Flat(
                    child: NavItem(
                      imagePath: AssetsName.navNotification,
                      label: l.navNotifications,
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ),
                Expanded(
                  child: _Flat(
                    child: NavSlot(
                      label: l.navProfile,
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                      child: _ProfileIcon(
                        avatarUrl: avatarUrl,
                        isRestaurant: avatarIsRestaurant,
                        isActive: currentIndex == 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a side item inside the flat part of the bar (below the bump line).
class _Flat extends StatelessWidget {
  final Widget child;
  const _Flat({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppBottomNavBar.bumpHeight),
    child: child,
  );
}

/// The profile tab: the photo in a glowing gradient ring (with a storefront
/// badge when acting as a restaurant). With no photo, a glowing storefront
/// or person line icon instead.
class _ProfileIcon extends StatelessWidget {
  final String? avatarUrl;
  final bool isRestaurant;
  final bool isActive;
  const _ProfileIcon({
    required this.avatarUrl,
    required this.isRestaurant,
    required this.isActive,
  });

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final Widget icon;
    if (!hasPhoto) {
      icon = NavGlow(
        strength: isActive ? 1 : 0.65,
        child: Icon(
          isRestaurant
              ? Icons.storefront_outlined
              : Icons.person_outline_rounded,
          size: NavItem.iconSize + 2,
          color: Colors.white,
        ),
      );
    } else {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(1.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: navGlowGradient,
              boxShadow: [
                BoxShadow(
                  color: navGlowColors.first.withValues(
                    alpha: isActive ? 0.75 : 0.35,
                  ),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ImageUserCircleProfile(imageUrl: avatarUrl, size: _size),
          ),
          if (isRestaurant)
            Positioned(
              right: -4,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: navGlowGradient,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey('$avatarUrl|$isRestaurant'),
        child: icon,
      ),
    );
  }
}

/// The bar's silhouette: a rounded rectangle whose top edge rises into a
/// flat-topped bump in the middle, with smooth shoulders.
Path _barPath(Size size) {
  const r = 22.0;
  const bump = AppBottomNavBar.bumpHeight;
  const shoulder = 20.0;
  // Flat top of the bump; narrower on very small phones.
  final top = math.min(60.0, size.width * 0.26);
  final w = size.width, h = size.height, cx = w / 2;
  final l0 = cx - top / 2 - shoulder, l1 = cx - top / 2;
  final r0 = cx + top / 2, r1 = cx + top / 2 + shoulder;

  return Path()
    ..moveTo(r, bump)
    ..lineTo(l0, bump)
    ..cubicTo(l0 + shoulder * 0.55, bump, l1 - shoulder * 0.55, 0, l1, 0)
    ..lineTo(r0, 0)
    ..cubicTo(r0 + shoulder * 0.55, 0, r1 - shoulder * 0.55, bump, r1, bump)
    ..lineTo(w - r, bump)
    ..arcToPoint(Offset(w, bump + r), radius: const Radius.circular(r))
    ..lineTo(w, h - r)
    ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
    ..lineTo(r, h)
    ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
    ..lineTo(0, bump + r)
    ..arcToPoint(const Offset(r, bump), radius: const Radius.circular(r))
    ..close();
}

class _BarClipper extends CustomClipper<Path> {
  const _BarClipper();

  @override
  Path getClip(Size size) => _barPath(size);

  @override
  bool shouldReclip(_BarClipper oldClipper) => false;
}

/// Thin light rim in the bar's shape, like the edge of a pane of glass.
class _BarEdgePainter extends CustomPainter {
  const _BarEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Inset half a stroke so the line isn't cut off at the widget's edge.
    final inner = Size(size.width - 1, size.height - 1);
    canvas.drawPath(
      _barPath(inner).shift(const Offset(0.5, 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_BarEdgePainter oldDelegate) => false;
}
