// lib/core/components/dialogs/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button_gradient.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

class AppDialog extends StatelessWidget {
  final String? icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  const AppDialog({
    this.icon,
    this.iconColor,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText,
    this.onConfirm,
    this.isDestructive = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.appPrimaryPink).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(icon ?? "", color: iconColor),
              ),
              const Gap(16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.lightGrey),
            ),
            const Gap(24),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: AppColors.lightGrey.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        cancelText!,
                        style: TextStyle(color: AppColors.lightGrey),
                      ),
                    ),
                  ),
                  const Gap(12),
                ],
                Expanded(
                  child: isDestructive
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(confirmText),
                        )
                      : AppTextButtonGradient(
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm?.call();
                          },
                          text: confirmText,
                          height: 45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// lib/core/components/dialogs/app_dialog.dart — add below the class

class AppDialogs {
  /// Simple info/message dialog — single OK button, gradient style.
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    String icon = AssetsName.info,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AppDialog(
        icon: icon,
        title: title,
        message: message,
        confirmText: confirmText,
      ),
    );
  }

  /// Two-button confirm dialog — used for destructive actions like logout.
  static Future<void> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    String icon = AssetsName.question,
    bool isDestructive = false,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AppDialog(
        icon: icon,
        iconColor: isDestructive ? Colors.red.shade500 : null,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
    );
  }
}
