// lib/features/home/presentation/screens/index_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/navigationbar/app_bottom_nav_bar.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/presentation/screens/home_feed.dart';
import 'package:khmer_cat_app/src/profile/presentation/screens/profile_tab.dart';
import 'package:khmer_cat_app/src/search/presentation/search_screen.dart';
import 'package:khmer_cat_app/src/video_upload/domain/video_upload_state.dart';
import 'package:khmer_cat_app/src/video_upload/presentation/video_upload_viewmodel.dart';

class IndexScreen extends HookConsumerWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);
    final currentUser = ref.watch(currentUserProvider);

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
              'Video uploaded — it\'ll appear in the feed once it\'s ready.',
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
      const _NotificationTab(),
      const ProfileTab(),
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
          avatarUrl: currentUser?.profilePicture,
        ),
      ),
    );
  }
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab();
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Notifications are coming soon.',
      style: TextStyle(color: AppColors.lightGrey),
    ),
  );
}
