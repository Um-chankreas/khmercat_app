import 'package:flutter/material.dart';

/// Pins [child] at the top of a [CustomScrollView] at a fixed [height].
///
/// Unlike a typical collapsing header, `minExtent` and `maxExtent` are the
/// same value, so there's no shrink animation and nothing that depends on
/// how far the user has scrolled: the header is simply always [height] tall
/// and always pinned, whether the slivers below it hold no items or hundreds.
/// That fixed extent is also what makes it safe to sit inside a real
/// [CustomScrollView] (rather than a plain, non-scrolling widget) — a drag
/// that starts anywhere on screen, including directly over this header,
/// still scrolls the page, exactly as it would over any other sliver.
class FixedSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  FixedSliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant FixedSliverHeaderDelegate old) =>
      height != old.height || child != old.child;
}

// A previous version of this file also had `flexibleSpaceCollapseFraction`
// and `flexibleSpaceCrossfade`, driven by [FlexibleSpaceBarSettings] — the
// InheritedWidget FlexibleSpaceBar uses internally for its own `title` fade.
// Both looked like the right way to read "how collapsed is the header" from
// inside a custom `background`/`title` widget, and both had a real bug: with
// a plain `pinned: true` SliverAppBar (no `floating: true`), Flutter
// hard-codes the fade opacity FlexibleSpaceBar.title reads to a constant
// `1.0`, so relying on that same signal for a custom crossfade meant the
// "collapsed" state either never actually triggered, or (once mixed with a
// manual opacity, in an earlier revision) triggered at the wrong moment —
// both shipped as real, screenshotted bugs on the profile and edit-profile
// screens before this was replaced. ProfileTab and EditProfileScreen now
// each compute their own collapse fraction directly from a ScrollController
// attached to their CustomScrollView instead — see
// `ProfileTab._collapseFraction` / `EditProfileScreen._collapseFraction` —
// which reads the real scroll offset and has no such edge case.
