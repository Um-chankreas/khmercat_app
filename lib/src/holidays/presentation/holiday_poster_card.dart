import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/holidays/presentation/holiday_labels.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';
import 'package:khmer_cat_app/src/holidays/presentation/holiday_poster_art.dart';

/// The restaurant's upcoming holiday on its profile: a small poster with
/// the headline, "Closed · Mon 9 Nov" and the note. Tapping opens the full
/// poster; [onRemove] (the team) adds a ⋯ to take it down.
class HolidayPosterCard extends StatelessWidget {
  final RestaurantHoliday holiday;
  final String restaurantName;
  final VoidCallback? onRemove;
  const HolidayPosterCard({
    required this.holiday,
    required this.restaurantName,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    final note = holiday.description?.trim();
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => showHolidayPoster(context, holiday, restaurantName),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              ProfileTheme.brandPink.withValues(alpha: 0.18),
              ProfileTheme.brandBlue.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: HolidayPosterArt(
                restaurantName: restaurantName,
                headline: holiday.headline,
                pillLabel: holiday.pillText(context),
                imageUrl: holiday.imageUrl,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday.isToday ? l.holidayToday : l.holidayNotice,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xffB0125A),
                    ),
                  ),
                  const Gap(3),
                  Text(
                    holiday.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    holiday.pillText(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const Gap(4),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemove != null)
              PopupMenuButton<void>(
                icon: Icon(Icons.more_horiz_rounded, color: muted),
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: onRemove,
                    child: Text(
                      l.removePoster,
                      style: const TextStyle(color: Color(0xffE5484D)),
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

/// The full poster and its note, over the page.
Future<void> showHolidayPoster(
  BuildContext context,
  RestaurantHoliday holiday,
  String restaurantName,
) {
  final note = holiday.description?.trim();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (dialog) => GestureDetector(
      onTap: () => Navigator.pop(dialog),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HolidayPosterArt(
                  restaurantName: restaurantName,
                  headline: holiday.headline,
                  pillLabel: holiday.pillText(context),
                  imageUrl: holiday.imageUrl,
                ),
                if (note != null && note.isNotEmpty) ...[
                  const Gap(16),
                  Text(
                    note,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
