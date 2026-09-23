import 'package:flutter/material.dart';

abstract class AppColors {
  static Color appPrimaryBlue = Color(0xffCBE7FF);
  static Color appPrimaryPink = Color(0xffF7C4DE);
  static Color whiteColor = Color(0xffFFFFFF);
  static Color darkColor = Color(0xff000000);
  static Color darkGray = Color(0xff121212);
  static Color lightBackground = Color(0xffF8FAFF);
  static Color lightGrey = Color(0xff444444);
  static const List<Color> brandGradientText = [
    Color(0xFFE066A8),
    Color(0xFF988EEB),
  ];

  static Color boldColor(
    Color color, {
    double saturationBoost = 0.15,
    double lightnessDrop = 0.05,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation + saturationBoost).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - lightnessDrop).clamp(0.0, 1.0))
        .toColor();
  }

  static LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [appPrimaryPink, appPrimaryBlue],
  );
  static LinearGradient backgroundGradientLR = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [appPrimaryPink, appPrimaryBlue],
  );
}
