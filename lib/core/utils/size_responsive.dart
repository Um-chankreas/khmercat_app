import 'package:flutter/material.dart';

extension SizeResponsive on BuildContext {
  // 1. Get the scale factor (Shortest side logic)
  double get _scale => MediaQuery.of(this).size.shortestSide / 375;

  // 2. Scale any double (Height, Width, Radius)
  double s(double value) => value * _scale;

  // 3. Scale with safety limits (Best for Buttons)
  double sc(double value, {double? min, double? max}) {
    double scaled = value * _scale;
    if (min != null && scaled < min) return min;
    if (max != null && scaled > max) return max;
    return scaled;
  }

  // 4. Responsive Padding/Margins
  EdgeInsets all(double value) => EdgeInsets.all(value * _scale);

  EdgeInsets sym({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h * _scale, vertical: v * _scale);

  // 5. Screen Type Check
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;
  double sw(double value, {double? min, double? max}) {
    double scaleFactor = MediaQuery.of(this).size.shortestSide / 375;
    double scaled = value * scaleFactor;

    if (min != null && scaled < min) return min;
    if (max != null && scaled > max) return max;
    return scaled;
  }
}
