import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// One tab for [ProfileUnderlineTabs]: an app icon image ([asset]) or a
/// Material [icon], plus a short label.
class ProfileUnderlineTab {
  final String? asset;
  final IconData? icon;
  final String label;
  const ProfileUnderlineTab({this.asset, this.icon, required this.label})
    : assert((asset == null) != (icon == null));
}

/// Icon + label tabs sharing the width equally, a dark underline under the
/// selected one and a hairline along the bottom. Labels shrink instead of
/// overflowing on narrow screens or with large text.
class ProfileUnderlineTabs extends StatelessWidget {
  final List<ProfileUnderlineTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const ProfileUnderlineTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ProfileTheme.hairlineColor(context)),
          ),
        ),
        child: Row(
          children: [
            for (final (i, t) in tabs.indexed)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == selected) return;
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: i == selected ? primary : Colors.transparent,
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          if (t.asset != null)
                            Image.asset(
                              t.asset!,
                              width: 17,
                              height: 17,
                              color: i == selected ? primary : muted,
                            )
                          else
                            Icon(
                              t.icon,
                              size: 18,
                              color: i == selected ? primary : muted,
                            ),
                          const Gap(7),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: i == selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: i == selected ? primary : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grey circle holding a brand logo ([asset]) or the name's [initial], with
/// a small caption underneath.
class ProfileLinkCircle extends StatelessWidget {
  final String label;
  final String? asset;
  final String? initial;
  final VoidCallback onTap;
  const ProfileLinkCircle({
    required this.label,
    required this.onTap,
    this.asset,
    this.initial,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted.withValues(alpha: 0.12),
              ),
              child: asset != null
                  ? Image.asset(asset!, width: 22, height: 22)
                  : Text(
                      (initial ?? '?').characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ProfileTheme.textPrimary(context),
                      ),
                    ),
            ),
            const Gap(6),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-height pill button: pastel pink → blue gradient when [filled],
/// otherwise a grey wash.
class ProfileGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;
  const ProfileGradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ProfileTheme.ink : ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xffF0A6CE), Color(0xffA9C1F5)],
                )
              : null,
          color: filled
              ? null
              : ProfileTheme.textSecondary(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: fg),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round camera button laid on the cover photo (the owner's view).
class ProfileChangeCoverButton extends StatelessWidget {
  final VoidCallback onTap;
  const ProfileChangeCoverButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change cover',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.photo_camera_outlined,
            size: 19,
            color: ProfileTheme.ink,
          ),
        ),
      ),
    );
  }
}

/// Posts · Reviews · … as evenly spaced stats, with a thin pink → purple →
/// blue line between them and no background.
class ProfileStatsRow extends StatelessWidget {
  /// (value, label) — shown in order.
  final List<(String, String)> stats;
  const ProfileStatsRow({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    const divider = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ProfileTheme.pink, ProfileTheme.purple, ProfileTheme.blue],
        ),
      ),
      child: SizedBox(width: 1.5, height: 34),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final (i, (value, label)) in stats.indexed) ...[
            if (i > 0) divider,
            Expanded(
              child: Column(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: ProfileTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
