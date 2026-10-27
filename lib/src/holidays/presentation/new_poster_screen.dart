import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/holidays/presentation/holiday_labels.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';
import 'package:khmer_cat_app/src/holidays/presentation/holiday_poster_art.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_logo.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

const _crimson = Color(0xffB0125A);
const _maxDescription = 300;

/// Restaurants the person may post for: theirs as owner or manager.
List<Restaurant> postableRestaurants(List<Restaurant> mine) => [
  for (final r in mine)
    if (r.myRole == 'owner' || r.myRole == 'manager') r,
];

/// How long the notice can run, in days.
const _maxDays = 7;

/// "New poster": a holiday notice (closed, special hours or open) with an
/// optional photo, for one or several of the person's restaurants — only
/// the current one while acting as a restaurant.
class NewPosterScreen extends HookConsumerWidget {
  const NewPosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = l.localeName;
    final active = ref.watch(activeRestaurantProvider);
    final mine = postableRestaurants(
      ref.watch(myRestaurantsControllerProvider).valueOrNull?.restaurants ??
          const [],
    );
    // Acting as a restaurant: only that one.
    final choices = active != null ? [active] : mine;

    final selected = useState<Set<String>>({for (final r in choices) r.id});
    // The list may load after the first build: select all once it does.
    useEffect(() {
      if (selected.value.isEmpty && choices.isNotEmpty) {
        Future.microtask(
          () => selected.value = {for (final r in choices) r.id},
        );
      }
      return null;
    }, [choices.length]);

    final title = useTextEditingController();
    useListenable(title);
    final startDate = useState(() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + 1);
    }());
    final days = useState(1);
    final mode = useState(HolidayMode.closed);
    final opensAt = useState(const TimeOfDay(hour: 8, minute: 0));
    final closesAt = useState(const TimeOfDay(hour: 14, minute: 0));
    final image = useState<File?>(null);
    final description = useTextEditingController();
    useListenable(description);
    final posting = useState(false);

    final name = title.text.trim();
    final start = startDate.value;
    final end = DateTime(start.year, start.month, start.day + days.value - 1);
    final headline = name.isEmpty ? l.posterTitlePlaceholder : name;
    String hm(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    final pill = holidayPillText(
      context,
      mode.value,
      start,
      end,
      hm(opensAt.value),
      hm(closesAt.value),
    );
    final chosen = [
      for (final r in choices)
        if (selected.value.contains(r.id)) r,
    ];
    final previewName = chosen.isNotEmpty
        ? chosen.first.name
        : (choices.firstOrNull?.name ?? '');
    final canPost = chosen.isNotEmpty && name.isNotEmpty && !posting.value;

    Future<void> pickImage() async {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (file != null) image.value = File(file.path);
    }

    Future<void> pickStartDate() async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 1, now.month, now.day),
      );
      if (date != null) startDate.value = date;
    }

    Future<void> pickTime(ValueNotifier<TimeOfDay> target) async {
      final t = await showTimePicker(
        context: context,
        initialTime: target.value,
      );
      if (t != null) target.value = t;
    }

    Future<void> post() async {
      posting.value = true;
      try {
        await ref
            .read(restaurantRepositoryProvider)
            .postHoliday(
              restaurantIds: [for (final r in chosen) r.id],
              date: start,
              days: days.value,
              title: name,
              mode: mode.value,
              opensAt: hm(opensAt.value),
              closesAt: hm(closesAt.value),
              description: description.text.trim(),
              image: image.value,
            );
        // Profiles that are open show the new poster straight away.
        for (final r in chosen) {
          final p = restaurantProfileControllerProvider(r.id);
          if (ref.exists(p)) ref.read(p.notifier).refreshQuietly();
        }
        AppService.showToast(
          chosen.length == 1
              ? l.posterPosted
              : l.posterPostedMany(chosen.length),
        );
        if (context.mounted) Navigator.of(context).pop(true);
      } on ApiException catch (e) {
        AppService.showToast(
          e.isValidationError ? e.allErrorsMessage : e.message,
          isError: true,
        );
      } catch (_) {
        AppService.showToast(l.posterPostFailed, isError: true);
      } finally {
        if (context.mounted) posting.value = false;
      }
    }

    final status = holidayTodayText(
      context,
      mode.value,
      hm(opensAt.value),
      hm(closesAt.value),
      name.isEmpty ? l.posterYourHoliday : name,
    );

    return GestureDetector(
      onTap: () => AppService.dismissKeyboard(context),
      behavior: HitTestBehavior.opaque,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: SoftCirclesBackdrop()),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _TopBar(
                      canPost: canPost,
                      posting: posting.value,
                      onPost: post,
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          MediaQuery.paddingOf(context).bottom + 28,
                        ),
                        children: [
                          // ---- Poster preview -----------------------------
                          Center(
                            child: SizedBox(
                              width: 240,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xff3B1C7A,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: HolidayPosterArt(
                                  restaurantName: previewName,
                                  headline: headline,
                                  pillLabel: pill,
                                  imageFile: image.value,
                                  corner: _PhotoButton(
                                    hasImage: image.value != null,
                                    onTap: pickImage,
                                    onRemove: image.value == null
                                        ? null
                                        : () => image.value = null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(24),

                          // ---- Title --------------------------------------
                          _Label(l.posterTitleLabel),
                          const Gap(10),
                          _Card(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: TextField(
                              controller: title,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ProfileTheme.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: l.posterTitleHint,
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: ProfileTheme.muted.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          const Gap(24),

                          // ---- Description --------------------------------
                          _Label(l.posterDescriptionLabel),
                          const Gap(10),
                          _Card(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: TextField(
                              controller: description,
                              maxLength: _maxDescription,
                              minLines: 3,
                              maxLines: 6,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: ProfileTheme.ink,
                              ),
                              buildCounter:
                                  (
                                    _, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => Text(
                                    '$currentLength / $maxLength',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: ProfileTheme.muted,
                                    ),
                                  ),
                              decoration: InputDecoration(
                                hintText: l.posterDescriptionHint(
                                  DateFormat(
                                    'EEEE d MMMM',
                                    locale,
                                  ).format(start),
                                ),
                                hintStyle: TextStyle(
                                  color: ProfileTheme.muted.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const Gap(24),

                          // ---- Apply to -----------------------------------
                          Row(
                            children: [
                              _Label(l.posterApplyTo),
                              if (active == null && choices.length > 1)
                                Text(
                                  ' · ${l.chosenOfTotal(chosen.length, choices.length)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: ProfileTheme.muted,
                                  ),
                                ),
                              const Spacer(),
                              if (active == null && choices.length > 1)
                                GestureDetector(
                                  onTap: () => selected.value =
                                      chosen.length == choices.length
                                      ? {}
                                      : {for (final r in choices) r.id},
                                  child: Text(
                                    chosen.length == choices.length
                                        ? l.clearAction
                                        : l.selectAll,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _crimson,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (active != null) ...[
                            const Gap(4),
                            Text(
                              l.posterActingAs,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: ProfileTheme.muted,
                              ),
                            ),
                          ],
                          const Gap(10),
                          _Card(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                for (final r in choices)
                                  _RestaurantRow(
                                    restaurant: r,
                                    // Acting as one: no choice to make.
                                    selected: active != null
                                        ? null
                                        : selected.value.contains(r.id),
                                    onTap: active != null
                                        ? null
                                        : () => selected.value =
                                              selected.value.contains(r.id)
                                              ? ({...selected.value}
                                                  ..remove(r.id))
                                              : {...selected.value, r.id},
                                  ),
                                if (choices.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      l.posterNoRestaurants,
                                      style: const TextStyle(
                                        color: ProfileTheme.muted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Gap(24),

                          // ---- Opening on the holiday ---------------------
                          _Label(l.posterOpeningOnHoliday),
                          const Gap(10),
                          _Card(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GestureDetector(
                                  onTap: pickStartDate,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 19,
                                        color: ProfileTheme.ink,
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l.posterStarts,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: ProfileTheme.muted,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'EEE, d MMM y',
                                                locale,
                                              ).format(start),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: ProfileTheme.ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        l.changeAction,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _crimson,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(14),
                                _DaysPicker(
                                  value: days.value,
                                  onChanged: (d) => days.value = d,
                                ),
                                if (days.value > 1) ...[
                                  const Gap(8),
                                  Text(
                                    l.posterUntil(
                                      DateFormat(
                                        'EEE, d MMM y',
                                        locale,
                                      ).format(end),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: ProfileTheme.muted,
                                    ),
                                  ),
                                ],
                                const Gap(14),
                                _ModeSwitch(
                                  value: mode.value,
                                  onChanged: (m) => mode.value = m,
                                ),
                                if (mode.value == HolidayMode.special) ...[
                                  const Gap(12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TimeField(
                                          label: l.posterOpens,
                                          value: holidayTime(
                                            context,
                                            hm(opensAt.value),
                                          ),
                                          onTap: () => pickTime(opensAt),
                                        ),
                                      ),
                                      const Gap(10),
                                      Expanded(
                                        child: _TimeField(
                                          label: l.posterCloses,
                                          value: holidayTime(
                                            context,
                                            hm(closesAt.value),
                                          ),
                                          onTap: () => pickTime(closesAt),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Gap(12),
                                _StatusNote(status: status),
                              ],
                            ),
                          ),
                        ],
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

class _TopBar extends StatelessWidget {
  final bool canPost;
  final bool posting;
  final VoidCallback onPost;
  const _TopBar({
    required this.canPost,
    required this.posting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: ProfileTheme.ink,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).newPosterTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ProfileTheme.ink,
            ),
          ),
          Positioned(
            right: 12,
            child: GestureDetector(
              onTap: canPost ? onPost : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: canPost || posting
                      ? ProfileTheme.brandGradient
                      : null,
                  color: canPost || posting ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ProfileTheme.ink,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).postAction,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: canPost
                              ? ProfileTheme.ink
                              : Colors.grey.shade500,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: ProfileTheme.ink,
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff3B1C7A).withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// "Change" / "Add photo" pill on the preview's corner, plus a remove "×".
class _PhotoButton extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _PhotoButton({
    required this.hasImage,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(Widget child, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRemove != null) ...[
          pill(
            const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            onRemove!,
          ),
          const Gap(6),
        ],
        pill(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, size: 16, color: Colors.white),
              const Gap(6),
              Text(
                hasImage
                    ? AppLocalizations.of(context).changeAction
                    : AppLocalizations.of(context).addPhoto,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          onTap,
        ),
      ],
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;

  /// null: not selectable (acting as this restaurant).
  final bool? selected;
  final VoidCallback? onTap;
  const _RestaurantRow({
    required this.restaurant,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final address = restaurant.address?.trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            RestaurantLogo(restaurant: restaurant, size: 44, borderRadius: 12),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.ink,
                    ),
                  ),
                  if (address != null && address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: ProfileTheme.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (selected != null) ...[
              const Gap(10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected! ? ProfileTheme.brandGradient : null,
                  border: selected!
                      ? null
                      : Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: selected!
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: ProfileTheme.ink,
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Closed · Special · Open, as a segmented pill.
class _ModeSwitch extends StatelessWidget {
  final HolidayMode value;
  final ValueChanged<HolidayMode> onChanged;
  const _ModeSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF1F1F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final m in HolidayMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(m);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: m == value ? ProfileTheme.brandGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    holidayModeText(context, m),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: m == value
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: m == value ? ProfileTheme.ink : ProfileTheme.muted,
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

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF1F1F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: ProfileTheme.muted),
          ),
          const Gap(2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ProfileTheme.ink,
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Customers will see **Closed today · …** on your profile, search and
/// map that day."
class _StatusNote extends StatelessWidget {
  final String status;
  const _StatusNote({required this.status});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: ProfileTheme.ink,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ProfileTheme.brandPink.withValues(alpha: 0.18),
            ProfileTheme.brandBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _crimson,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: AppLocalizations.of(context).posterSeePrefix),
                  TextSpan(
                    text: status,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: AppLocalizations.of(context).posterSeeSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1 day · 2 days · … · 7 days, as scrollable chips.
class _DaysPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DaysPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _maxDays,
        separatorBuilder: (_, _) => const Gap(8),
        itemBuilder: (_, i) {
          final d = i + 1;
          final on = d == value;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: on ? ProfileTheme.brandGradient : null,
                color: on ? null : const Color(0xffF1F1F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                AppLocalizations.of(context).daysCount(d),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? ProfileTheme.ink : ProfileTheme.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// What the + button creates, for people who run a restaurant.
enum CreateKind { video, holidayPoster }

/// The + button's "Create" sheet for restaurant owners/managers: who it
/// posts as, then Video or Holiday poster.
Future<CreateKind?> showCreateChooser(
  BuildContext context, {
  required String postingAs,
  String? avatarUrl,
}) {
  return showModalBottomSheet<CreateKind>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateSheet(postingAs: postingAs, avatarUrl: avatarUrl),
  );
}

class _CreateSheet extends StatelessWidget {
  final String postingAs;
  final String? avatarUrl;
  const _CreateSheet({required this.postingAs, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).createTitle,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: ProfileTheme.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xffF1F1F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: ProfileTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 28,
                  height: 28,
                  color: const Color(0xffF1F1F5),
                  child: hasAvatar
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: ProfileTheme.muted,
                        ),
                ),
              ),
              const Gap(10),
              Text(
                AppLocalizations.of(context).postingAs,
                style: const TextStyle(fontSize: 14, color: ProfileTheme.muted),
              ),
              Flexible(
                child: Text(
                  postingAs,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: ProfileTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _CreateCard(
                  icon: Icons.videocam_outlined,
                  title: AppLocalizations.of(context).createVideoTitle,
                  subtitle: AppLocalizations.of(context).createVideoSub,
                  tint: ProfileTheme.brandPink,
                  onTap: () => Navigator.pop(context, CreateKind.video),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _CreateCard(
                  icon: Icons.calendar_month_outlined,
                  title: AppLocalizations.of(context).createPosterTitle,
                  subtitle: AppLocalizations.of(context).createPosterSub,
                  tint: ProfileTheme.brandBlue,
                  onTap: () => Navigator.pop(context, CreateKind.holidayPoster),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A soft tinted tile: white icon circle, title, subtitle and a faint
/// circle in the corner.
class _CreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  const _CreateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint.withValues(alpha: 0.28),
              tint.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              bottom: -34,
              width: 88,
              height: 88,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: ProfileTheme.ink),
                  ),
                  const Gap(12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.ink,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ProfileTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
