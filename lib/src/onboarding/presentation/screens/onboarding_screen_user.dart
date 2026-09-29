import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';

import '../../domain/onboarding_page_data.dart';
import '../widgets/onboarding_view.dart';

class OnboardingScreenUser extends StatelessWidget {
  const OnboardingScreenUser({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingView(
      pages: onboardingPagesUser,
      onFinish: () => AppRouter.router.pushReplacement(AppRoute.index.name),
    );
  }
}
