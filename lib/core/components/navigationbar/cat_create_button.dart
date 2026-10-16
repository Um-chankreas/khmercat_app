// lib/core/components/navigation/cat_create_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khmer_cat_app/core/utils/cat_head_path.dart';

import 'nav_item.dart';

/// The center "create" button: a gradient cat-head outline with a plus
/// inside. While a background upload runs the plus becomes a progress ring
/// (a green tick on success, a red retry arrow on failure).
class CatCreateButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool busy;

  /// Upload progress 0..1; null while compressing (indeterminate).
  final double? progress;
  final bool error;
  final bool success;

  /// The bar is over a light page: deeper colors.
  final bool onLight;

  const CatCreateButton({
    required this.onTap,
    required this.label,
    this.busy = false,
    this.progress,
    this.error = false,
    this.success = false,
    this.onLight = false,
    super.key,
  });

  // The logo's head is a touch wider than tall (about 1.08 : 1).
  static const Size size = Size(43, 40);

  @override
  State<CatCreateButton> createState() => _CatCreateButtonState();
}

class _CatCreateButtonState extends State<CatCreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final Widget inner;
    if (w.error) {
      inner = const Icon(
        Icons.refresh_rounded,
        key: ValueKey('error'),
        size: 16,
        color: Color(0xffFF5A5F),
      );
    } else if (w.success) {
      inner = const Icon(
        Icons.check_rounded,
        key: ValueKey('success'),
        size: 16,
        color: Color(0xff3DDC84),
      );
    } else if (w.busy) {
      inner = SizedBox(
        key: const ValueKey('busy'),
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Determinate only while we have a real upload percentage.
          value: w.progress,
          valueColor: AlwaysStoppedAnimation(
            (w.onLight ? navInkColors : navGlowColors).last,
          ),
          backgroundColor: (w.onLight ? Colors.black : Colors.white).withValues(
            alpha: w.onLight ? 0.08 : 0.25,
          ),
        ),
      );
    } else {
      inner = const SizedBox.shrink(key: ValueKey('plus'));
    }

    return Semantics(
      button: true,
      label: w.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          w.onTap();
        },
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            // Quick squeeze in, springy release.
            duration: Duration(milliseconds: _pressed ? 90 : 280),
            curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
            child: SizedBox.fromSize(
              size: CatCreateButton.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Painted once; the plus is part of the painting unless a
                  // status icon takes its place.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CatOutlinePainter(
                          showPlus: !(w.busy || w.error || w.success),
                          onLight: w.onLight,
                        ),
                      ),
                    ),
                  ),
                  // Sits where the plus is: the face, below the ears.
                  Padding(
                    // Twice the offset: Stack centers what's left.
                    padding: EdgeInsets.only(
                      top:
                          CatCreateButton.size.height *
                          (catHeadFaceCenter - 0.5) *
                          2,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: inner,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app logo's cat-head outline (upright ears, wide round face) as a
/// crisp gradient line, with no glow behind it.
class _CatOutlinePainter extends CustomPainter {
  final bool showPlus;
  final bool onLight;
  const _CatOutlinePainter({required this.showPlus, required this.onLight});

  @override
  void paint(Canvas canvas, Size size) {
    // Inset so the stroke isn't clipped at the edges.
    const pad = 3.0;
    final head = Rect.fromLTRB(pad, pad, size.width - pad, size.height - pad);
    final path = catHeadPath(head);
    if (showPlus) {
      final c = Offset(
        size.width / 2,
        head.top + head.height * catHeadFaceCenter,
      );
      const arm = 5.0;
      path
        ..moveTo(c.dx - arm, c.dy)
        ..lineTo(c.dx + arm, c.dy)
        ..moveTo(c.dx, c.dy - arm)
        ..lineTo(c.dx, c.dy + arm);
    }

    final shader = navGradient(
      onLight: onLight,
    ).createShader(Offset.zero & size);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;

    canvas.drawPath(path, line..strokeWidth = 1.7);
  }

  @override
  bool shouldRepaint(_CatOutlinePainter old) =>
      old.showPlus != showPlus || old.onLight != onLight;
}
