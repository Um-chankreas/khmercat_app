import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';

// Shared by the user and restaurant profile pages so both use one action
// style: equal-width icon-over-label tiles, a "Follow us on" logo strip, and
// a chip saying which kind of profile it is.

/// One action: icon over a short label in a 60px tile with 18px corners.
/// The main action uses the brand gradient with a soft glow; the rest a
/// tonal purple fill. Switching [primary] (e.g. Follow -> Following) blends
/// between the two, and the icon/label cross-fade. Tiles share a row
/// equally, so the layout never overflows.
class ProfileActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const ProfileActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    super.key,
  });

  @override
  State<ProfileActionTile> createState() => _ProfileActionTileState();
}

class _ProfileActionTileState extends State<ProfileActionTile> {
  bool _pressed = false;

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = w.primary
        ? Colors.white
        : (isDark ? const Color(0xffC9B8FF) : ProfileTheme.deepPurple);

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      // Quick squeeze in, springy release.
      duration: Duration(milliseconds: _pressed ? 90 : 260),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: _radius,
          gradient: w.primary ? ProfileTheme.pinkPurple : null,
          color: w.primary
              ? null
              : ProfileTheme.purple.withValues(alpha: isDark ? 0.16 : 0.08),
          boxShadow: [
            BoxShadow(
              color: ProfileTheme.pink.withValues(alpha: w.primary ? 0.30 : 0),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Transparent Material above the fill so the ripple shows on it.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: _radius,
            onTap: () {
              HapticFeedback.lightImpact();
              w.onTap();
            },
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: (w.primary ? Colors.white : ProfileTheme.purple)
                .withValues(alpha: 0.16),
            highlightColor: Colors.transparent,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey('${w.label}${w.primary}'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(w.icon, size: 22, color: fg),
                  const Gap(4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      w.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light row: "Follow us on" + the real brand logos, each tappable. No box
/// around it, so it reads as part of the header instead of another card.
class ProfileSocialStrip extends StatelessWidget {
  /// (link, brand logo asset, name) for each link that's set.
  final List<(Uri, String, String)> links;
  const ProfileSocialStrip({required this.links, super.key});

  @override
  Widget build(BuildContext context) {
    // The logos are 512px PNGs; decode them at their on-screen size.
    final cache = (20 * MediaQuery.devicePixelRatioOf(context)).round();
    return Row(
      children: [
        Text(
          'Follow us on',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
        const Gap(10),
        for (final (uri, asset, label) in links) ...[
          Tooltip(
            message: label,
            child: Material(
              color: ProfileTheme.surface(context),
              shape: CircleBorder(
                side: BorderSide(color: ProfileTheme.hairlineColor(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => SocialLinks.open(uri),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    asset,
                    width: 20,
                    height: 20,
                    cacheWidth: cache,
                  ),
                ),
              ),
            ),
          ),
          const Gap(8),
        ],
      ],
    );
  }
}

/// "Personal" (person icon, blue) or "Restaurant" (storefront, pink) — so
/// it's always obvious which kind of profile you're looking at.
class ProfileTypeChip extends StatelessWidget {
  final bool isRestaurant;

  /// Overrides the label (e.g. the restaurant's category name).
  final String? label;
  const ProfileTypeChip({required this.isRestaurant, this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final color = isRestaurant ? ProfileTheme.pink : const Color(0xff3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRestaurant ? Icons.storefront_rounded : Icons.person_rounded,
            size: 14,
            color: color,
          ),
          const Gap(5),
          Text(
            label ?? (isRestaurant ? 'Restaurant' : 'Personal'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
