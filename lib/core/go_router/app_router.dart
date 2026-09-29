import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/src/auth/presentation/screens/login_screen.dart';
import 'package:khmer_cat_app/src/auth/presentation/screens/otp_verify.dart';
import 'package:khmer_cat_app/src/auth/presentation/screens/register_screen.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/presentation/screens/video_viewer_screen.dart';
import 'package:khmer_cat_app/src/index/index_screen.dart';
import 'package:khmer_cat_app/src/onboarding/presentation/screens/onboarding_screen_restaurant.dart';
import 'package:khmer_cat_app/src/onboarding/presentation/screens/onboarding_screen_user.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/create_restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/restaurant_profile_screen.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/edit_restaurant_screen.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/restaurant_menu_screen.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/edit_profile_screen.dart';
import 'package:khmer_cat_app/src/settings/presentation/settings_screen.dart';
import 'package:khmer_cat_app/src/splash/splash_screen.dart';
import 'package:khmer_cat_app/src/splash/welcome_screen.dart';
import 'package:khmer_cat_app/src/users/presentation/user_profile_screen.dart';
import 'package:khmer_cat_app/src/video_upload/presentation/camera_record_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class AppRouter {
  static GoRouter get router => _goRouter;

  static String? routeNavigate;

  static void setRouteNavigate(String route) {
    routeNavigate = route;
  }

  static final _navigatorKey = GlobalKey<NavigatorState>();
  static final _goRouter = GoRouter(
    initialLocation: AppRoute.splash.path,
    observers: [routeObserver],
    navigatorKey: _navigatorKey,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        pageBuilder: (context, state) => CupertinoPage(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoute.welcome.path,
        name: AppRoute.welcome.name,
        pageBuilder: (context, state) => CupertinoPage(child: WelcomeScreen()),
        routes: [
          GoRoute(
            path: AppRoute.login.path,
            name: AppRoute.login.name,
            pageBuilder: (context, state) =>
                CupertinoPage(child: LoginScreen()),
          ),
          GoRoute(
            path: AppRoute.createAccount.path,
            name: AppRoute.createAccount.name,
            pageBuilder: (context, state) => CupertinoPage(
              child: RegisterScreen(
                userType: state.uri.queryParameters['user_type'].toString(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoute.verifyCode.path,
            name: AppRoute.verifyCode.name,
            pageBuilder: (context, state) => CupertinoPage(
              child: OtpVerify(
                userId: state.uri.queryParameters['user_id'].toString(),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.onboadingRestaurant.path,
        name: AppRoute.onboadingRestaurant.name,
        pageBuilder: (context, state) =>
            CupertinoPage(child: OnboardingScreenRestaurant()),
      ),

      GoRoute(
        path: AppRoute.createRestaurant.path,
        name: AppRoute.createRestaurant.name,
        pageBuilder: (context, state) =>
            CupertinoPage(child: CreateRestaurant()),
      ),

      GoRoute(
        path: AppRoute.onboadingNormalUser.path,
        name: AppRoute.onboadingNormalUser.name,
        pageBuilder: (context, state) =>
            CupertinoPage(child: OnboardingScreenUser()),
      ),
      GoRoute(
        path: AppRoute.index.path,
        name: AppRoute.index.name,
        pageBuilder: (context, state) => CupertinoPage(child: IndexScreen()),
        routes: [
          GoRoute(
            path: AppRoute.cameraRecord.path,
            name: AppRoute.cameraRecord.name,
            pageBuilder: (context, state) =>
                CupertinoPage(child: CameraRecordScreen()),
          ),
        ],
      ),

      GoRoute(
        path: AppRoute.memberinfo.path,
        name: AppRoute.memberinfo.name,
        pageBuilder: (context, state) => CupertinoPage(child: Container()),
      ),

      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        pageBuilder: (context, state) =>
            const CupertinoPage(child: SettingsScreen()),
      ),

      GoRoute(
        path: AppRoute.editProfile.path,
        name: AppRoute.editProfile.name,
        pageBuilder: (context, state) =>
            const CupertinoPage(child: EditProfileScreen()),
      ),

      GoRoute(
        path: AppRoute.restaurantProfile.path,
        name: AppRoute.restaurantProfile.name,
        pageBuilder: (context, state) => CupertinoPage(
          child: RestaurantProfileScreen(
            restaurantId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.restaurantMenu.path,
        name: AppRoute.restaurantMenu.name,
        pageBuilder: (context, state) => CupertinoPage(
          child: RestaurantMenuScreen(
            restaurantId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.editRestaurant.path,
        name: AppRoute.editRestaurant.name,
        pageBuilder: (context, state) => CupertinoPage(
          child: EditRestaurantScreen(
            restaurantId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.userProfile.path,
        name: AppRoute.userProfile.name,
        pageBuilder: (context, state) => CupertinoPage(
          child: UserProfileScreen(username: state.pathParameters['username']!),
        ),
      ),
      GoRoute(
        path: AppRoute.videoViewer.path,
        name: AppRoute.videoViewer.name,
        pageBuilder: (context, state) => CupertinoPage(
          child: VideoViewerScreen(video: state.extra as VideoFeedItem),
        ),
      ),
    ],
  );
}
