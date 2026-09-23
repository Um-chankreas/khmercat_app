// lib/features/feed/presentation/widgets/feed_action_rail.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import '../../domain/video_feed_item.dart';

// Highlight colour per button, and the light neutral used when idle.
const _likeColor = Color(0xffFF1493);
const _commentColor = Color(0xff3498DB);
const _saveColor = Color(0xffDA70D6);
const _shareColor = Color(0xff9370DB);
const _idleColor = Color(0xffE6E6E6);

/// Like / comment / save / share rail. Each button sits on a frosted circle
/// and bounces when tapped. The icon takes its highlight colour the instant
/// it's pressed; like and save then stay coloured while on (liked / saved),
/// and comment and share stay coloured while their sheet is open.
class FeedActionRail extends StatelessWidget {
  final VideoFeedItem item;
  final VoidCallback onLike;
  final FutureOr<void> Function() onComment;
  final VoidCallback onSave;
  final FutureOr<void> Function() onShare;

  const FeedActionRail({
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionButton(
          iconAsset: AssetsName.heart,
          active: item.likedByMe,
          activeColor: _likeColor,
          label: formatCount(item.likesCount),
          onTap: onLike,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          iconAsset: AssetsName.comment,
          activeColor: _commentColor,
          holdWhileBusy: true,
          label: formatCount(item.commentsCount),
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          iconAsset: item.savedByMe
              ? AssetsName.bookmark
              : AssetsName.bookmarkout,
          active: item.savedByMe,
          activeColor: _saveColor,
          onTap: onSave,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          iconAsset: AssetsName.share,
          activeColor: _shareColor,
          holdWhileBusy: true,
          onTap: onShare,
        ),
      ],
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Same neutral circle whether or not it's liked — the liked
                // state shows only in the icon's colour.
                color: Colors.black.withValues(alpha: 0.30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Center(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: const Duration(milliseconds: 160),
                  builder: (context, c, _) => Image.asset(
                    widget.iconAsset,
                    width: 20,
                    height: 20,
                    color: c,
                  ),
                ),
              ),
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 5),
            Text(
              widget.label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
