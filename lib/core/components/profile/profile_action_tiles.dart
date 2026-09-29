import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';

// Shared by the user and restaurant profile pages so both use one action
// style: equal-width icon-over-label tiles, a "Follow us on" logo strip, and
// a chip saying which kind of profile it is.

/// One action: icon over a short label in a 64px tile with 14px corners.
/// The main action uses the brand gradient; the rest a soft purple tint.
/// Tiles share a row equally, so the layout never overflows.
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

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = w.primary ? Colors.white : ProfileTheme.deepPurple;
    final radius = BorderRadius.circular(14);

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: w.primary ? ProfileTheme.pinkPurple : null,
            color: w.primary
                ? null
                : ProfileTheme.purple.withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: w.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: (w.primary ? Colors.white : ProfileTheme.purple)
                .withValues(alpha: 0.15),
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(w.icon, size: 22, color: fg),
                  const Gap(5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      w.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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

/// Slim bar: "Follow us on" + the real brand logos, each tappable.
class ProfileSocialStrip extends StatelessWidget {
  /// (link, brand logo asset, name) for each link that's set.
  final List<(Uri, String, String)> links;
  const ProfileSocialStrip({required this.links, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: ProfileTheme.purple.withValues(alpha: isDark ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Follow us on',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
          ),
          for (final (uri, asset, label) in links) ...[
            const Gap(6),
            Tooltip(
              message: label,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => SocialLinks.open(uri),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(asset, width: 22, height: 22),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
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
