import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:video_player/video_player.dart';

import '../../domain/video_feed_item.dart';
import 'report_screens.dart';

const _speeds = [0.5, 1.0, 1.5, 2.0];

/// How many video options sheets are open. The feed counts itself as
/// covered whenever anything sits on top of it (and unloads its videos), but
/// this small sheet should leave the video playing underneath, as on TikTok.
final videoOptionsSheetsOpen = ValueNotifier<int>(0);

/// The long-press menu on a video, like TikTok's: Report (not on your own
/// videos) and playback speed.
Future<void> showVideoOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  VideoFeedItem video, {
  VideoPlayerController? controller,
}) {
  HapticFeedback.mediumImpact();
  final isMine = ref.read(currentUserProvider)?.id == video.user.id;
  videoOptionsSheetsOpen.value++;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _sheetColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine)
              _Group(
                children: [
                  _OptionRow(
                    icon: Icons.outlined_flag_rounded,
                    label: 'Report',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (!await requireLogin(
                        context,
                        ref,
                        message: 'Sign in to report videos',
                      )) {
                        return;
                      }
                      if (context.mounted) {
                        openReportFlow(
                          context,
                          ref.read(apiClientProvider),
                          video.id,
                        );
                      }
                    },
                  ),
                ],
              ),
            if (controller != null) ...[
              if (!isMine) const Gap(12),
              _Group(children: [_SpeedRow(controller: controller)]),
            ],
          ],
        ),
      ),
    ),
  ).whenComplete(() => videoOptionsSheetsOpen.value--);
}

Color _sheetColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xff1C1C1E)
    : const Color(0xffF2F2F4);

/// A white rounded card of rows.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: primary),
            const Gap(14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Speed" with 0.5× · 1.0× · 1.5× · 2.0×, applied right away.
class _SpeedRow extends StatefulWidget {
  final VideoPlayerController controller;
  const _SpeedRow({required this.controller});

  @override
  State<_SpeedRow> createState() => _SpeedRowState();
}

class _SpeedRowState extends State<_SpeedRow> {
  late double _speed = widget.controller.value.playbackSpeed;

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      child: Row(
        children: [
          Icon(Icons.speed_rounded, size: 24, color: primary),
          const Gap(14),
          Text(
            'Speed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const Gap(10),
          // Shrinks to fit narrow screens instead of overflowing.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (final s in _speeds)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.controller.setPlaybackSpeed(s);
                            setState(() => _speed = s);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _speed == s
                                  ? Theme.of(context).colorScheme.surface
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${s.toStringAsFixed(1)}×',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _speed == s
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _speed == s ? primary : muted,
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
        ],
      ),
    );
  }
}
