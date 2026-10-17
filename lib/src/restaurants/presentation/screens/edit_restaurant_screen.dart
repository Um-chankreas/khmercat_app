import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/delete_restaurant_sheet.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

const _danger = Color(0xffD6336C);
const _accent = Color(0xffB0125A);
const _green = Color(0xff1F7A4D);

/// Pastel pink → blue wash: Save, and picked chips.
const _wash = ProfileTheme.brandGradient;

const _aboutMax = 1000;

const _serviceTypes = <(String, String)>[
  ('dine_in', 'Dine-in'),
  ('delivery', 'Delivery'),
  ('dine_in_delivery', 'Dine-in & Delivery'),
  ('takeaway', 'Takeaway'),
];

/// Owner/manager form for a restaurant's details: name, category, about,
/// contact, opening hours, services, Halal and social links, saved with the
/// Save pill; then Published and (for the owner) Delete, which apply right
/// away.
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
    final halal = useState(r.isHalal);
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
        // Type the time in; no clock dial or switch to it.
        initialEntryMode: TimePickerEntryMode.inputOnly,
        // The app theme's primary is a very pale blue, which left Cancel /
        // OK (and the selected AM/PM) nearly invisible on the dialog.
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: _accent,
                onPrimary: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: theme.colorScheme.surface,
                dayPeriodColor: _wash.colors.first.withValues(alpha: 0.45),
                dayPeriodTextColor: ProfileTheme.textPrimary(context),
                hourMinuteColor: ProfileTheme.textPrimary(
                  context,
                ).withValues(alpha: 0.06),
                hourMinuteTextColor: ProfileTheme.textPrimary(context),
              ),
            ),
            child: child!,
          );
        },
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
        'is_halal': halal.value,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                saving: saving.value,
                onBack: () => Navigator.of(context).maybePop(),
                onSave: save,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    MediaQuery.paddingOf(context).bottom + 32,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // ---- Basics
                    const _SectionTitle('Basics'),
                    const _Label('Name'),
                    _Input(
                      controller: name,
                      hint: 'Restaurant name',
                      maxLength: 255,
                      errorText: err('name'),
                    ),
                    const Gap(18),
                    const _Label('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in cuisineOptions)
                          _Choice(
                            label: c,
                            selected: category.value == c,
                            hasError: err('category_id') != null,
                            onTap: () => category.value = c,
                          ),
                      ],
                    ),
                    const Gap(18),
                    _Label(
                      'About',
                      optional: true,
                      trailing: _Counter(controller: about, max: _aboutMax),
                    ),
                    _Input(
                      controller: about,
                      hint: 'What makes your restaurant special?',
                      maxLines: 4,
                      minLines: 3,
                      maxLength: _aboutMax,
                      errorText: err('description'),
                    ),
                    const _SectionDivider(),

                    // ---- Contact & location
                    const _SectionTitle('Contact & location'),
                    const _Label('Phone', optional: true),
                    _Input(
                      controller: phone,
                      hint: '012 345 678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 30,
                      errorText: err('phone'),
                    ),
                    const Gap(18),
                    const _Label('Address', optional: true),
                    _Input(
                      controller: address,
                      hint: 'Street 271, Phnom Penh',
                      icon: Icons.location_on_outlined,
                      maxLength: 500,
                      errorText: err('address'),
                    ),
                    const Gap(18),
                    const _Label('Opening hours', optional: true),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeButton(
                            label: 'Opens',
                            value: opens.value,
                            onTap: () => pickTime(opens),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _TimeButton(
                            label: 'Closes',
                            value: closes.value,
                            onTap: () => pickTime(closes),
                          ),
                        ),
                      ],
                    ),
                    if (opens.value != null || closes.value != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            opens.value = null;
                            closes.value = null;
                          },
                          child: Text(
                            'Clear hours',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ProfileTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    const _SectionDivider(),

                    // ---- Services
                    const _SectionTitle('Services'),
                    const _Label('What you offer', optional: true),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (value, label) in _serviceTypes)
                          _Choice(
                            label: label,
                            selected: service.value == value,
                            onTap: () => service.value = service.value == value
                                ? null
                                : value,
                          ),
                      ],
                    ),
                    const Gap(20),
                    // Shown as a badge on its cards, and matched by search's
                    // Halal filter.
                    _SwitchRow(
                      title: 'Halal',
                      subtitle:
                          'Show a Halal badge and appear in the Halal filter',
                      value: halal.value,
                      onChanged: (v) => halal.value = v,
                    ),
                    const _SectionDivider(),

                    // ---- Social links
                    const _SectionTitle('Social links'),
                    _Input(
                      controller: facebook,
                      hint: 'facebook.com/yourpage',
                      asset: AssetsName.facebook,
                      keyboardType: TextInputType.url,
                      maxLength: 255,
                      errorText: err('facebook_url'),
                    ),
                    const Gap(10),
                    _Input(
                      controller: tiktok,
                      hint: 'TikTok @username',
                      asset: AssetsName.tiktok,
                      keyboardType: TextInputType.url,
                      maxLength: 255,
                      errorText: err('tiktok_url'),
                    ),
                    const Gap(10),
                    _Input(
                      controller: telegram,
                      hint: 'Telegram username',
                      asset: AssetsName.telegram,
                      maxLength: 64,
                      errorText: err('telegram_username'),
                    ),
                    const _SectionDivider(),

                    // ---- Applies right away (not via Save).
                    _VisibilityCard(restaurant: r),
                    if (isOwner) ...[
                      const Gap(28),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final deleted = await confirmDeleteRestaurant(
                              context,
                              r,
                            );
                            if (!deleted || !context.mounted) return;
                            HapticFeedback.mediumImpact();
                            AppService.showToast('${r.name} was deleted');
                            // Back to the home screen: this restaurant's
                            // pages are gone.
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: _danger,
                          ),
                          label: const Text(
                            'Delete restaurant',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _danger,
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Back, the centered title, and the Save pill.
class _TopBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;
  const _TopBar({
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: primary,
              ),
              onPressed: onBack,
            ),
          ),
          Text(
            'Edit restaurant',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: primary,
            ),
          ),
          Positioned(
            right: 12,
            child: GestureDetector(
              onTap: saving ? null : onSave,
              child: Container(
                height: 38,
                constraints: const BoxConstraints(minWidth: 74),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _wash,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: ProfileTheme.ink,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ProfileTheme.ink,
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

/// Small grey heading over a group of fields ("Basics", "Services").
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ProfileTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Hairline between sections.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Divider(
      height: 1,
      thickness: 1,
      color: ProfileTheme.hairlineColor(context),
    ),
  );
}

/// A field's name (+ "Optional", + e.g. a counter on the right).
class _Label extends StatelessWidget {
  final String text;
  final bool optional;
  final Widget? trailing;
  const _Label(this.text, {this.optional = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          if (optional) ...[
            const Gap(6),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// "43 / 300" for a text field, updating as you type.
class _Counter extends StatelessWidget {
  final TextEditingController controller;
  final int max;
  const _Counter({required this.controller, required this.max});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Text(
        '${controller.text.length} / $max',
        style: TextStyle(
          fontSize: 12.5,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: controller.text.length >= max * 0.9
              ? _danger
              : ProfileTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Soft grey field with no outline until focused. Leads with a line
/// [icon], a brand logo [asset] in a small grey circle, or nothing.
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final hasLead = icon != null || asset != null;
    final multiline = maxLines > 1;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 15, color: primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: ProfileTheme.textSecondary(context).withValues(alpha: 0.75),
        ),
        counterText: '',
        errorText: errorText,
        prefixIcon: !hasLead
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                child: asset != null
                    ? Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.08),
                        ),
                        child: Image.asset(asset!, width: 15, height: 15),
                      )
                    : Icon(icon, size: 20, color: primary),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: primary.withValues(alpha: 0.045),
        contentPadding: EdgeInsets.fromLTRB(
          hasLead ? 0 : 16,
          multiline ? 14 : 15,
          14,
          15,
        ),
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(_accent.withValues(alpha: 0.6), 1.2),
        errorBorder: _border(_danger.withValues(alpha: 0.7), 1.2),
        focusedErrorBorder: _border(_danger, 1.5),
      ),
    );
  }
}

/// "Opens" / "Closes": a clock, the label, and the time (or "Set time").
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
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Material(
      color: primary.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 20, color: primary),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: muted)),
                    const Gap(1),
                    Text(
                      value ?? 'Set time',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: value == null ? muted : primary,
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

/// A choice chip: soft grey, or the pastel wash with a check when picked.
class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: selected ? _wash : null,
          color: selected ? null : primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(19),
          border: hasError && !selected
              ? Border.all(color: _danger.withValues(alpha: 0.6))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: ProfileTheme.ink,
              ),
              const Gap(4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? ProfileTheme.ink : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title over a line of help text, with a switch on the right.
class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Shown in place of the switch (e.g. while a change is saving).
  final Widget? busy;
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        busy ??
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: _green,
              onChanged: onChanged,
            ),
      ],
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
    return _SwitchRow(
      title: on ? 'Published' : 'Unpublished',
      subtitle: on
          ? 'Customers can find and see your restaurant'
          : 'Hidden from customers. Only your team can see it',
      value: on,
      onChanged: toggle,
      busy: busy.value
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
          : null,
    );
  }
}
