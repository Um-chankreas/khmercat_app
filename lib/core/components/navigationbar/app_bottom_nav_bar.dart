// lib/core/components/navigation/app_bottom_nav_bar.dart
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';

import 'cat_create_button.dart';
import 'nav_item.dart';

/// How much room a page under an `extendBody` Scaffold should leave at the
/// bottom so its content ends at the top of the bar's flat part (the center
/// dome may overlap it). 0 when there is no bar.
double navBarInset(BuildContext context) => math.max(
  0,
  MediaQuery.paddingOf(context).bottom - AppBottomNavBar.bumpHeight,
);

/// Floating frosted-glass bar with a round dome in the middle over the cat
/// "create" button. The bar itself has no outline; only the icons are
/// glowing pink → blue lines, and there are no labels.
///
/// The page is meant to show through it, so the Scaffold using it should
/// set `extendBody: true`. Pages that shouldn't run under the bar can pad
/// their bottom by [navBarInset].
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;

  /// The user is acting as a restaurant: the profile tab shows the shop
  /// icon instead of the user icon.
  final bool actingAsRestaurant;

  /// The page behind is media (the video feed): use a faint light frost
  /// instead of the near-opaque grey used over flat pages.
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
    this.actingAsRestaurant = false,
    this.overMedia = false,
    this.uploadBusy = false,
    this.uploadProgress,
    this.uploadError = false,
    this.uploadSuccess = false,
    super.key,
  });

  /// Height of the flat part of the bar.
  static const double barHeight = 50;

  /// How far the center dome rises above the flat part.
  static const double bumpHeight = 12;

  static const double _sideMargin = 10;
  static const double _bottomMargin = 8;
  static const double _centerWidth = 76;
  static const double _catBottomPadding = 8;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    const clipper = _BarClipper();

    // The same warm grey pane on every tab. Over the feed a light frost
    // lets the video through and lands on that grey by itself. The other
    // tabs have a flat white or near-black page behind the bar, where the
    // same frost would come out near-white or near-black, so there the
    // pane is that grey itself, nearly opaque. The pane is never light, so
    // the icons always use the bright neon colors.
    final tint = overMedia
        ? const Color(0xffA39A92).withValues(alpha: 0.10)
        : const Color(0xff8F867A).withValues(alpha: 0.20);

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
                // Uses the full height, dome included; the padding lifts
                // the cat a little so its head sits up in the dome.
                SizedBox(
                  width: _centerWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _catBottomPadding),
                    child: CatCreateButton(
                      label: 'Create',
                      onTap: onCreateTap,
                      busy: uploadBusy,
                      progress: uploadProgress,
                      error: uploadError,
                      success: uploadSuccess,
                    ),
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
                    child: NavItem(
                      imagePath: actingAsRestaurant
                          ? AssetsName.shop
                          : AssetsName.user,
                      label: l.navProfile,
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
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

/// Keeps a side item inside the flat part of the bar (below the dome).
class _Flat extends StatelessWidget {
  final Widget child;
  const _Flat({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppBottomNavBar.bumpHeight),
    child: child,
  );
}

/// The bar's silhouette: a rounded rectangle whose top edge rises into a
/// round dome in the middle, over the cat button.
Path _barPath(Size size) {
  const r = 22.0;
  const bump = AppBottomNavBar.bumpHeight;
  final w = size.width, h = size.height, cx = w / 2;

  return Path()
    ..moveTo(r, bump)
    ..lineTo(cx - 40, bump)
    // One round dome over the cat button, eased into the flat edge.
    ..cubicTo(cx - 27, bump, cx - 23, 0, cx, 0)
    ..cubicTo(cx + 23, 0, cx + 27, bump, cx + 40, bump)
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
