import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

/// The restaurant's own logo when it has one; otherwise a soft pastel
/// placeholder (colour picked deterministically per restaurant) so a list of
/// logo-less restaurants still reads as distinct pages rather than identical
/// grey boxes.
class RestaurantLogo extends StatelessWidget {
  final Restaurant restaurant;
  final double size;
  final double borderRadius;

  const RestaurantLogo({
    required this.restaurant,
    this.size = 48,
    this.borderRadius = 14,
    super.key,
  });

  static final _palette = [
    AppColors.appPrimaryPink,
    AppColors.appPrimaryBlue,
    const Color(0xffD9CBFB),
    const Color(0xffC9F2D9),
    const Color(0xffFCE3B6),
  ];

  @override
  Widget build(BuildContext context) {
    final url = restaurant.profilePicture;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
        ),
      );
    }

    final color = _palette[restaurant.id.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: size * 0.42,
        color: AppColors.boldColor(
          color,
          saturationBoost: 0.3,
          lightnessDrop: 0.3,
        ),
      ),
    );
  }
}
