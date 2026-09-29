import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/delete_restaurant_sheet.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

const _red = Color(0xffE5484D);

const _serviceTypes = <(String, String, IconData)>[
  ('dine_in', 'Dine-in', Icons.restaurant_rounded),
  ('delivery', 'Delivery', Icons.delivery_dining_rounded),
  ('dine_in_delivery', 'Dine-in & Delivery', Icons.storefront_rounded),
  ('takeaway', 'Takeaway', Icons.takeout_dining_rounded),
];

/// Owner/manager form for a restaurant's details: name, category, about,
/// contact, opening hours, service type and social links.
/// Saves only what changed, then updates the profile and the switcher.
class EditRestaurantScreen extends HookConsumerWidget {
  final String restaurantId;
  const EditRestaurantScreen({required this.restaurantId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = restaurantProfileControllerProvider(restaurantId);
    final restaurant = ref.watch(provider.select((s) => s.restaurant));
    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(surfaceTintColor: Colors.transparent),
        body: const Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
        ),
      );
    }
    return _EditForm(restaurant: restaurant);
  }
}

class _EditForm extends HookConsumerWidget {
  final Restaurant restaurant;
  const _EditForm({required this.restaurant});

  static String? _hm(String? t) =>
      t == null || t.length < 5 ? null : t.substring(0, 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = restaurant;
    final name = useTextEditingController(text: r.name);
    final about = useTextEditingController(text: r.description ?? '');
    final phone = useTextEditingController(text: r.phone ?? '');
    final address = useTextEditingController(text: r.address ?? '');
    final facebook = useTextEditingController(text: r.facebookUrl ?? '');
    final tiktok = useTextEditingController(text: r.tiktokUrl ?? '');
    final telegram = useTextEditingController(text: r.telegramUsername ?? '');
    final category = useState<String?>(r.category?.name);
    final service = useState<String?>(r.serviceType);
    final opens = useState<String?>(_hm(r.openingTime));
    final closes = useState<String?>(_hm(r.closingTime));
    final saving = useState(false);
    // Only the owner (not managers) can delete; the role comes from your
    // restaurants list.
    final isOwner =
        ref
            .watch(myRestaurantsControllerProvider)
            .valueOrNull
            ?.restaurants
            .any((x) => x.id == r.id && x.myRole == 'owner') ??
        false;
    final errors = useState<ApiException?>(null);

    Future<void> pickTime(ValueNotifier<String?> target) async {
      final parts = target.value?.split(':');
      final picked = await showTimePicker(
        context: context,
        initialTime: parts == null
            ? const TimeOfDay(hour: 9, minute: 0)
            : TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      );
      if (picked == null) return;
      target.value =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    }

    Future<void> save() async {
      if (saving.value) return;
      if (name.text.trim().isEmpty) {
        errors.value = ApiException(
          message: 'Please enter a name.',
          errors: const {
            'name': ['Please enter a name.'],
          },
        );
        return;
      }
      if ((opens.value == null) != (closes.value == null)) {
        AppService.showToast(
          'Set both opening and closing time, or neither.',
          isError: true,
        );
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();

      String? text(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();

      // The fields this form edits; price level and delivery time aren't
      // sent, so any values already stored are left untouched.
      final fields = <String, dynamic>{
        'name': name.text.trim(),
        if (category.value != null)
          'category_id': int.parse(cuisineCategoryIds[category.value]!),
        'description': text(about),
        'phone': text(phone),
        'address': text(address),
        'facebook_url': text(facebook),
        'tiktok_url': text(tiktok),
        'telegram_username': text(telegram),
        'service_type': service.value,
        'opening_time': opens.value,
        'closing_time': closes.value,
      };

      saving.value = true;
      errors.value = null;
      try {
        final updated = await ref
            .read(restaurantRepositoryProvider)
            .update(r.id, fields);
        ref
            .read(restaurantProfileControllerProvider(r.id).notifier)
            .replace(updated);
        await ref
            .read(myRestaurantsControllerProvider.notifier)
            .reloadQuietly();
        if (!context.mounted) return;
        HapticFeedback.lightImpact();
        AppService.showToast('Restaurant updated');
        Navigator.of(context).pop();
      } on ApiException catch (e) {
        errors.value = e;
        if (context.mounted) {
          AppService.showToast(e.message, isError: true);
        }
      } catch (_) {
        AppService.showToast(
          'Could not save. Please try again.',
          isError: true,
        );
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    String? err(String field) => errors.value?.fieldError(field);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit restaurant',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _Label('Name', icon: Icons.storefront_rounded),
            const Gap(8),
            _Input(
              controller: name,
              hint: 'Restaurant name',
              icon: Icons.storefront_rounded,
              maxLength: 255,
              errorText: err('name'),
            ),
            const Gap(18),
            const _Label('Category', icon: Icons.restaurant_menu_rounded),
            const Gap(8),
            CuisineCategorySelector(
              selected: category.value,
              onSelect: (c) => category.value = c,
              hasError: err('category_id') != null,
            ),
            const Gap(18),
            const _Label('About', icon: Icons.notes_rounded, optional: true),
            const Gap(8),
            _Input(
              controller: about,
              hint: 'What makes your restaurant special?',
              icon: Icons.notes_rounded,
              maxLines: 4,
              minLines: 3,
              maxLength: 1000,
              errorText: err('description'),
            ),
            const Gap(18),
            const _Label('Phone', icon: Icons.phone_rounded, optional: true),
            const Gap(8),
            _Input(
              controller: phone,
              hint: '012 345 678',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              maxLength: 30,
              errorText: err('phone'),
            ),
            const Gap(18),
            const _Label(
              'Address',
              icon: Icons.location_on_rounded,
              optional: true,
            ),
            const Gap(8),
            _Input(
              controller: address,
              hint: 'Street 271, Phnom Penh',
              icon: Icons.location_on_rounded,
              maxLength: 500,
              errorText: err('address'),
            ),
            const Gap(18),
            const _Label(
              'Opening hours',
              icon: Icons.schedule_rounded,
              optional: true,
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Opens',
                    value: opens.value,
                    onTap: () => pickTime(opens),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _TimeButton(
                    label: 'Closes',
                    value: closes.value,
                    onTap: () => pickTime(closes),
                  ),
                ),
                if (opens.value != null || closes.value != null)
                  IconButton(
                    tooltip: 'Clear hours',
                    onPressed: () {
                      opens.value = null;
                      closes.value = null;
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: ProfileTheme.muted,
                    ),
                  ),
              ],
            ),
            const Gap(18),
            const _Label(
              'Service',
              icon: Icons.delivery_dining_rounded,
              optional: true,
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label, icon) in _serviceTypes)
                  _Choice(
                    label: label,
                    icon: icon,
                    selected: service.value == value,
                    onTap: () =>
                        service.value = service.value == value ? null : value,
                  ),
              ],
            ),
            const Gap(18),
            const _Label(
              'Social links',
              icon: Icons.share_rounded,
              optional: true,
            ),
            const Gap(8),
            _Input(
              controller: facebook,
              hint: 'Facebook page URL',
              asset: AssetsName.facebook,
              keyboardType: TextInputType.url,
              maxLength: 255,
              errorText: err('facebook_url'),
            ),
            const Gap(10),
            _Input(
              controller: tiktok,
              hint: 'TikTok username or URL',
              asset: AssetsName.tiktok,
              keyboardType: TextInputType.url,
              maxLength: 255,
              errorText: err('tiktok_url'),
            ),
            const Gap(10),
            _Input(
              controller: telegram,
              hint: 'Telegram username, e.g. @angkorbites',
              asset: AssetsName.telegram,
              maxLength: 64,
              errorText: err('telegram_username'),
            ),
            const Gap(28),
            ProfileGradientButton(
              text: saving.value ? 'Saving…' : 'Save changes',
              icon: Icons.check_rounded,
              onTap: saving.value ? null : save,
            ),

            // ---- Manage: these apply right away (not via Save).
            const Gap(32),
            const _SectionLabel('Visibility'),
            const Gap(8),
            _VisibilityCard(restaurant: r),
            if (isOwner) ...[
              const Gap(24),
              const _SectionLabel('Danger zone'),
              const Gap(8),
              _DangerCard(
                onDelete: () async {
                  final deleted = await confirmDeleteRestaurant(context, r);
                  if (!deleted || !context.mounted) return;
                  HapticFeedback.mediumImpact();
                  AppService.showToast('${r.name} was deleted');
                  // Back to the home screen: this restaurant's pages are gone.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool optional;
  const _Label(this.text, {required this.icon, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: ProfileTheme.purple),
        const Gap(6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (optional)
          const Text(
            '  Optional',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ProfileTheme.muted,
            ),
          ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  /// Leading icon: a Material [icon], or a brand logo [asset].
  final IconData? icon;
  final String? asset;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? errorText;

  const _Input({
    required this.controller,
    required this.hint,
    this.icon,
    this.asset,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.keyboardType,
    this.errorText,
  });

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ProfileTheme.muted.withValues(alpha: 0.65),
        ),
        counterText: '',
        errorText: errorText,
        prefixIcon: asset != null
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(asset!, width: 20, height: 20),
              )
            : Icon(icon, size: 20, color: ProfileTheme.purple),
        filled: true,
        fillColor: ProfileTheme.purple.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(ProfileTheme.purple.withValues(alpha: 0.18)),
        enabledBorder: _border(ProfileTheme.purple.withValues(alpha: 0.18)),
        focusedBorder: _border(ProfileTheme.purple, 1.6),
        errorBorder: _border(_red.withValues(alpha: 0.7), 1.3),
        focusedErrorBorder: _border(_red, 1.6),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTheme.purple.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ProfileTheme.purple.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 20,
                color: ProfileTheme.purple,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: ProfileTheme.muted,
                      ),
                    ),
                    Text(
                      value ?? '--:--',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : ProfileTheme.deepPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? ProfileTheme.pinkPurple : null,
          color: selected ? null : ProfileTheme.purple.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : ProfileTheme.purple.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small grey uppercase heading for the Manage sections.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: ProfileTheme.textSecondary(context),
      ),
    );
  }
}

/// Published switch. Unpublishing hides the restaurant from everyone but
/// its team (search, feed, its page and menu); it asks first.
class _VisibilityCard extends HookConsumerWidget {
  final Restaurant restaurant;
  const _VisibilityCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = useState(restaurant.isPublished);
    final busy = useState(false);
    final muted = ProfileTheme.textSecondary(context);
    const green = Color(0xff22A45D);

    Future<void> apply(bool value) async {
      busy.value = true;
      published.value = value;
      try {
        final updated = await ref
            .read(restaurantRepositoryProvider)
            .setPublished(restaurant.id, value);
        ref
            .read(restaurantProfileControllerProvider(restaurant.id).notifier)
            .replace(updated);
        await ref
            .read(myRestaurantsControllerProvider.notifier)
            .reloadQuietly();
        AppService.showToast(
          value ? 'Restaurant is public again' : 'Restaurant is now hidden',
        );
      } catch (_) {
        published.value = !value;
        AppService.showToast('Could not change visibility.', isError: true);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    void toggle(bool value) {
      if (busy.value) return;
      if (value) {
        apply(true);
        return;
      }
      AppDialogs.showConfirm(
        context,
        title: 'Unpublish ${restaurant.name}?',
        message:
            'It will be hidden from search and the feed, and its page and '
            'menu QR stop opening for customers. Your team can still see '
            'it, and you can publish it again any time.',
        confirmText: 'Unpublish',
        onConfirm: () => apply(false),
      );
    }

    final on = published.value;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (on ? green : muted).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              on ? Icons.public_rounded : Icons.visibility_off_rounded,
              size: 20,
              color: on ? green : muted,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  on ? 'Published' : 'Unpublished',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
                const Gap(2),
                Text(
                  on
                      ? 'Customers can find and see your restaurant.'
                      : 'Hidden from customers. Only your team can see it.',
                  style: TextStyle(fontSize: 12.5, height: 1.3, color: muted),
                ),
              ],
            ),
          ),
          busy.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProfileTheme.purple,
                    ),
                  ),
                )
              : Switch(
                  value: on,
                  activeThumbColor: Colors.white,
                  activeTrackColor: green,
                  onChanged: toggle,
                ),
        ],
      ),
    );
  }
}

/// Owner-only: permanently delete the restaurant.
class _DangerCard extends StatelessWidget {
  final VoidCallback onDelete;
  const _DangerCard({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _red.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _red.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDelete,
        splashColor: _red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: _red,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delete restaurant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _red,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Removes its page, menu and videos for everyone.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _red),
            ],
          ),
        ),
      ),
    );
  }
}
