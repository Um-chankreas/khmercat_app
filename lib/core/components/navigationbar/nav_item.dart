// lib/core/components/navigation/nav_item.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/themes/app_themes_mode.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

class NavItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
    required this.imagePath,
    required this.label,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.appPrimaryPink : AppColors.lightGrey;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isActive
              ? ShaderMask(
                  blendMode: BlendMode.srcIn,
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
                      width: context.sc(22),
                      height: context.sc(22),
                    ),
                  ),
                )
              : ColorFiltered(
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  child: Image.asset(imagePath, width: 22, height: 22),
                ),
          Gap(context.sc(2)),
          isActive
              ? GradientText(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: color,
                    fontSize: fs(12),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: color,
                    fontSize: fs(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }
}
