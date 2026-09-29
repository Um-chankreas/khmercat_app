import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/switch_password_sheet.dart';

Future<void> showRestaurantSwitcherSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const RestaurantSwitcherSheet(),
  );
}

class RestaurantSwitcherSheet extends ConsumerWidget {
  const RestaurantSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRestaurantsControllerProvider);
    final user = ref.watch(currentUserProvider);
    final l = AppLocalizations.of(context);

    Future<void> switchTo(String? restaurantId, String name) async {
      final bool ok;
      if (restaurantId == null) {
        // Back to personal needs the password (cancelled = stay put).
        if (!await confirmSwitchToPersonal(context)) return;
        ok = true;
      } else {
        ok = await ref
            .read(myRestaurantsControllerProvider.notifier)
            .switchTo(restaurantId);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      AppService.showToast(
        ok ? l.switchedTo(name) : l.switchFailed,
        isError: !ok,
      );
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Text(l.switchTo, style: Theme.of(context).textTheme.titleMedium),
            const Gap(8),
            Flexible(
              child: state.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Could not load your restaurants.'),
                ),
                data: (data) {
                  final personalActive = data.activeRestaurantId == null;
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      // Back to the user's own profile.
                      if (user != null)
                        ListTile(
                          leading: ImageUserCircleProfile(
                            imageUrl: user.profilePicture,
                            name: user.name,
                            size: 40,
                          ),
                          title: Text(user.name),
                          subtitle: Text(l.profileTypePersonal),
                          trailing: personalActive
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.appPrimaryPink,
                                )
                              : null,
                          onTap: personalActive
                              ? null
                              : () => switchTo(null, user.name),
                        ),
                      ...data.restaurants.map((r) {
                        final isActive = r.id == data.activeRestaurantId;
                        return ListTile(
                          leading: ImageUserCircleProfile(
                            imageUrl: r.profilePicture,
                            name: r.name,
                            size: 40,
                          ),
                          title: Text(r.name),
                          subtitle: Text(l.profileTypeRestaurant),
                          trailing: isActive
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.appPrimaryPink,
                                )
                              : null,
                          onTap: isActive ? null : () => switchTo(r.id, r.name),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create a new restaurant'),
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.router.pushNamed(AppRoute.createRestaurant.name);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
