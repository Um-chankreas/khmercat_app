// lib/core/components/rating/star_rating_input.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _feedback = <int, (String emoji, String label)>{
  1: ('😞', 'Terrible'),
  2: ('😕', 'Could be better'),
  3: ('😐', 'It was okay'),
  4: ('😋', 'Really good!'),
  5: ('🤩', 'Absolutely amazing!'),
};

/// Tappable 1–5 star rating with a wave animation and emoji feedback.
/// [value] of 0 means "not rated yet". Tapping the selected star again
/// clears the rating.
class StarRatingInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  final double size;
  final Color activeColor;
  final bool enabled;

  /// Shows the emoji + caption under the stars.
  final bool showFeedback;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.size = 46,
    this.activeColor = const Color(0xffFFB800),
    this.enabled = true,
    this.showFeedback = true,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(StarRatingInput old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && widget.value > 0) _wave.forward(from: 0);
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  /// Scale for star [i]: a quick pop that ripples left → right.
  double _scaleFor(int i) {
    final start = (i * 0.09).clamp(0.0, 0.5);
    final t = ((_wave.value - start) / 0.5).clamp(0.0, 1.0);
    return 1 + 0.4 * math.sin(math.pi * t);
  }

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _wave,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.max, (i) {
              final star = i + 1;
              final selected = star <= widget.value;
              return Semantics(
                button: true,
                label: '$star star${star > 1 ? 's' : ''}',
                selected: star == widget.value,
                child: MouseRegion(
                  cursor: widget.enabled
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enabled
                        ? () {
                            HapticFeedback.selectionClick();
                            widget.onChanged(star == widget.value ? 0 : star);
                          }
                        : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.size * 0.05,
                      ),
                      child: Transform.scale(
                        scale: selected ? _scaleFor(i) : 1,
                        child: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: widget.size,
                          color: selected ? widget.activeColor : inactive,
                          shadows: selected
                              ? [
                                  Shadow(
                                    color: widget.activeColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (widget.showFeedback) ...[
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: _FeedbackRow(
              key: ValueKey(widget.value),
              value: widget.value,
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final int value;
  const _FeedbackRow({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final fb = _feedback[value];
    if (fb == null) {
      return SizedBox(
        height: 36,
        child: Center(
          child: Text(
            'Tap a star to rate',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fb.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Text(
            fb.$2,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff6B4EFF),
            ),
          ),
        ],
      ),
    );
  }
}
