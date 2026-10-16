import 'dart:ui';

// The left half of the app logo's head outline, traced from the artwork in
// fractions of its width and height, from the top of the head down to the
// chin. Two numbers are a line's end point; six are a cubic's two control
// points and end point.
const _start = [0.5, 0.085];
const _leftHalf = <List<double>>[
  // Top of the head, out to where the ear starts.
  [0.44, 0.085, 0.38, 0.095, 0.324, 0.116],
  // Inner edge of the ear, then around its rounded tip.
  [0.188, 0.014],
  [0.155, -0.008, 0.11, -0.004, 0.093, 0.04],
  // Outer edge of the ear, nearly upright.
  [0.07, 0.10, 0.055, 0.25, 0.067, 0.36],
  // The cheek bulging out below it.
  [0.03, 0.42, 0.003, 0.50, 0.003, 0.60],
  // Round the jaw and along the wide, flat chin.
  [0.003, 0.74, 0.09, 0.86, 0.207, 0.927],
  [0.30, 0.975, 0.40, 0.997, 0.5, 0.997],
];

/// The head's width divided by its height in the logo.
const catHeadAspectRatio = 1.08;

/// Where the middle of the face is, as a fraction of the head's height
/// (below the ears, so lower than the bounds' center).
const catHeadFaceCenter = 0.6;

/// The app logo's cat-head outline (upright ears, wide round face) as a
/// closed path filling [bounds].
Path catHeadPath(Rect bounds) {
  Offset p(double fx, double fy, {required bool mirror}) => Offset(
    bounds.left + (mirror ? 1 - fx : fx) * bounds.width,
    bounds.top + fy * bounds.height,
  );

  final start = p(_start[0], _start[1], mirror: false);
  final path = Path()..moveTo(start.dx, start.dy);
  // Down the left side.
  for (final s in _leftHalf) {
    final end = p(s[s.length - 2], s[s.length - 1], mirror: false);
    if (s.length == 2) {
      path.lineTo(end.dx, end.dy);
    } else {
      final a = p(s[0], s[1], mirror: false), b = p(s[2], s[3], mirror: false);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, end.dx, end.dy);
    }
  }
  // Back up the right side: the same segments mirrored, each run backwards
  // (so its control points swap).
  for (var i = _leftHalf.length - 1; i >= 0; i--) {
    final s = _leftHalf[i];
    final from = i == 0 ? _start : _leftHalf[i - 1];
    final end = p(from[from.length - 2], from[from.length - 1], mirror: true);
    if (s.length == 2) {
      path.lineTo(end.dx, end.dy);
    } else {
      final a = p(s[2], s[3], mirror: true), b = p(s[0], s[1], mirror: true);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, end.dx, end.dy);
    }
  }
  return path..close();
}
