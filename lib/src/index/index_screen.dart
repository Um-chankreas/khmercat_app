// lib/features/home/presentation/screens/index_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/navigationbar/app_bottom_nav_bar.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/presentation/screens/home_feed.dart';
import 'package:khmer_cat_app/src/notifications/presentation/screens/notifications_screen.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/profile_tab.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/restaurant_owner_profile_tab.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/search_screen.dart';
import 'package:khmer_cat_app/src/video_upload/domain/video_upload_state.dart';
import 'package:khmer_cat_app/src/video_upload/presentation/video_upload_viewmodel.dart';

class IndexScreen extends HookConsumerWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);
    final currentUser = ref.watch(currentUserProvider);
    // The profile the user is acting as: a restaurant, or null = personal.
    final activeRestaurant = ref.watch(activeRestaurantProvider);

    final upload = ref.watch(videoUploadViewModelProvider);
    final uploadBusy =
        upload.stage == UploadStage.compressing ||
        upload.stage == UploadStage.uploading;

    // Surface the outcome of a background upload once the user is back on the
    // feed, then clear it so the create button returns to normal.
    ref.listen<VideoUploadState>(videoUploadViewModelProvider, (prev, next) {
      if (prev?.stage == next.stage) return;
      final messenger = ScaffoldMessenger.of(context);
      if (next.stage == UploadStage.success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Video uploaded — it\'ll go live once processing finishes.',
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          // Don't clobber a fresh upload the user may have started in the
          // meantime — only clear if we're still showing this success.
          if (ref.read(videoUploadViewModelProvider).stage ==
              UploadStage.success) {
            ref.read(videoUploadViewModelProvider.notifier).reset();
          }
        });
      } else if (next.stage == UploadStage.error) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(next.errorMessage ?? 'Upload failed'),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: ref.read(videoUploadViewModelProvider.notifier).retry,
            ),
          ),
        );
      }
    });

    final pages = [
      HomeFeed(isTabActive: selectedIndex.value == 0),
      const SearchScreen(),
      const NotificationsScreen(),
      _ActiveProfileTab(activeRestaurant: activeRestaurant),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      ),
      child: Scaffold(
        body: IndexedStack(index: selectedIndex.value, children: pages),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: selectedIndex.value,
          onTap: (i) => selectedIndex.value = i,
          uploadBusy: uploadBusy,
          uploadProgress: upload.stage == UploadStage.uploading
              ? upload.uploadProgress
              : null,
          uploadError: upload.stage == UploadStage.error,
          uploadSuccess: upload.stage == UploadStage.success,
          onCreateTap: () async {
            // A background upload is running — ignore taps until it settles.
            if (uploadBusy) return;
            // Last one failed: the button is a retry affordance now.
            if (upload.stage == UploadStage.error) {
              ref.read(videoUploadViewModelProvider.notifier).retry();
              return;
            }
            if (!await requireLogin(
              context,
              ref,
              message: 'Sign in to upload a video',
            )) {
              return;
            }
            AppRouter.router.pushNamed(AppRoute.cameraRecord.name);
          },
          avatarUrl: activeRestaurant != null
              ? activeRestaurant.profilePicture
              : currentUser?.profilePicture,
          avatarIsRestaurant: activeRestaurant != null,
        ),
      ),
    );
  }
}

/// The Profile tab shows whichever profile the user is acting as — their
/// own, or the active restaurant's (same layout, editable, with category).
/// Switching fades and slides between them.
class _ActiveProfileTab extends StatelessWidget {
  final Restaurant? activeRestaurant;
  const _ActiveProfileTab({required this.activeRestaurant});

  @override
  Widget build(BuildContext context) {
    final restaurant = activeRestaurant;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: restaurant == null
          ? const ProfileTab(key: ValueKey('personal'))
          : RestaurantOwnerProfileTab(
              key: ValueKey('restaurant-${restaurant.id}'),
              restaurantId: restaurant.id,
            ),
    );
  }
}
