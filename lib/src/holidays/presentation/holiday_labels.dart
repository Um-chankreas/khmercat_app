import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';

/// The holiday's labels in the app's language: weekday and month names, and
/// AM/PM, follow the locale too.
extension HolidayLabels on RestaurantHoliday {
  /// "Closed · Mon 9 Nov", "8:00 AM – 2:00 PM · Mon 9 – Tue 10 Nov",
  /// "Open · …".
  String pillText(BuildContext context) =>
      holidayPillText(context, mode, date, endDate, opensAt, closesAt);

  /// "Closed today · Independence Day", "Open 8:00 AM – 2:00 PM today · …",
  /// "Open today · …".
  String todayText(BuildContext context) =>
      holidayTodayText(context, mode, opensAt, closesAt, title);
}

/// [RestaurantHoliday.pillText] for a poster that isn't saved yet.
String holidayPillText(
  BuildContext context,
  HolidayMode mode,
  DateTime date,
  DateTime endDate,
  String? opensAt,
  String? closesAt,
) {
  final l = AppLocalizations.of(context);
  final dates = _dateRange(date, endDate, l.localeName);
  return switch (mode) {
    HolidayMode.closed => l.holidayClosedOn(dates),
    HolidayMode.special =>
      '${holidayTime(context, opensAt)} – '
          '${holidayTime(context, closesAt)} · $dates',
    HolidayMode.open => l.holidayOpenOn(dates),
  };
}

/// [RestaurantHoliday.todayText] for a poster that isn't saved yet.
String holidayTodayText(
  BuildContext context,
  HolidayMode mode,
  String? opensAt,
  String? closesAt,
  String title,
) {
  final l = AppLocalizations.of(context);
  return switch (mode) {
    HolidayMode.closed => l.holidayClosedToday(title),
    HolidayMode.special => l.holidayOpenHoursToday(
      holidayTime(context, opensAt),
      holidayTime(context, closesAt),
      title,
    ),
    HolidayMode.open => l.holidayOpenToday(title),
  };
}

/// "Closed" / "Special" / "Open".
String holidayModeText(BuildContext context, HolidayMode mode) {
  final l = AppLocalizations.of(context);
  return switch (mode) {
    HolidayMode.closed => l.closedStatus,
    HolidayMode.special => l.modeSpecial,
    HolidayMode.open => l.modeOpen,
  };
}

/// "08:00" → "8:00 AM" in the app's language.
String holidayTime(BuildContext context, String? hm) {
  if (hm == null || hm.length < 5) return '–';
  final h = int.tryParse(hm.substring(0, 2)) ?? 0;
  final m = int.tryParse(hm.substring(3, 5)) ?? 0;
  return DateFormat.jm(
    AppLocalizations.of(context).localeName,
  ).format(DateTime(2000, 1, 1, h, m));
}

/// "Mon 9 Nov", "Mon 9 – Tue 10 Nov", "Mon 30 Nov – Tue 1 Dec" in [locale].
String _dateRange(DateTime start, DateTime end, String locale) {
  final full = DateFormat('EEE d MMM', locale);
  if (isSameDay(start, end)) return full.format(start);
  return start.month == end.month && start.year == end.year
      ? '${DateFormat('EEE d', locale).format(start)} – ${full.format(end)}'
      : '${full.format(start)} – ${full.format(end)}';
}
