import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const _posterGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xff2E2B5F), Color(0xff6B2A6E), Color(0xffA21D5C)],
);

/// The holiday poster itself (4:5): the owner's photo — or the brand's deep
/// navy → crimson gradient — with the restaurant's name, the headline and a
/// "Closed · Mon 9 Nov" pill on top. Text scales with the width, so the same
/// poster works as the form preview, the profile card and in the feed.
class HolidayPosterArt extends StatelessWidget {
  final String restaurantName;
  final String headline;
  final String pillLabel;
  final String? imageUrl;

  /// A just-picked image (the New poster preview), over [imageUrl].
  final File? imageFile;
  final double borderRadius;

  /// Drawn over the bottom-right corner (e.g. the preview's "Change").
  final Widget? corner;

  const HolidayPosterArt({
    required this.restaurantName,
    required this.headline,
    required this.pillLabel,
    this.imageUrl,
    this.imageFile,
    this.borderRadius = 22,
    this.corner,
    super.key,
  });

  static const aspectRatio = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageFile != null || (imageUrl?.isNotEmpty ?? false);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          // Sized for a 260px-wide poster.
          final k = box.maxWidth / 260;
          final w = box.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius * k.clamp(.6, 2)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageFile != null)
                  Image.file(imageFile!, fit: BoxFit.cover)
                else if (hasImage)
                  CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                else ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: _posterGradient),
                  ),
                  // Soft decorative circles, as on the design.
                  Positioned(
                    right: -w * 0.28,
                    top: -w * 0.22,
                    width: w * 0.75,
                    height: w * 0.75,
                    child: _Circle(alpha: 0.10),
                  ),
                  Positioned(
                    left: -w * 0.22,
                    bottom: -w * 0.3,
                    width: w * 0.7,
                    height: w * 0.7,
                    child: _Circle(alpha: 0.08),
                  ),
                ],
                if (hasImage)
                  // Keeps the text readable on any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3000000), Color(0x33000000)],
                        stops: [0, 0.75],
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22 * k, 26 * k, 22 * k, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11 * k,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2 * k,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 14 * k),
                      Text(
                        headline,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 29 * k,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5 * k,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16 * k),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * k,
                          vertical: 7 * k,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10 * k),
                        ),
                        child: Text(
                          pillLabel,
                          style: TextStyle(
                            fontSize: 13 * k,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (corner != null)
                  Positioned(right: 10 * k, bottom: 10 * k, child: corner!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double alpha;
  const _Circle({required this.alpha});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}
