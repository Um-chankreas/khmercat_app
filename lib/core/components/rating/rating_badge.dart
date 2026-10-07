// lib/core/components/rating/rating_badge.dart
import 'package:flutter/material.dart';

/// Read-only rating: a yellow star followed by the average, to one decimal
/// ("★ 4.5"). The number takes [style] merged over the surrounding text
/// style, so it can sit in a row, a subtitle or a pill over an image.
class RatingBadge extends StatelessWidget {
  final double rating;
  final double iconSize;
  final TextStyle? style;

  const RatingBadge({
    required this.rating,
    this.iconSize = 16,
    this.style,
    super.key,
  });

  static const Color starColor = Color(0xffFFB800);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: iconSize, color: starColor),
        SizedBox(width: iconSize * 0.18),
        Text(rating.toStringAsFixed(1), style: style),
      ],
    );
  }
}
