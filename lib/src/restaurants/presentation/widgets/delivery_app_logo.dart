import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

/// A delivery app's icon ([DeliveryApp.asset] is a full square app icon)
/// as a small rounded square, decoded at its on-screen size.
class DeliveryAppLogo extends StatelessWidget {
  final DeliveryApp app;
  final double size;
  const DeliveryAppLogo({required this.app, this.size = 28, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        app.asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}
