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

  /// The soft full-width line along the bottom; off leaves only the
  /// selected tab's underline.
  final bool showBaseline;
  const ProfileUnderlineTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.showBaseline = true,
    super.key,
  });

  static const _iconSize = 17.0;
  static const _iconGap = 7.0;
  static const _tabPadding = 2.0;

  static TextStyle _labelStyle(bool selected) => TextStyle(
    fontSize: 14.5,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
  );

  /// Each tab's width. Equal when every tab fits its share; otherwise each
  /// gets its own content width plus an even share of what's left, so a
  /// long label takes more room instead of being shrunk smaller than the
  /// rest. Only if even that doesn't fit do they fall back to equal widths
  /// (and the labels scale down).
  List<double> _tabWidths(BuildContext context, double available) {
    final share = available / tabs.length;
    final natural = [
      for (final t in tabs)
        () {
          final painter = TextPainter(
            text: TextSpan(text: t.label, style: _labelStyle(true)),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final width =
              painter.width + _iconSize + _iconGap + _tabPadding * 2 + 1;
          painter.dispose();
          return width;
        }(),
    ];
    final total = natural.fold<double>(0, (a, b) => a + b);
    if (natural.every((w) => w <= share) || total > available) {
      return List.filled(tabs.length, share);
    }
    final extra = (available - total) / tabs.length;
    return [for (final w in natural) w + extra];
  }

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widths = _tabWidths(context, constraints.maxWidth);
          return Stack(
            children: [
              // Full-width line along the bottom: the same gradient as the
              // selected tab's underline, thinner and softer so that one
              // stands out.
              if (showBaseline)
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
                    SizedBox(
                      width: widths[i],
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: _tabPadding,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    if (t.asset != null)
                                      Image.asset(
                                        t.asset!,
                                        width: _iconSize,
                                        height: _iconSize,
                                        color: i == selected ? primary : muted,
                                      )
                                    else
                                      Icon(
                                        t.icon,
                                        size: 18,
                                        color: i == selected ? primary : muted,
                                      ),
                                    const Gap(_iconGap),
                                    Text(
                                      t.label,
                                      style: _labelStyle(i == selected)
                                          .copyWith(
                                            color: i == selected
                                                ? primary
                                                : muted,
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
          );
        },
      ),
    );
  }
}

/// Small round button on the page (not the cover), e.g. QR or Menu: a
/// soft shadow instead of a border, and the icon ([asset]) filled with
/// the brand gradient.
class ProfileRaisedCircleButton extends StatelessWidget {
  final String asset;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;

  /// A solid icon colour instead of the brand gradient.
  final Color? iconColor;

  /// The circle's diameter.
  final double size;
  const ProfileRaisedCircleButton({
    required this.asset,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 20,
    this.iconColor,
    this.size = ProfileTheme.headerButtonSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: ProfileTheme.purple.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: iconColor != null
              ? Image.asset(
                  asset,
                  width: iconSize,
                  height: iconSize,
                  color: iconColor,
                )
              // White icon used as a mask, filled with the brand gradient.
              : ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: ProfileTheme.brandGradient.createShader,
                  child: Image.asset(
                    asset,
                    width: iconSize,
                    height: iconSize,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Just a link's brand logo ([asset]), or the name's [initial] in a soft
/// circle when there's none; [label] is the tooltip / screen-reader label.
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

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: asset != null
              ? Image.asset(asset!, width: _size, height: _size)
              : Container(
                  width: _size,
                  height: _size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProfileTheme.textSecondary(
                      context,
                    ).withValues(alpha: 0.12),
                  ),
                  child: Text(
                    (initial ?? '?').characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round white camera button laid on the cover photo (the owner's view);
/// also the avatar's "change photo" badge.
class ProfileChangeCoverButton extends StatelessWidget {
  final VoidCallback onTap;

  /// Diameter; the icon is half of it.
  final double size;
  final String tooltip;
  const ProfileChangeCoverButton({
    required this.onTap,
    this.size = ProfileTheme.headerButtonSize,
    this.tooltip = 'Change cover',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
