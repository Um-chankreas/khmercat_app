import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    );

    useEffect(() {
      controller.repeat(reverse: true);
      Future.microtask(
        () => ref.read(authControllerProvider.notifier).checkAuthStatus(),
      );
      return null;
    }, [controller]);
    ref.listen(authControllerProvider, (previous, next) {
      final settled =
          next.status == AuthStatus.authenticated ||
          next.status == AuthStatus.unauthenticated;
      if (settled) {
        AppRouter.router.pushReplacement(AppRoute.index.name);
      }
    });
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
        systemNavigationBarColor: AppColors.appPrimaryBlue,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: Center(
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      AssetsName.appLogoTr,
                      width: context.sc(200),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: context.sc(28),
              left: context.sc(14),
              right: context.sc(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Khmer Cat Co., Ltd.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Version 1.0.0.1',
                    style: Theme.of(context).textTheme.bodyMedium,
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
