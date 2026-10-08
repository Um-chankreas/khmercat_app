import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// TikTok-style playback bar: a thin line along the bottom of the video that
/// fills as it plays, thickens while you touch it, and can be dragged to
/// scrub.
///
/// Kept cheap on purpose. The player only reports its position a couple of
/// times a second, so a [Ticker] — running only while the video plays —
/// interpolates between reports for a smooth fill. Progress goes into a
/// [ValueNotifier] that only the [CustomPainter] listens to, so a frame
/// repaints a few pixels inside its own [RepaintBoundary] and rebuilds no
/// widgets.
class FeedProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  const FeedProgressBar({required this.controller, super.key});

  @override
  State<FeedProgressBar> createState() => _FeedProgressBarState();
}

class _FeedProgressBarState extends State<FeedProgressBar>
    with SingleTickerProviderStateMixin {
  static const _touchHeight = 28.0;

  late final Ticker _ticker = createTicker(_onTick);
  final _progress = ValueNotifier<double>(0);
  final _dragging = ValueNotifier<bool>(false);
  final _clock = Stopwatch()..start();

  // Last position the player reported, and when we heard it.
  Duration _basePosition = Duration.zero;
  Duration _baseAt = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1;
  bool _playing = false;

  bool _resumeAfterDrag = false;
  int _lastSeekMs = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(FeedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _ticker.dispose();
    _progress.dispose();
    _dragging.dispose();
    super.dispose();
  }

  void _sync() {
    final v = widget.controller.value;
    _basePosition = v.position;
    _baseAt = _clock.elapsed;
    _duration = v.duration;
    _speed = v.playbackSpeed;
    _playing = v.isPlaying && !v.isBuffering;
    if (_playing) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
      if (!_dragging.value) _update();
    }
  }

  void _onTick(Duration _) {
    if (!_dragging.value) _update();
  }

  void _update() {
    final total = _duration.inMilliseconds;
    if (total <= 0) {
      _progress.value = 0;
      return;
    }
    final elapsed = _playing ? (_clock.elapsed - _baseAt).inMilliseconds : 0;
    final pos = _basePosition.inMilliseconds + elapsed * _speed;
    _progress.value = (pos / total).clamp(0.0, 1.0);
  }

  void _dragStart(DragStartDetails d) {
    HapticFeedback.selectionClick();
    _resumeAfterDrag = widget.controller.value.isPlaying;
    _dragging.value = true;
    if (_resumeAfterDrag) widget.controller.pause();
  }

  void _dragUpdate(DragUpdateDetails d, double width) {
    if (_duration == Duration.zero || width <= 0) return;
    final f = (d.localPosition.dx / width).clamp(0.0, 1.0);
    _progress.value = f;
    // Seeking every frame can flood the player; ~12 per second is plenty.
    final now = _clock.elapsedMilliseconds;
    if (now - _lastSeekMs > 80) {
      _lastSeekMs = now;
      widget.controller.seekTo(_duration * f);
    }
  }

  Future<void> _dragEnd() async {
    await widget.controller.seekTo(_duration * _progress.value);
    _dragging.value = false;
    if (_resumeAfterDrag) widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _dragStart,
        onHorizontalDragUpdate: (d) => _dragUpdate(d, c.maxWidth),
        onHorizontalDragEnd: (_) => _dragEnd(),
        onHorizontalDragCancel: _dragEnd,
        child: SizedBox(
          height: _touchHeight,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BarPainter(progress: _progress, dragging: _dragging),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final ValueNotifier<double> progress;
  final ValueNotifier<bool> dragging;
  _BarPainter({required this.progress, required this.dragging})
    : super(repaint: Listenable.merge([progress, dragging]));

  static final _track = Paint()..color = const Color(0x40FFFFFF);
  static final _fill = Paint()..color = const Color(0xF2FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final h = dragging.value ? 5.0 : 2.5;
    final top = size.height - h;
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, h), _track);
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width * progress.value, h),
      _fill,
    );
    if (dragging.value) {
      // Thumb, so you can see where you are while scrubbing.
      canvas.drawCircle(
        Offset(size.width * progress.value, top + h / 2),
        6,
        _fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.dragging != dragging;
}
