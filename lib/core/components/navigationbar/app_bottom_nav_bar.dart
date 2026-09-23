// lib/core/components/navigation/app_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/themes/app_themes_mode.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'gradient_ring_button.dart';
import 'nav_item.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;
  final String? avatarUrl;

  /// A background video upload is compressing/uploading.
  final bool uploadBusy;

  /// Upload progress 0..1 while uploading; null while compressing
  /// (indeterminate).
  final double? uploadProgress;

  /// The last background upload failed — the create button turns into a
  /// retry affordance.
  final bool uploadError;

  /// The last background upload just succeeded — briefly shown before reset.
  final bool uploadSuccess;

  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCreateTap,
    this.avatarUrl,
    this.uploadBusy = false,
    this.uploadProgress,
    this.uploadError = false,
    this.uploadSuccess = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.sym(h: 16),
      height: context.sc(50),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NavItem(
            imagePath: AssetsName.navHome,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          NavItem(
            imagePath: AssetsName.navSearch,
            label: 'Search',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _CreateButton(
            onTap: onCreateTap,
            busy: uploadBusy,
            progress: uploadProgress,
            error: uploadError,
            success: uploadSuccess,
          ),
          NavItem(
            imagePath: AssetsName.navNotification,
            label: 'Notification',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImageUserCircleProfile(imageUrl: avatarUrl, size: 22),
                Gap(context.sc(2)),
                currentIndex == 3
                    ? GradientText(
                        "Profile",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: fs(12),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        "Profile",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: fs(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The center "create" button. Normally just the gradient ring; while a
/// background upload is running it wears a progress ring (green on success,
/// red on failure).
class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;
  final double? progress;
  final bool error;
  final bool success;

  const _CreateButton({
    required this.onTap,
    required this.busy,
    required this.progress,
    required this.error,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final showRing = busy || error || success;
    final ringColor = error
        ? Colors.red
        : success
        ? Colors.green
        : AppColors.boldColor(AppColors.appPrimaryBlue);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showRing)
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                // Determinate only while we have a real upload percentage.
                value: (error || success) ? 1.0 : progress,
                valueColor: AlwaysStoppedAnimation(ringColor),
                backgroundColor: AppColors.lightGrey.withValues(alpha: 0.15),
              ),
            ),
          GradientRingButton(imagePath: AssetsName.navAdd, onTap: onTap),
          if (error)
            const Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.refresh, size: 14, color: Colors.red),
            ),
        ],
      ),
    );
  }
}
