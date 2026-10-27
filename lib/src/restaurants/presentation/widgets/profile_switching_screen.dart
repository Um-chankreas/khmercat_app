import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/presentation/viewmodel/comments_controller.dart';
import 'package:khmer_cat_app/src/feed/presentation/viewmodel/feed_controller.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_restaurant_provider.dart';
import 'package:khmer_cat_app/src/notifications/presentation/viewmodel/notifications_controller.dart';
import 'package:khmer_cat_app/src/profile/presentation/viewmodel/my_profile_summary_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_menu_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:khmer_cat_app/src/users/presentation/user_profile_controller.dart';

// Shortest time the switching screen stays up, so it reads as a deliberate
// step instead of a flash when the API answers instantly.
const _minShown = Duration(milliseconds: 1600);

/// Covers the app with the profile being switched to — its avatar inside a
/// spinning brand-gradient ring — while [run] performs the switch, then
/// reloads everything and lands on the Home tab (or closes with an error
/// toast if [run] returns false).
///
/// For a switch that already happened (back to personal, which the
/// password sheet does itself), pass `run: () async => true`.
///
/// [status], [doneToast] and [failToast] replace the "Switching profile…"
/// wording, e.g. for logging out.
Future<void> showProfileSwitching(
  BuildContext context, {
  required String name,
  required String? imageUrl,
  required bool isRestaurant,
  required Future<bool> Function() run,
  String? status,
  String? doneToast,
  String? failToast,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _ProfileSwitchingScreen(
        name: name,
        imageUrl: imageUrl,
        isRestaurant: isRestaurant,
        run: run,
        status: status,
        doneToast: doneToast,
        failToast: failToast,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Logs out behind the same screen as a profile switch — the account's
/// avatar in the spinning ring, "Logging out…" — then reloads everything
/// and lands on Home, signed out. Used by both the app's and the admin
/// area's Settings.
Future<void> showLoggingOut(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final user = ref.read(currentUserProvider);
  final auth = ref.read(authControllerProvider.notifier);
  return showProfileSwitching(
    context,
    name: user?.name ?? '',
    imageUrl: user?.profilePicture,
    isRestaurant: false,
    status: l.loggingOut,
    doneToast: l.loggedOut,
    failToast: l.logOutFailed,
    run: () async {
      try {
        await auth.logout();
        return true;
      } catch (_) {
        return false;
      }
    },
  );
}

/// Drops everything cached for the previous profile — the API answers
/// (likes, follows, notifications, "my" profile…) depend on who the user is
/// acting as — so each screen loads fresh the next time it's shown.
void refreshAfterProfileSwitch(WidgetRef ref) {
  ref
    ..invalidate(feedControllerProvider)
    ..invalidate(feedRestaurantProvider)
    ..invalidate(commentsControllerProvider)
    ..invalidate(notificationsControllerProvider)
    ..invalidate(myProfileSummaryControllerProvider)
    ..invalidate(restaurantProfileControllerProvider)
    ..invalidate(restaurantMenuControllerProvider)
    ..invalidate(userProfileControllerProvider)
    ..invalidate(searchViewModelProvider)
    ..invalidate(discoverProvider);
  ref.read(myRestaurantsControllerProvider.notifier).reloadQuietly();
}

class _ProfileSwitchingScreen extends HookConsumerWidget {
  final String name;
  final String? imageUrl;
  final bool isRestaurant;
  final Future<bool> Function() run;
  final String? status;
  final String? doneToast;
  final String? failToast;
  const _ProfileSwitchingScreen({
    required this.name,
    required this.imageUrl,
    required this.isRestaurant,
    required this.run,
    this.status,
    this.doneToast,
    this.failToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final spin = useAnimationController(duration: const Duration(seconds: 1));
    useEffect(() {
      spin.repeat();
      return null;
    }, [spin]);

    useEffect(() {
      Future<void> go() async {
        final results = await Future.wait([
          run(),
          Future.delayed(_minShown, () => true),
        ]);
        if (!context.mounted) return;
        final ok = results.first;
        // Close this screen first; the router change below then swaps the
        // stack underneath it as it fades out.
        Navigator.of(context).pop();
        if (ok) {
          refreshAfterProfileSwitch(ref);
          AppRouter.router.goNamed(AppRoute.index.name);
          HapticFeedback.lightImpact();
          AppService.showToast(doneToast ?? l.switchedTo(name));
        } else {
          AppService.showToast(failToast ?? l.switchFailed, isError: true);
        }
      }

      go();
      return null;
    }, const []);

    const avatarSize = 96.0;
    const ring = 4.0;
    final page = Theme.of(context).scaffoldBackgroundColor;
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return PopScope(
      // Can't back out of a switch that's already in flight.
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: MenuBackdrop()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: avatarSize + ring * 2 + 8,
                    height: avatarSize + ring * 2 + 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // A gradient arc that fades out at its tail,
                        // turning around the avatar.
                        RotationTransition(
                          turns: spin,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Color(0x00F0A6CE),
                                  ProfileTheme.brandPink,
                                  ProfileTheme.brandBlue,
                                ],
                                stops: [0.15, 0.6, 1],
                              ),
                            ),
                            child: SizedBox.expand(),
                          ),
                        ),
                        // Page-colored gap between the ring and the photo.
                        Container(
                          width: avatarSize + 8,
                          height: avatarSize + 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page,
                          ),
                        ),
                        if (isRestaurant && !hasImage)
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: ProfileTheme.coverFallback,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: avatarSize * 0.45,
                            ),
                          )
                        else
                          ClipOval(
                            child: ImageUserCircleProfile(
                              imageUrl: url,
                              name: name,
                              size: avatarSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: ProfileTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    status ?? l.switchingProfile,
                    style: TextStyle(
                      fontSize: 14,
                      color: ProfileTheme.textSecondary(context),
                    ),
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
