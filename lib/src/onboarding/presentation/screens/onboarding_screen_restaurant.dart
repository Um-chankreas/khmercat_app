import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';

import '../../domain/onboarding_page_data.dart';
import '../widgets/onboarding_view.dart';

class OnboardingScreenRestaurant extends StatelessWidget {
  const OnboardingScreenRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingView(
      pages: onboardingPagesRestaurant,
      onFinish: () => AppRouter.router.pushReplacement(AppRoute.home.name),
    );
  }
}
