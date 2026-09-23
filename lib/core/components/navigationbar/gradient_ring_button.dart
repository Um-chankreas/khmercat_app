// lib/core/components/navigation/gradient_ring_button.dart
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';

class GradientRingButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  final double size;

  const GradientRingButton({
    required this.imagePath,
    required this.onTap,
    this.size = 34,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(1.5), // ring thickness
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.boldColor(AppColors.appPrimaryPink),
              AppColors.boldColor(AppColors.appPrimaryBlue),
            ],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors
                .white, // matches bar background — creates the ring effect
            shape: BoxShape.circle,
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.boldColor(AppColors.appPrimaryPink),
                  AppColors.boldColor(AppColors.appPrimaryBlue),
                ],
              ).createShader(bounds),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  imagePath,
                  width: size * 0.5,
                  height: size * 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
