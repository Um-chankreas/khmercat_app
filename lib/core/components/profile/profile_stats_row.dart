import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

class ProfileStat {
  final int value;
  final String label;
  final IconData icon;
  const ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Card of icon + count + label columns. Counts animate up on first show and
/// whenever they change (e.g. after following).
class ProfileStatsRow extends StatelessWidget {
  final List<ProfileStat> stats;
  const ProfileStatsRow({required this.stats, super.key});

  static const _tints = [
    ProfileTheme.pink,
    ProfileTheme.purple,
    ProfileTheme.blue,
    ProfileTheme.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 6,
                  endIndent: 6,
                  color: ProfileTheme.hairlineColor(context),
                ),
              Expanded(
                child: _Stat(stat: stats[i], tint: _tints[i % _tints.length]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final ProfileStat stat;
  final Color tint;
  const _Stat({required this.stat, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(stat.icon, size: 15, color: tint),
        ),
        const Gap(6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: stat.value),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _compact(v),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
          ),
        ),
        const Gap(2),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
