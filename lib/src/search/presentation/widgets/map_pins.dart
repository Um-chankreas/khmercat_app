import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khmer_cat_app/core/components/navigationbar/nav_item.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/cat_head_path.dart';

/// The map's own markers: the brand-gradient pin with the shop icon for
/// restaurants (larger when selected), and the logo's cat head holding the user's
/// photo (or the user icon) for the spot the search is centered on.
class MapPins {
  final BitmapDescriptor restaurant;
  final BitmapDescriptor selectedRestaurant;
  final BitmapDescriptor user;

  /// The user marker stands on its blue dot, which marks the position.
  static const userAnchor = Offset(0.5, _dotY / _pinHeight);

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
            (_userWidth * devicePixelRatio).ceil(),
          );
    final pins = await Future.wait([
      // Every restaurant: the brand-gradient pin with a white rim and shop
      // icon; the selected one is the same pin, a little larger.
      _draw(
        AssetsName.shop,
        ProfileTheme.pink,
        devicePixelRatio,
        ink: Colors.white,
        whiteRim: true,
        fill: ProfileTheme.gradient,
      ),
      _draw(
        AssetsName.shop,
        ProfileTheme.pink,
        devicePixelRatio,
        scale: 1.2,
        ink: Colors.white,
        whiteRim: true,
        fill: ProfileTheme.gradient,
      ),
      drawUserPin(devicePixelRatio, photo),
    ]);
    return MapPins(
      restaurant: pins[0],
      selectedRestaurant: pins[1],
      user: pins[2],
    );
  }

  // The cat head's size on the map, in logical pixels.
  static const _userWidth = 36.0;
  static const _userHeight = _userWidth / catHeadAspectRatio;

  // The user pin, like the address screen's: head (with its rim) on a
  // short stem, standing on a blue dot inside a soft halo.
  static const _rim = 2.0;
  static const _stem = 9.0;
  static const _dot = 13.0;
  static const _halo = 40.0;
  static const _headBox = _userHeight + _rim * 2;
  static const _dotY = _headBox + _stem;
  static const _pinWidth = _halo;
  static const _pinHeight = _dotY + _halo / 2;
  static const _blue = Color(0xff3B9DFF);

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
  }) async {
    // Logical size: a round head with a point underneath, whose tip is the
    // marker's anchor (bottom center).
    const width = 44.0, height = 56.0, radius = 19.0, iconSize = 21.0;
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
    // The icons are line art on transparent: paint their shape in [ink].
    canvas.drawImageRect(
      icon,
      Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
      Rect.fromCenter(center: head, width: iconSize, height: iconSize),
      Paint()
        ..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn)
        ..filterQuality = FilterQuality.medium,
    );

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

  /// The logo's cat head drawn like the nav bar's create button — a thin
  /// pink → blue line — and filled with [photo], or with white and the user
  /// icon when there's none; on a stem, standing on a blue dot.
  @visibleForTesting
  static Future<BitmapDescriptor> drawUserPin(
    double devicePixelRatio,
    ui.Image? photo,
  ) async {
    const rim = _rim, iconSize = 15.0;
    const width = _pinWidth, height = _pinHeight;
    const head = Rect.fromLTWH(
      (_pinWidth - _userWidth) / 2,
      rim,
      _userWidth,
      _userHeight,
    );
    final shape = catHeadPath(head);
    const dot = Offset(_pinWidth / 2, _dotY);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio);

    // Halo, stem and dot first; the head goes over the stem's top.
    canvas
      ..drawCircle(
        dot,
        _halo / 2,
        Paint()..color = _blue.withValues(alpha: 0.18),
      )
      ..drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(dot.dx - 1.25, _headBox - 2, 2.5, _stem + 2),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff9B8CFF), _blue],
          ).createShader(Rect.fromLTWH(dot.dx, _headBox, 1, _stem)),
      )
      ..drawCircle(
        dot,
        _dot / 2 + 1,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(dot, _dot / 2, Paint()..color = Colors.white)
      ..drawCircle(dot, _dot / 2 - 2.5, Paint()..color = _blue);

    canvas.drawPath(shape, Paint()..color = Colors.white);
    if (photo != null) {
      // Scaled to cover the head and cropped to its outline.
      final scale = [
        head.width / photo.width,
        head.height / photo.height,
      ].reduce((a, b) => a > b ? a : b);
      canvas
        ..save()
        ..clipPath(shape)
        ..drawImageRect(
          photo,
          Rect.fromCenter(
            center: Offset(photo.width / 2, photo.height / 2),
            width: head.width / scale,
            height: head.height / scale,
          ),
          head,
          Paint()..filterQuality = FilterQuality.medium,
        )
        ..restore();
    } else {
      final data = await rootBundle.load(AssetsName.user);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: (iconSize * devicePixelRatio).round(),
      );
      final icon = (await codec.getNextFrame()).image;
      canvas.drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        Rect.fromCenter(
          center: Offset(
            head.center.dx,
            head.top + head.height * catHeadFaceCenter,
          ),
          width: iconSize,
          height: iconSize,
        ),
        Paint()
          ..colorFilter = const ColorFilter.mode(
            ProfileTheme.ink,
            BlendMode.srcIn,
          )
          ..filterQuality = FilterQuality.medium,
      );
    }
    // The rim goes on last so it covers the photo's cut edge.
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..strokeJoin = StrokeJoin.round
        ..shader = navGlowGradient.createShader(head.inflate(rim)),
    );

    final image = await recorder.endRecording().toImage(
      (width * devicePixelRatio).ceil(),
      (height * devicePixelRatio).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }
}
