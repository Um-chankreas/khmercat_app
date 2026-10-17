import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

/// One tab for [ProfileUnderlineTabs]: an app icon image ([asset]) or a
/// Material [icon], plus a short label.
class ProfileUnderlineTab {
  final String? asset;
  final IconData? icon;
  final String label;
  const ProfileUnderlineTab({this.asset, this.icon, required this.label})
    : assert((asset == null) != (icon == null));
}

/// Icon + label tabs sharing the width equally, a soft pink → blue
/// underline under the selected one and a softer one along the bottom. Labels
/// shrink instead of overflowing on narrow screens or with large text.
class ProfileUnderlineTabs extends StatelessWidget {
  static const _lineGradient = ProfileTheme.brandGradient;

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
      child: Stack(
        children: [
          // Full-width line along the bottom: the same gradient as the
          // selected tab's underline, thinner and softer so that one
          // stands out.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.6,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _lineGradient),
                child: SizedBox(height: 1),
              ),
            ),
          ),
          Row(
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
                    child: Stack(
                      children: [
                        Container(
                          height: 48,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
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
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: i == selected ? 1 : 0,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(2),
                                ),
                                gradient: _lineGradient,
                              ),
                              child: SizedBox(height: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
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
          gradient: filled ? ProfileTheme.brandGradient : null,
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

  /// Diameter; the icon is half of it.
  final double size;
  const ProfileChangeCoverButton({
    required this.onTap,
    this.size = 38,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change cover',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            AssetsName.cameraPhoto,
            width: size / 2,
            height: size / 2,
            color: ProfileTheme.ink,
            // A 512px PNG; decode it at its on-screen size.
            cacheWidth: (size / 2 * MediaQuery.devicePixelRatioOf(context))
                .round(),
          ),
        ),
      ),
    );
  }
}

/// Posts · Reviews · … as evenly spaced stats, with a thin soft pink → blue
/// line between them and no background.
class ProfileStatsRow extends StatelessWidget {
  /// (value, label) — shown in order.
  final List<(String, String)> stats;

  /// What tapping each stat opens, by position; null (or missing) for
  /// none.
  final List<VoidCallback?> onTaps;
  const ProfileStatsRow({
    required this.stats,
    this.onTaps = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const divider = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ProfileTheme.brandPink, ProfileTheme.brandBlue],
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: i < onTaps.length ? onTaps[i] : null,
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
            ),
          ],
        ],
      ),
    );
  }
}
