import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Round icon button for a profile's action row. [filled] gives it the
/// brand gradient (the primary action); otherwise it's a card-toned circle.
class ProfileCircleAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final bool filled;
  final VoidCallback onTap;
  const ProfileCircleAction({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.filled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled ? ProfileTheme.pinkPurple : null,
          color: filled ? null : ProfileTheme.surface(context),
          border: filled
              ? null
              : Border.all(color: ProfileTheme.hairlineColor(context)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: ProfileTheme.pink.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 21, color: filled ? Colors.white : iconColor),
      ),
    );
  }
}

class ProfileSegmentTab {
  /// A Material icon, or an app icon image ([asset], e.g. AssetsName.feeds)
  /// tinted to match the tab — exactly one of the two.
  final IconData? icon;
  final String? asset;
  final String label;

  /// Shown as a small badge after the label; null for none.
  final int? count;
  const ProfileSegmentTab({
    this.icon,
    this.asset,
    required this.label,
    this.count,
  }) : assert((icon == null) != (asset == null));
}

/// Segmented tab switcher with a gradient pill behind the selected segment,
/// icon + label side by side, and an optional count badge per tab.
class ProfileSegmentTabs extends StatelessWidget {
  final List<ProfileSegmentTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Smaller and flat: shorter bar, smaller text, no glow on the selected tab.
  final bool compact;
  const ProfileSegmentTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: compact ? 42 : 54,
      padding: EdgeInsets.all(compact ? 3 : 4),
      decoration: BoxDecoration(
        color: ProfileTheme.surface(context),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: _Segment(
                  tab: tabs[i],
                  selected: selected == i,
                  compact: compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final ProfileSegmentTab tab;
  final bool selected;
  final bool compact;
  const _Segment({
    required this.tab,
    required this.selected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : ProfileTheme.textSecondary(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: selected ? ProfileTheme.pinkPurple : null,
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
        boxShadow: selected && !compact
            ? [
                BoxShadow(
                  color: ProfileTheme.pink.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tab.asset != null)
            Image.asset(
              tab.asset!,
              width: compact ? 16 : 18,
              height: compact ? 16 : 18,
              color: color,
            )
          else
            Icon(tab.icon, size: compact ? 16 : 18, color: color),
          Gap(compact ? 6 : 7),
          Flexible(
            child: Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (tab.count != null) ...[
            const Gap(7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.black.withValues(alpha: 0.2)
                    : ProfileTheme.textSecondary(
                        context,
                      ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tab.count}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
