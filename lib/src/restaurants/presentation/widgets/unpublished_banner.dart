import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// Shown to the team on an unpublished restaurant's pages: it's hidden from
/// customers, with a one-tap Publish.
class UnpublishedBanner extends HookConsumerWidget {
  final Restaurant restaurant;
  const UnpublishedBanner({required this.restaurant, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);
    final muted = ProfileTheme.textSecondary(context);

    Future<void> publish() async {
      busy.value = true;
      try {
        final updated = await ref
            .read(restaurantRepositoryProvider)
            .setPublished(restaurant.id, true);
        ref
            .read(restaurantProfileControllerProvider(restaurant.id).notifier)
            .replace(updated);
        await ref
            .read(myRestaurantsControllerProvider.notifier)
            .reloadQuietly();
        AppService.showToast('Restaurant is public again');
      } catch (_) {
        AppService.showToast('Could not publish.', isError: true);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_off_rounded, size: 20, color: muted),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hidden from customers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
                Text(
                  'Only your team can see this restaurant.',
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy.value ? null : publish,
            style: TextButton.styleFrom(
              foregroundColor: ProfileTheme.deepPurple,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: busy.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publish'),
          ),
        ],
      ),
    );
  }
}
