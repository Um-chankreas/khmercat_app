// lib/core/components/navigation/nav_item.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Bright pink → blue used for every glowing line on the bottom bar: the
/// icons and the cat button.
const navGlowColors = [Color(0xffFF74CB), Color(0xff62D2FF)];

const navGlowGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: navGlowColors,
);

/// Deeper pink → blue for when the bar sits on a light page: the bright
/// pair washes out against white.
const navInkColors = [Color(0xffE5318F), Color(0xff2F8DEB)];

const navInkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: navInkColors,
);

/// The line gradient for the bar's current backdrop.
LinearGradient navGradient({required bool onLight}) =>
    onLight ? navInkGradient : navGlowGradient;

/// Paints [child] in the pink → blue gradient with a soft halo of the same
/// colors behind it, so a line icon looks like a lit neon tube. [strength]
/// (0..1) scales the halo. With [onLight] it uses the deeper colors and
/// only a faint halo, which is what stays readable on a white page.
class NavGlow extends StatelessWidget {
  final Widget child;
  final double strength;
  final bool onLight;
  const NavGlow({
    required this.child,
    this.strength = 1,
    this.onLight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strength = onLight ? this.strength * 0.35 : this.strength;
    final tinted = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: navGradient(onLight: onLight).createShader,
      child: child,
    );
    // The halo is a blurred copy underneath; cached so it isn't re-blurred
    // while the page behind the bar scrolls.
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (strength > 0)
            Opacity(
              opacity: 0.85 * strength,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: tinted,
              ),
            ),
          tinted,
        ],
      ),
    );
  }
}

/// One icon on the bottom bar. No label: the active tab is brighter, a
/// little larger, and has a glowing dot under it.
class NavItem extends StatelessWidget {
  final String imagePath;

  /// Read by screen readers (the bar shows no text).
  final String label;
  final bool isActive;

  /// The bar is over a light page (see [NavGlow.onLight]).
  final bool onLight;
  final VoidCallback onTap;

  const NavItem({
    required this.imagePath,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onLight = false,
    super.key,
  });

  static const double iconSize = 23;

  @override
  Widget build(BuildContext context) {
    // The icons are 512px PNGs; decode them at their on-screen size.
    final cache = (iconSize * MediaQuery.devicePixelRatioOf(context)).round();
    return NavSlot(
      label: label,
      isActive: isActive,
      onLight: onLight,
      onTap: onTap,
      child: NavGlow(
        onLight: onLight,
        strength: isActive ? 1 : 0.65,
        child: Image.asset(
          imagePath,
          width: iconSize,
          height: iconSize,
          cacheWidth: cache,
        ),
      ),
    );
  }
}

/// Tap target + active treatment shared by the icon tabs and the profile
/// avatar.
class NavSlot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool onLight;
  final VoidCallback onTap;
  final Widget child;
  const NavSlot({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.child,
    this.onLight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            AnimatedScale(
              scale: isActive ? 1.12 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isActive ? 1 : 0.92,
                duration: const Duration(milliseconds: 200),
                child: child,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 5 : 0,
              height: 3,
              decoration: BoxDecoration(
                gradient: navGradient(onLight: onLight),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: navGlowColors.first.withValues(
                      alpha: onLight ? 0.3 : 0.8,
                    ),
                    blurRadius: 6,
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
