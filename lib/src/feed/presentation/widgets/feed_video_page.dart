// lib/features/feed/presentation/widgets/feed_video_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:video_player/video_player.dart';
import '../../domain/video_feed_item.dart';

/// Purely presentational — the controller's lifecycle (create, prefetch,
/// dispose, retry) is owned by [VideoControllerManager] one level up, so a
/// window of neighboring videos can be kept buffering ahead of time instead
/// of only ever starting on-demand when a page becomes visible.
class FeedVideoPage extends StatefulWidget {
  final VideoFeedItem item;
  final VideoPlayerController? controller;
  final bool failed;
  final VoidCallback onRetry;

  /// Fires on every double-tap, regardless of current like state — the
  /// caller decides whether that should actually submit a like (double-tap
  /// conventionally only ever *adds* a like, it doesn't unlike).
  final VoidCallback onDoubleTapLike;

  const FeedVideoPage({
    required this.item,
    required this.controller,
    required this.failed,
    required this.onRetry,
    required this.onDoubleTapLike,
    super.key,
  });

  @override
  State<FeedVideoPage> createState() => _FeedVideoPageState();
}

class _FeedVideoPageState extends State<FeedVideoPage> {
  Offset? _burstPosition;
  int _burstKey = 0;

  void _handleDoubleTapDown(TapDownDetails details) {
    setState(() {
      _burstPosition = details.localPosition;
      _burstKey++;
    });
    widget.onDoubleTapLike();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.failed) {
      return _ErrorPlaceholder(onRetry: widget.onRetry);
    }

    final ctrl = widget.controller;
    if (ctrl == null) {
      return _LoadingPlaceholder(thumbnailUrl: widget.item.thumbnailUrl);
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return _LoadingPlaceholder(thumbnailUrl: widget.item.thumbnailUrl);
        }
        return GestureDetector(
          onTap: () => value.isPlaying ? ctrl.pause() : ctrl.play(),
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: () {}, // required for onDoubleTapDown to be recognized
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(ctrl),
                  ),
                ),
              ),
              // Paused state gets a persistent tap-to-resume indicator,
              // same as most video apps — nothing shows while playing.
              if (!value.isPlaying)
                Center(
                  child: AnimatedOpacity(
                    opacity: 0.5,
                    duration: const Duration(milliseconds: 150),
                    child: Image.asset(
                      AssetsName.playone,
                      width: context.sc(50),
                      height: context.sc(50),
                      color: Colors.white,
                    ),
                  ),
                ),
              if (_burstPosition != null)
                _HeartBurst(
                  key: ValueKey(_burstKey),
                  position: _burstPosition!,
                  onCompleted: () {
                    if (mounted) setState(() => _burstPosition = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The heart that pops up, briefly grows past full size, settles back, holds,
/// then fades — centered on wherever the user double-tapped.
class _HeartBurst extends StatefulWidget {
  final Offset position;
  final VoidCallback onCompleted;
  const _HeartBurst({
    required this.position,
    required this.onCompleted,
    super.key,
  });

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  static const _size = 110.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - _size / 2,
      top: widget.position.dy - _size / 2,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              AssetsName.heart,
              width: _size,
              height: _size,
              color: Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final String? thumbnailUrl;
  const _LoadingPlaceholder({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: thumbnailUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        const Center(child: CircularProgressIndicator(color: Colors.white54)),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Couldn\'t load this video',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
