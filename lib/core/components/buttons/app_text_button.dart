import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

class AppTextButton extends StatelessWidget {
  final String text;
  final double? width;
  final double height;
  final String? asset;
  final void Function()? onTap;
  final BorderRadiusGeometry? borderRadius;

  const AppTextButton({
    super.key,
    required this.text,

    required this.height,
    this.width,
    this.onTap,
    this.borderRadius,
    this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.sc(width ?? double.infinity),
        height: context.sc(height),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: GradientText(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
