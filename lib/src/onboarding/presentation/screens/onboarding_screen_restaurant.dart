// lib/features/onboarding/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button_gradient.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/extensions/safe_area_extension.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import '../../domain/onboarding_page_data.dart';

class OnboardingScreenRestaurant extends HookConsumerWidget {
  const OnboardingScreenRestaurant({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);

    void goToNext() {
      if (currentPage.value < onboardingPagesRestaurant.length - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _finishOnboarding(context);
      }
    }

    void skip() => _finishOnboarding(context);

    final isLastPage =
        currentPage.value == onboardingPagesRestaurant.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: context.sym(h: 16, v: 8),
                child: TextButton(
                  onPressed: skip,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: onboardingPagesRestaurant.length,
                onPageChanged: (index) => currentPage.value = index,
                itemBuilder: (context, index) {
                  final page = onboardingPagesRestaurant[index];
                  return _OnboardingPageContent(page: page);
                },
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingPagesRestaurant.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentPage.value == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: currentPage.value == index
                        ? LinearGradient(
                            colors: [
                              AppColors.appPrimaryPink,
                              AppColors.appPrimaryBlue,
                            ],
                          )
                        : null,
                    color: currentPage.value == index
                        ? null
                        : AppColors.lightGrey.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            Gap(context.sc(24)),

            // Next / Get started button
            Padding(
              padding: context.sym(h: 16),
              child: AppTextButtonGradient(
                onTap: goToNext,
                text: isLastPage ? 'Get Started' : 'Next',
                height: 45,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            Gap(context.safeBottomPadding()),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding(BuildContext context) {
    AppRouter.router.pushReplacement(AppRoute.home.name);
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingPageData page;
  const _OnboardingPageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.sym(h: 24),
      child: Column(
        children: [
          Gap(context.sc(16)),
          Image.asset(
            page.imagePath,
            height: context.sc(280),
            fit: BoxFit.contain,
          ),
          Gap(context.sc(24)),
          GradientText(
            page.title,

            style: Theme.of(context).textTheme.titleLarge,
          ),
          Gap(context.sc(8)),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: AppColors.lightGrey),
          ),
        ],
      ),
    );
  }
}
