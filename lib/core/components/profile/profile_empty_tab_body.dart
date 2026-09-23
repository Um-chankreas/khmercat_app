import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Centered illustration + message for a profile tab with nothing to show
/// (or no backend support yet) — sized to its content so it can sit inside a
/// normal scrollable column.
class ProfileEmptyTabBody extends StatelessWidget {
  final String? asset;
  final IconData? icon;
  final String? title;
  final String message;
  const ProfileEmptyTabBody({
    this.asset,
    this.icon,
    this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ProfileTheme.pink.withValues(alpha: 0.14),
                      ProfileTheme.blue.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: asset != null
                      ? Image.asset(
                          asset!,
                          width: 38,
                          height: 38,
                          color: ProfileTheme.purple,
                        )
                      : Icon(
                          icon ?? Icons.inbox_outlined,
                          size: 40,
                          color: ProfileTheme.purple,
                        ),
                ),
              ),
            ),
            const Gap(16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(4),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
