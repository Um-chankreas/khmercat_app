import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

/// The map's own markers, in the app's primary colors: a pink pin with the
/// shop icon for restaurants, a blue pin with the user's photo (or the user
/// icon) for the spot the search is centered on.
class MapPins {
  final BitmapDescriptor restaurant;
  final BitmapDescriptor selectedRestaurant;
  final BitmapDescriptor user;

  const MapPins({
    required this.restaurant,
    required this.selectedRestaurant,
    required this.user,
  });

  /// Draws the pins for a screen of [devicePixelRatio]. With a
  /// [userPhotoUrl] the user pin shows that photo instead of the user icon
  /// (and falls back to the icon if it can't be loaded).
  static Future<MapPins> load(
    double devicePixelRatio, {
    String? userPhotoUrl,
  }) async {
    final photo = userPhotoUrl == null || userPhotoUrl.trim().isEmpty
        ? null
        : await _loadPhoto(
            userPhotoUrl,
            (_radius * 2 * devicePixelRatio).ceil(),
          );
    final pins = await Future.wait([
      _draw(AssetsName.shop, AppColors.appPrimaryPink, devicePixelRatio),
      // Selected: filled with the brand gradient, and a little larger.
      _draw(
        AssetsName.shop,
        ProfileTheme.pink,
        devicePixelRatio,
        scale: 1.2,
        ink: Colors.white,
        whiteRim: true,
        fill: ProfileTheme.gradient,
      ),
      _draw(
        AssetsName.user,
        AppColors.appPrimaryBlue,
        devicePixelRatio,
        photo: photo,
      ),
    ]);
    return MapPins(
      restaurant: pins[0],
      selectedRestaurant: pins[1],
      user: pins[2],
    );
  }

  // Radius of a pin's round head, in logical pixels.
  static const _radius = 19.0;

  /// The image at [url] (from the same cache the avatars use), or null if
  /// it doesn't load in time.
  static Future<ui.Image?> _loadPhoto(String url, int pixelSize) {
    final done = Completer<ui.Image?>();
    final stream = CachedNetworkImageProvider(
      url,
      maxWidth: pixelSize,
      maxHeight: pixelSize,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    void finish(ui.Image? image) {
      if (done.isCompleted) return;
      stream.removeListener(listener);
      done.complete(image);
    }

    listener = ImageStreamListener(
      (info, _) => finish(info.image.clone()),
      onError: (_, _) => finish(null),
    );
    stream.addListener(listener);
    return done.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        finish(null);
        return null;
      },
    );
  }

  static Future<BitmapDescriptor> _draw(
    String asset,
    Color color,
    double devicePixelRatio, {
    double scale = 1,
    // The brand colors are pale, so the icon is dark by default.
    Color ink = ProfileTheme.ink,
    // Otherwise the rim is the pink → purple → blue brand gradient.
    bool whiteRim = false,
    // Painted over the whole pin in place of the flat color.
    Gradient? fill,
    // Fills the round head in place of the icon.
    ui.Image? photo,
  }) async {
    // Logical size: a round head with a point underneath, whose tip is the
    // marker's anchor (bottom center).
    const width = 44.0, height = 56.0, radius = _radius, iconSize = 21.0;
    const head = Offset(width / 2, radius + 3);
    final pixelRatio = devicePixelRatio * scale;

    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (iconSize * pixelRatio).round(),
    );
    final icon = (await codec.getNextFrame()).image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    final shape = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCircle(center: head, radius: radius)),
      Path()
        ..moveTo(head.dx - 9, head.dy + radius - 5)
        ..lineTo(head.dx, height - 3)
        ..lineTo(head.dx + 9, head.dy + radius - 5)
        ..close(),
    );
    canvas
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white
          ..shader = whiteRim
              ? null
              : ProfileTheme.gradient.createShader(
                  const Rect.fromLTWH(0, 0, width, height),
                ),
      )
      ..drawPath(
        shape,
        Paint()
          ..color = color
          ..shader = fill?.createShader(
            const Rect.fromLTWH(0, 0, width, height),
          ),
      );
    if (photo != null) {
      // Center-cropped to a square, clipped to the head inside the rim.
      final side = photo.width < photo.height ? photo.width : photo.height;
      canvas
        ..save()
        ..clipPath(
          Path()..addOval(Rect.fromCircle(center: head, radius: radius - 2)),
        )
        ..drawImageRect(
          photo,
          Rect.fromCenter(
            center: Offset(photo.width / 2, photo.height / 2),
            width: side.toDouble(),
            height: side.toDouble(),
          ),
          Rect.fromCircle(center: head, radius: radius - 2),
          Paint()..filterQuality = FilterQuality.medium,
        )
        ..restore();
    } else {
      // The icons are line art on transparent: paint their shape in [ink].
      canvas.drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        Rect.fromCenter(center: head, width: iconSize, height: iconSize),
        Paint()
          ..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn)
          ..filterQuality = FilterQuality.medium,
      );
    }

    final image = await recorder.endRecording().toImage(
      (width * pixelRatio).ceil(),
      (height * pixelRatio).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width * scale,
      height: height * scale,
    );
  }
}
