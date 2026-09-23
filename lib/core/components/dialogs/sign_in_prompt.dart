// lib/core/components/dialogs/sign_in_prompt.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button_gradient.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

/// Gate for any guest-blocked action (like, comment, follow, upload).
/// Returns true immediately if already signed in; otherwise shows a
/// lightweight "sign in to continue" sheet and returns whether the user
/// followed through, so the browsing experience itself is never blocked.
Future<bool> requireLogin(
  BuildContext context,
  WidgetRef ref, {
  String message = 'Sign in to continue',
}) async {
  if (ref.read(isAuthenticatedProvider)) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => SignInPromptSheet(message: message),
  );
  return result ?? false;
}

class SignInPromptSheet extends StatelessWidget {
  final String message;
  const SignInPromptSheet({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(6),
            Text(
              'Create a free account to keep going.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.lightGrey),
            ),
            const Gap(24),
            AppTextButtonGradient(
              text: 'Sign in',
              height: 45,
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pop(true);
                AppRouter.router.pushNamed(AppRoute.login.name);
              },
            ),
            const Gap(10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not now',
                style: TextStyle(color: AppColors.lightGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
