import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/navigationbar/nav_item.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/cat_head_path.dart';

/// The logo's cat head holding a profile photo, inside a thin pink → blue
/// line — the widget twin of the user marker on the restaurant map. With
/// no [imageUrl] (or while it loads, or if it fails) it's white with the
/// user icon.
class CatHeadAvatar extends StatelessWidget {
  final String? imageUrl;

  /// The head's width; its height follows the logo's proportions.
  final double width;

  const CatHeadAvatar({required this.imageUrl, this.width = 40, super.key});

  static const double _rim = 2;

  @override
  Widget build(BuildContext context) {
    final height = width / catHeadAspectRatio;
    final iconSize = width * 0.42;
    final url = imageUrl;
    final icon = ColoredBox(
      color: Colors.white,
      child: Align(
        // The middle of the face, below the ears.
        alignment: const Alignment(0, (catHeadFaceCenter - 0.5) * 2),
        child: Image.asset(
          AssetsName.user,
          width: iconSize,
          height: iconSize,
          color: ProfileTheme.ink,
          cacheWidth: (iconSize * MediaQuery.devicePixelRatioOf(context))
              .round(),
        ),
      ),
    );
    return SizedBox(
      width: width + _rim,
      height: height + _rim,
      child: CustomPaint(
        // The rim goes on top so it covers the photo's cut edge.
        foregroundPainter: const _RimPainter(),
        child: Padding(
          padding: const EdgeInsets.all(_rim / 2),
          child: ClipPath(
            clipper: const _HeadClipper(),
            child: url == null || url.trim().isEmpty
                ? icon
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth:
                        (width * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    placeholder: (_, _) => icon,
                    errorWidget: (_, _, _) => icon,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeadClipper extends CustomClipper<Path> {
  const _HeadClipper();

  @override
  Path getClip(Size size) => catHeadPath(Offset.zero & size);

  @override
  bool shouldReclip(_HeadClipper oldClipper) => false;
}

class _RimPainter extends CustomPainter {
  const _RimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const half = CatHeadAvatar._rim / 2;
    canvas.drawPath(
      catHeadPath(
        Rect.fromLTRB(half, half, size.width - half, size.height - half),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = CatHeadAvatar._rim
        ..strokeJoin = StrokeJoin.round
        ..shader = navGlowGradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => false;
}
