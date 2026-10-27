// lib/core/components/navigation/cat_create_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

import 'nav_item.dart';

/// The center "create" button: the round cat badge with a plus at the
/// bottom. While a background upload runs the plus is covered by a progress
/// ring (a green tick on success, a red retry arrow on failure).
class CatCreateButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool busy;

  /// Upload progress 0..1; null while compressing (indeterminate).
  final double? progress;
  final bool error;
  final bool success;

  const CatCreateButton({
    required this.onTap,
    required this.label,
    this.busy = false,
    this.progress,
    this.error = false,
    this.success = false,
    super.key,
  });

  static const double diameter = 52;

  // Where the plus sits in the artwork, as a fraction of its size.
  static const _plusCenter = Alignment(0, 0.53);
  static const _plusSize = diameter * 0.34;

  @override
  State<CatCreateButton> createState() => _CatCreateButtonState();
}

class _CatCreateButtonState extends State<CatCreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    // Sits on a white dot over the plus, so the colors are the deep ones.
    final Widget? status;
    if (w.error) {
      status = const Icon(
        Icons.refresh_rounded,
        size: 16,
        color: Color(0xffFF5A5F),
      );
    } else if (w.success) {
      status = const Icon(
        Icons.check_rounded,
        size: 16,
        color: Color(0xff3DDC84),
      );
    } else if (w.busy) {
      status = SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Determinate only while we have a real upload percentage.
          value: w.progress,
          valueColor: AlwaysStoppedAnimation(navInkColors.last),
          backgroundColor: Colors.black.withValues(alpha: 0.08),
        ),
      );
    } else {
      status = null;
    }

    return Semantics(
      button: true,
      label: w.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          w.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          // Quick squeeze in, springy release.
          duration: Duration(milliseconds: _pressed ? 90 : 280),
          curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
          child: SizedBox.square(
            dimension: CatCreateButton.diameter,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AssetsName.catCreate,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                // A status icon covers the plus while an upload runs.
                Align(
                  alignment: CatCreateButton._plusCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: status == null
                        ? const SizedBox.shrink(key: ValueKey('plus'))
                        : Container(
                            key: ValueKey(
                              w.error
                                  ? 'error'
                                  : w.success
                                  ? 'success'
                                  : 'busy',
                            ),
                            width: CatCreateButton._plusSize,
                            height: CatCreateButton._plusSize,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: status,
                          ),
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
