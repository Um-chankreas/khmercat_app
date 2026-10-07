// lib/core/components/navigation/cat_create_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nav_item.dart';

/// The center "create" button: a glowing cat-head outline with a plus
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

  /// The bar is over a light page: deeper colors, fainter halo.
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

  static const Size size = Size(44, 38);

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
                    padding: const EdgeInsets.only(top: 6),
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

/// Cat-head silhouette (round face, two ears) as a neon line: a blurred
/// gradient stroke for the halo, a crisp one on top.
class _CatOutlinePainter extends CustomPainter {
  final bool showPlus;
  final bool onLight;
  const _CatOutlinePainter({required this.showPlus, required this.onLight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Inset so the halo isn't clipped at the edges.
    const pad = 3.0;
    final face = Rect.fromLTRB(pad, h * 0.24, w - pad, h - pad);

    Path ear(bool left) {
      double x(double f) => left ? pad + f * w : w - pad - f * w;
      return Path()
        ..moveTo(x(0.02), h * 0.56)
        ..lineTo(x(0.06), h * 0.10)
        ..quadraticBezierTo(x(0.08), h * 0.03, x(0.15), h * 0.08)
        ..lineTo(x(0.40), h * 0.30)
        ..close();
    }

    var head = Path()
      ..addRRect(RRect.fromRectAndRadius(face, Radius.circular(h * 0.36)));
    head = Path.combine(PathOperation.union, head, ear(true));
    head = Path.combine(PathOperation.union, head, ear(false));

    final path = Path()..addPath(head, Offset.zero);
    if (showPlus) {
      final c = Offset(w / 2, face.center.dy + 1);
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

    // The halo; on a light page it's drawn much fainter so the line stays
    // crisp instead of fuzzy.
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: onLight ? 0.25 : 0.55),
    );
    canvas.drawPath(
      path,
      line
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      line
        ..strokeWidth = 1.7
        ..maskFilter = null,
    );
  }

  @override
  bool shouldRepaint(_CatOutlinePainter old) =>
      old.showPlus != showPlus || old.onLight != onLight;
}
