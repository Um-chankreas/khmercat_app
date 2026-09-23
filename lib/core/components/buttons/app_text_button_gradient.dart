import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

class AppTextButtonGradient extends StatelessWidget {
  final String text;
  final double? width;
  final double height;
  final String? asset;
  final void Function()? onTap;
  final BorderRadiusGeometry? borderRadius;
  final bool isLoading;

  const AppTextButtonGradient({
    super.key,
    required this.text,

    required this.height,
    this.isLoading = false,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffFF54AB), Color(0xff74BFFF)],
          ),
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitFadingCircle(
                      size: context.sc(25),
                      color: Colors.white,
                    ),
                    Gap(context.sc(5)),
                    Text(
                      text,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(color: Colors.white),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
