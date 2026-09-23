// lib/core/components/avatar/user_avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

class ImageUserCircleProfile extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;

  const ImageUserCircleProfile({
    this.imageUrl,
    this.name,
    this.size = 40,
    super.key,
  });

  String get _initials {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _FallbackAvatar(size: size, initials: _initials);
    }

    return ClipOval(
      child: Image(
        image: CachedNetworkImageProvider(imageUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true, // keeps old image visible while new one loads
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // fully loaded
          return _LoadingAvatar(size: size);
        },
        errorBuilder: (context, error, stackTrace) =>
            _FallbackAvatar(size: size, initials: _initials),
      ),
    );
  }
}

class _LoadingAvatar extends StatelessWidget {
  final double size;
  const _LoadingAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightGrey.withValues(alpha: 0.15),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.lightGrey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final double size;
  final String initials;
  const _FallbackAvatar({required this.size, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sc(size),
      height: context.sc(size),
      decoration: BoxDecoration(shape: BoxShape.circle),

      child: Center(child: Image.asset("assets/company/app_logo_small.png")),
    );
  }
}
