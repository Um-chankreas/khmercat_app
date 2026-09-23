import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/extensions/safe_area_extension.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/verify_view_model.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerify extends HookConsumerWidget {
  final String userId; // passed in from RegisterScreen on navigation

  const OtpVerify({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpState = ref.watch(verifyEmailViewModelProvider);

    void handleResend() {
      ref.read(verifyEmailViewModelProvider.notifier).resend(userId: userId);
    }

    ref.listen(verifyEmailViewModelProvider, (previous, next) {
      // if (next.verified) {
      //   final user = ref.watch(currentUserProvider);
      //   if (user?.roleId.toString() == "3" && user?.restaurant == null) {
      //     AppRouter.router.pushReplacement(AppRoute.onboadingRestaurant.name);
      //   } else {
      //     if (user?.roleId.toString() == "2") {
      //       AppRouter.router.pushReplacement(AppRoute.onboadingNormalUser.name);
      //     }
      //   }
      // }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppService.showToast(next.errorMessage ?? "Opp something when wrong");
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      ),
      child: GestureDetector(
        onTap: () => AppService.dismissKeyboard(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          resizeToAvoidBottomInset: true,

          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.appPrimaryPink, AppColors.appPrimaryBlue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.toolbarHeight),

                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: context.sc(40),
                    width: context.sc(40),
                    margin: EdgeInsets.only(left: context.sc(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Padding(
                        padding: context.all(10),
                        child: Image.asset(AssetsName.back),
                      ),
                    ),
                  ),
                ),
                Gap(context.sc(16)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: context.sc(90),
                        height: context.sc(90),
                        padding: context.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          AssetsName.mail,
                          color: AppColors.lightGrey,
                        ),
                      ),
                      Gap(context.sc(16)),
                      Text(
                        "Verification Code",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: const Color(0xff303030),
                        ),
                      ),
                      Text(
                        "We send a 6 digit to your email",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(context.sc(16)),
                Padding(
                  padding: context.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: context.sym(h: 8, v: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MaterialPinField(
                          onCompleted: (value) => ref
                              .read(verifyEmailViewModelProvider.notifier)
                              .verify(userId: userId, code: value),
                          theme: MaterialPinTheme(
                            cellSize: Size(context.sc(45), context.sc(50)),
                            borderColor: Colors.transparent,
                            focusedBorderWidth: 0,
                            fillColor: AppColors.darkGray.withValues(
                              alpha: 0.1,
                            ),
                            filledBorderColor: AppColors.darkGray.withValues(
                              alpha: 0.1,
                            ),
                            filledFillColor: AppColors.darkGray.withValues(
                              alpha: 0.1,
                            ),
                            focusedFillColor: AppColors.darkGray.withValues(
                              alpha: 0.1,
                            ),
                            focusedBorderColor: AppColors.darkGray.withValues(
                              alpha: 0.1,
                            ),
                            cursorColor: AppColors.appPrimaryPink,
                            borderWidth: 0,
                          ),
                          length: 6,
                          // No theme parameter - automatically uses ThemeData
                        ),
                        Gap(context.sc(5)),
                        if (otpState.resendCooldownSeconds > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Resend in: ",
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: AppColors.lightGrey.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                              ),
                              Gap(context.sc(5)),
                              GradientText(
                                "${otpState.resendCooldownSeconds}s",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: handleResend,
                            child: GradientText(
                              otpState.isResending
                                  ? 'Sending...'
                                  : 'Resend code',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: AppColors.lightGrey.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                        // TextButton(
                        //   onPressed:
                        //       otpState.resendCooldownSeconds > 0 ||
                        //           otpState.isResending
                        //       ? null
                        //       : handleResend,
                        //   child: Text(
                        //     otpState.resendCooldownSeconds > 0
                        //         ? 'Resend in ${otpState.resendCooldownSeconds}s'
                        //         : otpState.isResending
                        //         ? 'Sending...'
                        //         : 'Resend code',
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
