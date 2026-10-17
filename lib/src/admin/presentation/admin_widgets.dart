import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Pastel pink → blue wash for the selected tab and primary actions.
const adminWash = ProfileTheme.brandGradient;
const adminDanger = Color(0xffD6336C);

/// Row of pill tabs (Pending / Approved / Rejected …).
class AdminTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const AdminTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const Gap(8),
        itemBuilder: (context, i) {
          final on = i == selected;
          return GestureDetector(
            onTap: () {
              if (on) return;
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: on ? adminWash : null,
                color: on ? null : primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? ProfileTheme.ink : primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small action button for list rows: the wash when [primary], a soft
/// grey otherwise, or red text when [danger].
class AdminActionButton extends StatelessWidget {
  final String label;
  final bool primary;
  final bool danger;
  final bool busy;
  final VoidCallback onTap;
  const AdminActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.busy = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final text = ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: primary ? adminWash : null,
          color: primary
              ? null
              : (danger ? adminDanger : text).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ProfileTheme.purple,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: primary
                      ? ProfileTheme.ink
                      : (danger ? adminDanger : text),
                ),
              ),
      ),
    );
  }
}

/// Centered icon + message (empty / error states).
class AdminMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const AdminMessage({
    required this.icon,
    required this.text,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return ListView(
      // Scrollable so pull-to-refresh works on an empty list.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: muted),
                const Gap(10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: muted),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: adminDanger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
