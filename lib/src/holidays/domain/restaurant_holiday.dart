import 'package:khmer_cat_app/core/config/app_config.dart';

/// How the restaurant opens on the holiday.
/// Its label is `holidayModeText` (presentation/holiday_labels.dart).
enum HolidayMode {
  closed('closed'),
  special('special'),
  open('open');

  final String key;
  const HolidayMode(this.key);

  static HolidayMode fromKey(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => HolidayMode.closed);
}

/// A restaurant's holiday notice for one date (from the API), shown as a
/// poster on its profile and in the feed, and as its status that day.
class RestaurantHoliday {
  final String id;
  final String restaurantId;

  /// First and last day (the same for a one-day notice).
  final DateTime date;
  final DateTime endDate;
  final String title;
  final HolidayMode mode;

  /// "08:00" — special hours only.
  final String? opensAt;
  final String? closesAt;
  final String? description;
  final String? imageUrl;

  const RestaurantHoliday({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.endDate,
    required this.title,
    required this.mode,
    this.opensAt,
    this.closesAt,
    this.description,
    this.imageUrl,
  });

  static RestaurantHoliday? maybeFromJson(Object? json) => json is Map
      ? RestaurantHoliday.fromJson(json.cast<String, dynamic>())
      : null;

  factory RestaurantHoliday.fromJson(Map<String, dynamic> json) {
    String? hm(Object? t) =>
        t is String && t.length >= 5 ? t.substring(0, 5) : null;
    final image = json['image_url'];
    final date =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();
    return RestaurantHoliday(
      id: json['id'].toString(),
      restaurantId: json['restaurant_id']?.toString() ?? '',
      // "2026-11-09" — calendar days, kept as local midnight.
      date: date,
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? date,
      title: json['title'] as String? ?? '',
      mode: HolidayMode.fromKey(json['mode'] as String?),
      opensAt: hm(json['opens_at']),
      closesAt: hm(json['closes_at']),
      description: json['description'] as String?,
      imageUrl: image is String && image.isNotEmpty
          ? AppConfig.fixMediaUrl(image)
          : null,
    );
  }

  /// Under way today.
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(date) && !today.isAfter(endDate);
  }

  /// What the poster says. Its other labels, in the app's language, are in
  /// presentation/holiday_labels.dart.
  String get headline => title;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
