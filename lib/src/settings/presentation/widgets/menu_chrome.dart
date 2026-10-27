import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

// The look shared by the Menu screen and the screens it opens: backdrop,
// title bar, and translucent cards of rows.

/// Dark pink used for text actions ("See all").
const menuAccent = Color(0xffB0125A);

/// Pale pink → lavender → blue wash with the logo's cat head faded into the
/// top-right corner. Dark mode keeps the plain page color and a faint cat.
class MenuBackdrop extends StatelessWidget {
  /// Plain white (the page color in dark mode) instead of the pink → blue
  /// wash; just the faded cat.
  final bool plain;
  const MenuBackdrop({this.plain = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = (MediaQuery.sizeOf(context).width * 0.8).clamp(260.0, 420.0);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: plain
              ? (isDark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.white)
              : null,
          gradient: isDark || plain
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xffFDE7F1),
                    Color(0xffF6F1FC),
                    Color(0xffEAF1FE),
                  ],
                ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -cat * 0.22,
              top: -cat * 0.12,
              width: cat,
              child: RepaintBoundary(
                child: Image.asset(
                  AssetsName.appLogoTrsm,
                  opacity: AlwaysStoppedAnimation(isDark ? 0.06 : 0.16),
                  // Decoded at on-screen size, not the 1198px source.
                  cacheWidth: (cat * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Off-white with three large, soft pastel circles — lavender top-left,
/// pink on the right, pink → lavender bottom-left (as on New Post).
class SoftCirclesBackdrop extends StatelessWidget {
  const SoftCirclesBackdrop({super.key});

  static const _pink = Color(0xffF4C6DC);
  static const _lavender = Color(0xffD9D6F3);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.10 : 0.35;

    Widget circle({
      required double size,
      required List<Color> colors,
      double? left,
      double? right,
      double? top,
      double? bottom,
    }) => Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [for (final c in colors) c.withValues(alpha: alpha)],
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return ColoredBox(
            color: isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xffFAFAFB),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                circle(
                  size: w * 1.15,
                  left: -w * 0.5,
                  top: -w * 0.42,
                  colors: [_lavender, const Color(0xffDDE7F8)],
                ),
                circle(
                  size: w * 0.8,
                  right: -w * 0.45,
                  top: h * 0.3,
                  colors: [_pink, _lavender],
                ),
                circle(
                  size: w * 1.1,
                  left: -w * 0.48,
                  bottom: -w * 0.55,
                  colors: [_pink, _lavender],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Back arrow with the title centered on the screen.
class MenuTitleBar extends StatelessWidget {
  final String title;
  const MenuTitleBar({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: primary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.3,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent rounded card: an optional small title (with an optional text
/// action on the right) over rows separated by hairlines.
class MenuCard extends StatelessWidget {
  final String? title;
  final (String, VoidCallback)? action;
  final List<Widget> children;

  /// Draw a hairline around the card, for when it sits on a plain page
  /// instead of the tinted backdrop (where its white rim is enough).
  final bool outlined;
  const MenuCard({
    required this.children,
    this.title,
    this.action,
    this.outlined = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = ProfileTheme.hairlineColor(context);
    return Container(
      decoration: BoxDecoration(
        // Slightly see-through so the backdrop tints it.
        color: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: isDark ? 1 : 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark || outlined
              ? line
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ),
                  if (action != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: action!.$2,
                      child: Text(
                        action!.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: menuAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: line,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Leading widget (an avatar, or a plain line icon), title, optional
/// subtitle, and a trailing widget — a chevron by default.
class MenuRow extends StatelessWidget {
  final Widget leading;
  final String title;

  /// Rendered in the muted subtitle style.
  final Widget? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback onTap;
  const MenuRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.titleColor,
    super.key,
  });

  /// A row led by a line icon; [color] also tints the title (destructive
  /// rows).
  factory MenuRow.icon({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    Color? color,
  }) => MenuRow(
    leading: SizedBox(
      width: leadingSize,
      height: leadingSize,
      child: Builder(
        builder: (context) => Icon(
          icon,
          size: 23,
          color: color ?? ProfileTheme.textPrimary(context),
        ),
      ),
    ),
    title: title,
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: trailing,
    titleColor: color,
    onTap: onTap,
  );

  static const double leadingSize = 40;

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            leading,
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? ProfileTheme.textPrimary(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(2),
                    DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: muted),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const Gap(8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: ProfileTheme.textPrimary(context),
                ),
          ],
        ),
      ),
    );
  }
}
