import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';
import 'package:khmer_cat_app/src/profile/providers/profile_providers.dart';

enum ProfileImageKind { avatar, cover }

/// Uploads [file] somewhere other than the signed-in user's own profile
/// (e.g. a restaurant's logo/cover) and refreshes whatever shows it.
typedef ProfileImageUploader =
    Future<void> Function(
      File file,
      void Function(int sent, int total) onProgress,
    );

const _red = Color(0xffE5484D);

/// Camera-icon flow for the profile's avatar / cover:
/// choose Camera or Gallery → pick → preview with Cancel / Upload → upload
/// (with progress, error message and Retry) → the profile updates and a
/// success message shows.
///
/// By default it updates the signed-in user's photo; pass [uploader] to send
/// the picked image elsewhere (a restaurant) with the same UI.
Future<void> changeProfileImage(
  BuildContext context,
  WidgetRef ref,
  ProfileImageKind kind, {
  ProfileImageUploader? uploader,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SourceSheet(kind: kind),
  );
  if (source == null || !context.mounted) return;

  XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: kind == ProfileImageKind.avatar ? 1024 : 1800,
    );
  } on PlatformException {
    // Camera / photo access denied (or no camera on this device).
    AppService.showToast(
      source == ImageSource.camera
          ? 'Camera access is off. Enable it in Settings to take a photo.'
          : 'Photo access is off. Enable it in Settings to choose a photo.',
      isError: true,
    );
    return;
  } catch (_) {
    AppService.showToast('Couldn\'t open the image picker.', isError: true);
    return;
  }
  if (picked == null || !context.mounted) return; // user backed out

  final uploaded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PreviewDialog(
      kind: kind,
      file: File(picked!.path),
      uploader: uploader,
    ),
  );
  if (uploaded == true) {
    AppService.showToast(
      kind == ProfileImageKind.avatar
          ? 'Profile photo updated'
          : 'Cover photo updated',
    );
  }
}

// =============================================================================
// Step 1 — Camera or Gallery
// =============================================================================

class _SourceSheet extends StatelessWidget {
  final ProfileImageKind kind;
  const _SourceSheet({required this.kind});

  @override
  Widget build(BuildContext context) {
    final title = kind == ProfileImageKind.avatar
        ? 'Change profile photo'
        : 'Change cover photo';
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: ProfileTheme.purple.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(14),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const Gap(14),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              gradient: ProfileTheme.pinkPurple,
              label: 'Take a photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Gap(8),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              gradient: ProfileTheme.purpleBlue,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Gap(8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: ProfileTheme.muted,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTheme.purple.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ProfileTheme.purple.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ProfileTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Steps 3–5 — preview, confirm, upload, error / retry
// =============================================================================

class _PreviewDialog extends HookConsumerWidget {
  final ProfileImageKind kind;
  final File file;
  final ProfileImageUploader? uploader;
  const _PreviewDialog({required this.kind, required this.file, this.uploader});

  bool get _isAvatar => kind == ProfileImageKind.avatar;

  /// The new image URL from the upload response, if it includes one — used
  /// only as a fallback when re-fetching the account fails.
  String? _urlFrom(Map<String, dynamic> data) {
    final source = data['user'] is Map
        ? (data['user'] as Map).cast<String, dynamic>()
        : data;
    final keys = _isAvatar
        ? ['profile_picture', 'avatar', 'url', 'image']
        : ['cover_picture', 'cover', 'url', 'image'];
    for (final k in keys) {
      final v = source[k];
      if (v is String && v.isNotEmpty) return AppConfig.fixMediaUrl(v);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploading = useState(false);
    final progress = useState(0.0);
    final error = useState<String?>(null);

    Future<void> upload() async {
      uploading.value = true;
      progress.value = 0;
      error.value = null;
      final repo = ref.read(profileRepositoryProvider);
      final before = ref.read(currentUserProvider);
      try {
        void onProgress(int sent, int total) {
          if (total > 0 && context.mounted) progress.value = sent / total;
        }

        final custom = uploader;
        if (custom != null) {
          await custom(file, onProgress);
          if (context.mounted) Navigator.of(context).pop(true);
          return;
        }

        final data = _isAvatar
            ? await repo.uploadAvatar(file, onProgress: onProgress)
            : await repo.uploadCover(file, onProgress: onProgress);

        // The upload itself succeeded: pull the fresh account so the new
        // image (and its final URL) shows everywhere.
        User? fresh;
        try {
          fresh = await ref.read(authRepositoryProvider).getCurrentUser();
        } catch (_) {
          final url = _urlFrom(data);
          if (before != null && url != null) {
            fresh = User(
              id: before.id,
              name: before.name,
              username: before.username,
              email: before.email,
              bio: before.bio,
              profilePicture: _isAvatar ? url : before.profilePicture,
              coverPicture: _isAvatar ? before.coverPicture : url,
            );
          }
        }
        // A server that reuses the same URL would otherwise keep showing the
        // cached old picture.
        for (final url in [
          _isAvatar ? before?.profilePicture : before?.coverPicture,
          _isAvatar ? fresh?.profilePicture : fresh?.coverPicture,
        ]) {
          if (url != null) await CachedNetworkImage.evictFromCache(url);
        }
        if (fresh != null) {
          ref.read(authControllerProvider.notifier).setAuthenticated(fresh);
        }
        if (context.mounted) Navigator.of(context).pop(true);
      } on ApiException catch (e) {
        error.value = e.isValidationError ? e.allErrorsMessage : e.message;
        uploading.value = false;
      } catch (_) {
        error.value = 'Something went wrong. Please try again.';
        uploading.value = false;
      }
    }

    final hasError = error.value != null;

    return PopScope(
      canPop: !uploading.value,
      child: Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isAvatar ? 'Preview profile photo' : 'Preview cover photo',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(4),
              const Text(
                'This is how it will look on your profile.',
                style: TextStyle(fontSize: 12.5, color: ProfileTheme.muted),
              ),
              const Gap(18),
              _Preview(
                file: file,
                isAvatar: _isAvatar,
                uploading: uploading.value,
                progress: progress.value,
              ),
              if (hasError) ...[
                const Gap(14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: _red,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          error.value!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: _red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: uploading.value
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: ProfileTheme.muted,
                        side: BorderSide(
                          color: ProfileTheme.purple.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: _UploadButton(
                      uploading: uploading.value,
                      retry: hasError,
                      onTap: uploading.value ? null : upload,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final File file;
  final bool isAvatar;
  final bool uploading;
  final double progress;
  const _Preview({
    required this.file,
    required this.isAvatar,
    required this.uploading,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final overlay = uploading
        ? ColoredBox(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress > 0 ? progress : null,
                          strokeWidth: 3.4,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  const Text(
                    'Uploading…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    if (isAvatar) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          gradient: ProfileTheme.gradient,
          shape: BoxShape.circle,
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file, fit: BoxFit.cover),
                  ?overlay,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final bool uploading;
  final bool retry;
  final VoidCallback? onTap;
  const _UploadButton({
    required this.uploading,
    required this.retry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: ProfileTheme.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ProfileTheme.purple.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (uploading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                retry ? Icons.refresh_rounded : Icons.cloud_upload_rounded,
                size: 19,
                color: Colors.white,
              ),
            const Gap(8),
            Text(
              uploading ? 'Uploading…' : (retry ? 'Retry' : 'Upload'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
