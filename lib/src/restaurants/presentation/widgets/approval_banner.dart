import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

/// Shown to the team while an admin hasn't approved the restaurant yet (it's
/// hidden from customers until then), or after they rejected it.
class ApprovalBanner extends StatelessWidget {
  final Restaurant restaurant;
  const ApprovalBanner({required this.restaurant, super.key});

  /// Whether there's anything to say: not approved yet, or rejected.
  static bool appliesTo(Restaurant r) => r.status != 'approved';

  @override
  Widget build(BuildContext context) {
    final rejected = restaurant.status == 'rejected';
    final color = rejected ? const Color(0xffD6336C) : const Color(0xffB7791F);
    final reason = restaurant.rejectionReason?.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rejected ? Icons.block_rounded : Icons.hourglass_top_rounded,
            size: 20,
            color: color,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rejected ? 'Not approved' : 'Waiting for approval',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Gap(2),
                Text(
                  rejected
                      ? (reason == null || reason.isEmpty
                            ? 'An admin didn\'t approve this restaurant, so customers can\'t see it.'
                            : 'Reason: $reason')
                      : 'Customers can\'t see it yet. It goes public once the Khmer Cat team approves it.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: ProfileTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
