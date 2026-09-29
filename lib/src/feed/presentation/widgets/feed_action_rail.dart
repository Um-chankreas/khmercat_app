// lib/features/feed/presentation/widgets/feed_action_rail.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import '../../domain/video_feed_item.dart';

// Highlight colour per button, and the light neutral used when idle.
const _likeColor = Color(0xffFF1493);
const _commentColor = Color(0xff3498DB);
const _saveColor = Color(0xffDA70D6);
const _shareColor = Color(0xff9370DB);
const _idleColor = Color(0xffE6E6E6);
const _purple = Color(0xff9B6BFF);
const _pink = Color(0xffFF54AB);

/// Reviewer avatar (with a follow badge) + like / comment / save / share
/// rail. Each button sits on a frosted circle and bounces when tapped. The
/// icon takes its highlight colour the instant it's pressed; like and save
/// then stay coloured while on (liked / saved), and comment and share stay
/// coloured while their sheet is open.
class FeedActionRail extends StatelessWidget {
  final VideoFeedItem item;
  final VoidCallback onLike;
  final FutureOr<void> Function() onComment;
  final VoidCallback onSave;
  final FutureOr<void> Function() onShare;
  final VoidCallback onFollowTap;
  final VoidCallback onAvatarTap;

  const FeedActionRail({
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onFollowTap,
    required this.onAvatarTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _AvatarWithFollowBadge(
          imageUrl: item.user.profilePicture,
          name: item.user.username,
          following: item.isFollowingRestaurant,
          onAvatarTap: onAvatarTap,
          onFollowTap: onFollowTap,
        ),
        Gap(context.sc(14)),
        _ActionButton(
          iconAsset: AssetsName.heart,
          active: item.likedByMe,
          activeColor: _likeColor,
          label: formatCount(item.likesCount),
          onTap: onLike,
        ),
        Gap(context.sc(8)),
        _ActionButton(
          iconAsset: AssetsName.comment,
          activeColor: _commentColor,
          holdWhileBusy: true,
          label: formatCount(item.commentsCount),
          onTap: onComment,
        ),
        Gap(context.sc(8)),
        _ActionButton(
          iconAsset: item.savedByMe
              ? AssetsName.bookmark
              : AssetsName.bookmarkout,
          active: item.savedByMe,
          activeColor: _saveColor,

          label: '24',
          onTap: onSave,
        ),
        Gap(context.sc(8)),
        _ActionButton(
          iconAsset: AssetsName.share,
          activeColor: _shareColor,
          holdWhileBusy: true,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }
}

/// The reviewer's avatar, with a small "+" follow badge overlapping its
/// bottom-right edge — hidden once already following, same as Instagram
/// Reels. Tapping the avatar itself is a separate action (opens the
/// profile) from tapping the badge (follows).
class _AvatarWithFollowBadge extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool following;
  final VoidCallback onAvatarTap;
  final VoidCallback onFollowTap;

  const _AvatarWithFollowBadge({
    required this.imageUrl,
    required this.name,
    required this.following,
    required this.onAvatarTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.sc(44);
    return SizedBox(
      width: size,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              padding: const EdgeInsets.all(1.5),
              child: ImageUserCircleProfile(
                imageUrl: imageUrl,
                name: name,
                size: size - 3,
              ),
            ),
          ),
          if (!following)
            Positioned(
              bottom: -6,
              left: size / 2 - 10,
              child: GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_pink, _purple]),
                    boxShadow: [
                      BoxShadow(color: Colors.black38, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String iconAsset;
  final bool active;
  final Color activeColor;

  /// Count under the icon; null for buttons that show no text (save, share).
  final String? label;
  final FutureOr<void> Function() onTap;

  /// Keep the highlight while [onTap]'s future is pending (e.g. a bottom
  /// sheet that's still open) — for buttons with no on/off state of their own.
  final bool holdWhileBusy;

  const _ActionButton({
    required this.iconAsset,
    this.active = false,
    this.activeColor = _idleColor,
    this.label,
    this.holdWhileBusy = false,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.78), weight: 25),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.78,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
  ]);

  bool _pressed = false;
  bool _busy = false;

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    _bounce.forward(from: 0);
    final result = widget.onTap();
    if (widget.holdWhileBusy && result is Future) {
      setState(() => _busy = true);
      try {
        await result;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || _pressed || _busy;
    final color = highlighted ? widget.activeColor : _idleColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _tap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale.animate(_bounce),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: context.sc(35),
              height: context.sc(35),
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: Colors.black.withValues(alpha: 0.30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Center(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: const Duration(milliseconds: 160),
                  builder: (context, c, _) => Image.asset(
                    widget.iconAsset,
                    width: context.sc(18),
                    height: context.sc(18),
                    color: c,
                  ),
                ),
              ),
            ),
          ),
          if (widget.label != null) ...[
            Gap(context.sc(3)),
            Text(
              widget.label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
