// lib/features/restaurant/presentation/widgets/logo_upload_picker.dart
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Full-width drop zone for the restaurant logo. Empty it invites a tap;
/// once a file is picked it becomes a live preview with Change / Remove, and
/// while the form is being submitted the preview shows the upload progress.
class LogoUploadPicker extends StatelessWidget {
  final File? image;
  final ValueChanged<File> onImagePicked;
  final VoidCallback? onRemove;

  /// 0..1 while uploading, null otherwise.
  final double? uploadProgress;
  final bool hasError;

  const LogoUploadPicker({
    required this.image,
    required this.onImagePicked,
    this.onRemove,
    this.uploadProgress,
    this.hasError = false,
    super.key,
  });

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) onImagePicked(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final uploading = uploadProgress != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: image == null
          ? _DropZone(
              key: const ValueKey('empty'),
              hasError: hasError,
              onTap: _pickImage,
            )
          : _Preview(
              key: const ValueKey('preview'),
              image: image!,
              progress: uploadProgress,
              onChange: uploading ? null : _pickImage,
              onRemove: uploading ? null : onRemove,
            ),
    );
  }
}

class _DropZone extends StatelessWidget {
  final bool hasError;
  final VoidCallback onTap;
  const _DropZone({required this.hasError, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final color = hasError ? const Color(0xffE5484D) : ProfileTheme.purple;
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(24),
          strokeWidth: 1.6,
          dashPattern: const [7, 5],
          color: color.withValues(alpha: 0.7),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: ProfileTheme.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ProfileTheme.purple.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const Gap(14),
              const Text(
                'Tap to upload your logo',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
              const Gap(4),
              Text(
                hasError
                    ? 'A logo is required'
                    : 'PNG or JPG · a square image works best',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: hasError ? FontWeight.w700 : FontWeight.w500,
                  color: hasError ? color : ProfileTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final File image;
  final double? progress;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;
  const _Preview({
    required this.image,
    required this.progress,
    required this.onChange,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileTheme.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ProfileTheme.purple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
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
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image, fit: BoxFit.cover),
                      if (p != null)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: p > 0 ? p : null,
                                    strokeWidth: 3,
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                  Text(
                                    '${(p * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      p != null
                          ? Icons.cloud_upload_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: p != null
                          ? ProfileTheme.purple
                          : const Color(0xff22A45D),
                    ),
                    const Gap(6),
                    Text(
                      p != null ? 'Uploading…' : 'Logo added',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallButton(
                      icon: Icons.swap_horiz_rounded,
                      text: 'Change',
                      onTap: onChange,
                    ),
                    _SmallButton(
                      icon: Icons.delete_outline_rounded,
                      text: 'Remove',
                      onTap: onRemove,
                      danger: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool danger;
  const _SmallButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xffE5484D) : ProfileTheme.deepPurple;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const Gap(5),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
