import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

const _red = Color(0xffE5484D);

/// Owner-only: confirms with the account password, then deletes the
/// restaurant. Returns true once it's deleted (the caller navigates away);
/// false if cancelled. Wrong passwords are shown inline.
Future<bool> confirmDeleteRestaurant(
  BuildContext context,
  Restaurant restaurant,
) async {
  final deleted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _DeleteSheet(restaurant: restaurant),
    ),
  );
  return deleted ?? false;
}

class _DeleteSheet extends HookConsumerWidget {
  final Restaurant restaurant;
  const _DeleteSheet({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctr = useTextEditingController();
    final obscure = useState(true);
    final loading = useState(false);
    final error = useState<String?>(null);
    final canSubmit = useListenableSelector(ctr, () => ctr.text.isNotEmpty);
    final muted = ProfileTheme.textSecondary(context);

    Future<void> submit() async {
      if (ctr.text.isEmpty || loading.value) return;
      loading.value = true;
      error.value = null;
      try {
        await ref
            .read(restaurantRepositoryProvider)
            .delete(restaurant.id, ctr.text);
        // The server also switched anyone using it back to personal.
        await ref
            .read(myRestaurantsControllerProvider.notifier)
            .reloadQuietly();
        if (context.mounted) Navigator.of(context).pop(true);
      } on ApiException catch (e) {
        HapticFeedback.heavyImpact();
        error.value = e.fieldError('password') ?? e.message;
      } catch (_) {
        error.value = 'Could not delete. Please try again.';
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(18),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 32,
                  color: _red,
                ),
              ),
            ),
            const Gap(12),
            Text(
              'Delete ${restaurant.name}?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in const [
                    'Its page, menu and QR code stop working.',
                    'Its videos disappear from the feed and search.',
                    'Everyone on your team loses access.',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 14,
                              color: _red,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: ProfileTheme.textPrimary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Gap(8),
            Text(
              'Just want to hide it for a while? Unpublish it instead.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
            const Gap(14),
            TextField(
              controller: ctr,
              autofocus: true,
              obscureText: obscure.value,
              enabled: !loading.value,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              onChanged: (_) {
                if (error.value != null) error.value = null;
              },
              decoration: InputDecoration(
                hintText: 'Enter your password to confirm',
                errorText: error.value,
                filled: true,
                fillColor: _red.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: _red,
                ),
                suffixIcon: IconButton(
                  onPressed: () => obscure.value = !obscure.value,
                  icon: Icon(
                    obscure.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: muted,
                  ),
                ),
                border: border(ProfileTheme.hairlineColor(context)),
                enabledBorder: border(ProfileTheme.hairlineColor(context)),
                focusedBorder: border(_red, 1.4),
                errorBorder: border(_red),
                focusedErrorBorder: border(_red, 1.4),
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: loading.value
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: muted,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FilledButton(
                    onPressed: canSubmit && !loading.value ? submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      disabledBackgroundColor: _red.withValues(alpha: 0.35),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
