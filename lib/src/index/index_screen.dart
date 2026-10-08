// lib/features/home/presentation/screens/index_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/navigationbar/app_bottom_nav_bar.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/src/feed/presentation/screens/home_feed.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_chrome_provider.dart';
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

    // The glass bar floats over the body (extendBody). The feed and search
    // draw behind it themselves; the other tabs just stop above it.
    final pages = [
      HomeFeed(isTabActive: selectedIndex.value == 0),
      const SearchScreen(),
      const _AboveNavBar(child: NotificationsScreen()),
      _AboveNavBar(
        child: _ActiveProfileTab(activeRestaurant: activeRestaurant),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The bar floats, so the page shows under the system gesture area.
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: selectedIndex.value, children: pages),

        bottomNavigationBar: _AutoHide(
          // Only the feed hides it, and only while swiping.
          hidden:
              selectedIndex.value == 0 && ref.watch(feedChromeHiddenProvider),
          child: AppBottomNavBar(
            currentIndex: selectedIndex.value,
            overMedia: selectedIndex.value == 0,
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
            actingAsRestaurant: activeRestaurant != null,
          ),
        ),
      ),
    );
  }
}

/// Slides [child] down off the screen while [hidden]. The slot keeps its
/// height (so nothing above re-lays out) and, once fully off-screen, the
/// child is switched off so its backdrop blur stops rendering. It stays in
/// the tree, so its state (icon animations, upload ring) is kept.
class _AutoHide extends StatefulWidget {
  final bool hidden;
  final Widget child;
  const _AutoHide({required this.hidden, required this.child});

  @override
  State<_AutoHide> createState() => _AutoHideState();
}

class _AutoHideState extends State<_AutoHide> {
  bool _gone = false;

  @override
  void didUpdateWidget(_AutoHide old) {
    super.didUpdateWidget(old);
    // Back on screen: render again before it slides in.
    if (!widget.hidden && _gone) _gone = false;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.hidden,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: widget.hidden ? Curves.easeInCubic : Curves.easeOutCubic,
        offset: widget.hidden ? const Offset(0, 1.4) : Offset.zero,
        onEnd: () {
          if (widget.hidden && !_gone) setState(() => _gone = true);
        },
        child: Visibility(
          visible: !_gone,
          // Keep the slot's size: if it collapsed, the feed's bottom inset
          // would change and its overlays would jump.
          maintainSize: true,
          maintainState: true,
          maintainAnimation: true,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Ends [child] at the top of the bar's flat part instead of letting it run
/// underneath: pads by the body's bottom inset (the bar, under extendBody)
/// less the center dome, and clears that inset for the subtree so nothing
/// inside pads for it a second time.
class _AboveNavBar extends StatelessWidget {
  final Widget child;
  const _AboveNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: navBarInset(context)),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
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
