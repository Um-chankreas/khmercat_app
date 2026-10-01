import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Pink → purple → blue call-to-action with a leading icon, press-scale and
/// a hover lift. A null [onTap] renders it muted.
class ProfileGradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  /// No shadow — for flat, minimal layouts.
  final bool flat;
  const ProfileGradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.height = 48,
    this.fontSize = 15.5,
    this.flat = false,
    super.key,
  });

  @override
  State<ProfileGradientButton> createState() => _ProfileGradientButtonState();
}

class _ProfileGradientButtonState extends State<ProfileGradientButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.015 : 1),
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: enabled ? ProfileTheme.gradient : null,
              color: enabled
                  ? null
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled && !widget.flat
                  ? [
                      BoxShadow(
                        color: ProfileTheme.purple.withValues(
                          alpha: _hovered ? 0.30 : 0.20,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: widget.fontSize + 3.5,
                  color: Colors.white,
                ),
                const Gap(8),
                Flexible(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White button with a purple outline, an icon, and a press-scale + tint.
class ProfileOutlineButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  const ProfileOutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.height = 48,
    this.fontSize = 15.5,
    super.key,
  });

  @override
  State<ProfileOutlineButton> createState() => _ProfileOutlineButtonState();
}

class _ProfileOutlineButtonState extends State<ProfileOutlineButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: (_pressed || _hovered)
                  ? ProfileTheme.purple.withValues(alpha: 0.08)
                  : ProfileTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ProfileTheme.purple.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: widget.fontSize + 3.5,
                  color: ProfileTheme.deepPurple,
                ),
                const Gap(8),
                Flexible(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Follow / Following toggle: gradient call-to-action when not following,
/// outlined check when following, cross-faded between the two.
class ProfileFollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const ProfileFollowButton({
    required this.isFollowing,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      // Unkeyed so a fast double-tap (follow -> following -> follow) can't
      // put two 'follow' buttons in the Stack at once ("Duplicate keys").
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isFollowing
          ? ProfileOutlineButton(
              key: const ValueKey('following'),
              text: 'Following',
              icon: Icons.check_rounded,
              onTap: onTap,
            )
          : ProfileGradientButton(
              key: const ValueKey('follow'),
              text: 'Follow',
              icon: Icons.person_add_alt_1_rounded,
              onTap: onTap,
            ),
    );
  }
}

/// One read-only line of profile info: a plain grey icon, a small grey label
/// and the value. Sits in a flat group, like the Settings screen's rows.
class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: muted),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: muted)),
                const Gap(2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
