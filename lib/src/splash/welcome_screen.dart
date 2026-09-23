import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

class WelcomeScreen extends HookWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    );

    useEffect(() {
      controller.repeat(reverse: true);
      return controller.dispose;
    }, [controller]);

    final scaleAnimation = useMemoized(
      () => Tween<double>(
        begin: 0.95,
        end: 1.05,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut)),
      [controller],
    );

    final rotationAnimation = useMemoized(
      () => Tween<double>(
        begin: -0.03,
        end: 0.03,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      [controller],
    );

    final scale = useAnimation(scaleAnimation);
    final rotation = useAnimation(rotationAnimation);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.appPrimaryPink,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.appPrimaryPink, AppColors.appPrimaryBlue],
                ),
              ),
              child: Padding(
                padding: context.sym(h: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          AssetsName.appLogoTrsm,
                          width: context.sc(150),
                        ),
                      ),
                    ),
                    Gap(context.sc(8)),
                    Text(
                      "Welcom To KhmerCat",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Gap(context.sc(7)),
                    Text(
                      "Choose an option to get started. You can add another account in any time.",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.lightGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: context.sc(14),
              right: context.sc(14),
              bottom: context.sc(28),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextButton(
                          onTap: () => AppRouter.router.pushNamed(
                            AppRoute.createAccount.name,
                            queryParameters: {"user_type": "normal_user"},
                          ),
                          text: "User",
                          height: 45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      Gap(context.sc(14)),
                      Expanded(
                        child: AppTextButton(
                          onTap: () => AppRouter.router.pushNamed(
                            AppRoute.createAccount.name,
                            queryParameters: {"user_type": "restaurant_user"},
                          ),
                          text: "Restaurant",
                          height: 45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                  Gap(context.sc(14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Already have an account?",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.lightGrey,
                        ),
                      ),
                      Gap(context.sc(5)),
                      GestureDetector(
                        onTap: () =>
                            AppRouter.router.pushNamed(AppRoute.login.name),
                        child: GradientText(
                          "Login",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
