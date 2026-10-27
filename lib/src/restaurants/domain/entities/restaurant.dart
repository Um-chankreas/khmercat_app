import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/src/holidays/domain/restaurant_holiday.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';

class RestaurantCategory {
  final String id;
  final String name;
  final String? icon;

  RestaurantCategory({required this.id, required this.name, this.icon});

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) =>
      RestaurantCategory(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String?,
      );
}

/// The delivery apps a restaurant can link to. [key] is what the API
/// stores as a link's `name` (must match Restaurant::DELIVERY_APPS).
enum DeliveryApp {
  grab('grab', 'Grab'),
  foodpanda('foodpanda', 'foodpanda'),
  wownow('wownow', 'WOWNOW');

  final String key;
  final String label;
  const DeliveryApp(this.key, this.label);

  String get asset => switch (this) {
    DeliveryApp.grab => AssetsName.grab,
    DeliveryApp.foodpanda => AssetsName.foodpanda,
    DeliveryApp.wownow => AssetsName.wownow,
  };

  static DeliveryApp? fromKey(String key) {
    final k = key.toLowerCase();
    for (final app in values) {
      if (app.key == k) return app;
    }
    return null;
  }
}

/// An order-delivery app the restaurant is listed on (Grab, foodpanda, …).
class DeliveryLink {
  final String name;
  final String url;
  const DeliveryLink({required this.name, required this.url});

  /// The known app this link is for, or null for an unrecognised name.
  DeliveryApp? get app => DeliveryApp.fromKey(name);

  String get label => app?.label ?? name;

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory DeliveryLink.fromJson(Map<String, dynamic> json) => DeliveryLink(
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
  );
}

class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? profilePicture;
  final String? coverPicture;
  final double? latitude;
  final double? longitude;

  /// pending (awaiting an admin) → approved, or rejected. Only approved
  /// ones are public.
  final String status;

  /// Why an admin rejected it, if they said.
  final String? rejectionReason;
  final int? followersCount;

  /// Accounts this restaurant follows; null until the API sends it.
  final int? followingCount;
  final RestaurantCategory? category;

  // Search-result extras. All optional: only the search API sends them, and
  // each is null until the restaurant has that data.
  final double? avgRating;
  final int reviewsCount;

  /// Distance from the position sent with the request, in km.
  final double? distanceKm;

  /// Open right now per its opening hours; null when hours aren't set.
  final bool? isOpen;

  /// 1–4, shown as "$" … "$$$$".
  final int? priceLevel;

  /// dine_in | delivery | dine_in_delivery | takeaway
  final String? serviceType;
  final int? deliveryTimeMin;
  final int? deliveryTimeMax;
  final bool isSponsored;

  /// false = hidden from the public by its owner (the team still sees it).
  final bool isPublished;

  /// Set by its team: shown as a Halal badge, and matched by search's
  /// Halal filter.
  final bool isHalal;

  /// Your role here ("owner", "manager", …) — only in your own restaurants
  /// list (GET /restaurants/mine); null elsewhere.
  final String? myRole;

  // Profile / edit-form extras (GET /restaurants/{id}).
  final String? phone;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? telegramUsername;

  /// The restaurant's own published posts.
  final int videosCount;

  /// Menu pages uploaded, and the public web page its QR code opens.
  final int menuPagesCount;
  final String? menuUrl;

  /// "HH:mm:ss" local opening hours, or null when not set.
  final String? openingTime;
  final String? closingTime;

  /// "daily", "Mon – Sat", … — null until the API sends it.
  final String? openDaysLabel;

  /// Delivery apps; empty until the API sends them.
  final List<DeliveryLink> deliveryLinks;

  /// Today's holiday notice: overrides the hours shown (and [isOpen]).
  final RestaurantHoliday? todayHoliday;

  /// The next notice from today on — its poster shows on the profile.
  final RestaurantHoliday? upcomingHoliday;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.profilePicture,
    this.coverPicture,
    this.latitude,
    this.longitude,
    required this.status,
    this.rejectionReason,
    this.followersCount,
    this.followingCount,
    this.category,
    this.avgRating,
    this.reviewsCount = 0,
    this.distanceKm,
    this.isOpen,
    this.priceLevel,
    this.serviceType,
    this.deliveryTimeMin,
    this.deliveryTimeMax,
    this.isSponsored = false,
    this.isPublished = true,
    this.isHalal = false,
    this.myRole,
    this.phone,
    this.facebookUrl,
    this.tiktokUrl,
    this.telegramUsername,
    this.videosCount = 0,
    this.menuPagesCount = 0,
    this.menuUrl,
    this.openingTime,
    this.closingTime,
    this.openDaysLabel,
    this.deliveryLinks = const [],
    this.todayHoliday,
    this.upcomingHoliday,
  });

  String? get priceText =>
      priceLevel == null || priceLevel! < 1 ? null : r'$' * priceLevel!;

  /// "15-25 min", "20 min", or null.
  String? get deliveryTimeText {
    final lo = deliveryTimeMin, hi = deliveryTimeMax;
    if (lo == null && hi == null) return null;
    if (lo == null || hi == null || lo == hi) return '${lo ?? hi} min';
    return '$lo-$hi min';
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    address: json['address'] as String?,
    profilePicture: (json['profile_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['profile_picture'] as String)
        : null,
    coverPicture: (json['cover_picture'] as String?) != null
        ? AppConfig.fixMediaUrl(json['cover_picture'] as String)
        : null,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'pending',
    rejectionReason: json['rejection_reason'] as String?,
    followersCount: (json['followers_count'] as num?)?.toInt(),
    followingCount: (json['following_count'] as num?)?.toInt(),
    category: json['category'] != null
        ? RestaurantCategory.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    avgRating: (json['avg_rating'] as num?)?.toDouble(),
    reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    isOpen: json['is_open'] as bool?,
    priceLevel: (json['price_level'] as num?)?.toInt(),
    serviceType: json['service_type'] as String?,
    deliveryTimeMin: (json['delivery_time_min'] as num?)?.toInt(),
    deliveryTimeMax: (json['delivery_time_max'] as num?)?.toInt(),
    isSponsored: json['is_sponsored'] == true,
    isPublished: json['is_published'] != false,
    isHalal: json['is_halal'] == true,
    myRole: (json['pivot'] as Map?)?['role'] as String?,
    phone: json['phone'] as String?,
    facebookUrl: json['facebook_url'] as String?,
    tiktokUrl: json['tiktok_url'] as String?,
    telegramUsername: json['telegram_username'] as String?,
    videosCount: (json['videos_count'] as num?)?.toInt() ?? 0,
    menuPagesCount: (json['menu_images_count'] as num?)?.toInt() ?? 0,
    menuUrl: (json['menu_url'] as String?) == null
        ? null
        : AppConfig.fixMediaUrl(json['menu_url'] as String),
    openingTime: json['opening_time'] as String?,
    closingTime: json['closing_time'] as String?,
    openDaysLabel: json['open_days_label'] as String?,
    deliveryLinks: [
      for (final l in (json['delivery_links'] as List?) ?? const [])
        DeliveryLink.fromJson(l as Map<String, dynamic>),
    ],
    todayHoliday: RestaurantHoliday.maybeFromJson(json['today_holiday']),
    upcomingHoliday: RestaurantHoliday.maybeFromJson(json['upcoming_holiday']),
  );

  Restaurant copyWith({int? followersCount}) => Restaurant(
    id: id,
    name: name,
    description: description,
    address: address,
    profilePicture: profilePicture,
    coverPicture: coverPicture,
    latitude: latitude,
    longitude: longitude,
    status: status,
    rejectionReason: rejectionReason,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount,
    category: category,
    avgRating: avgRating,
    reviewsCount: reviewsCount,
    distanceKm: distanceKm,
    isOpen: isOpen,
    priceLevel: priceLevel,
    serviceType: serviceType,
    deliveryTimeMin: deliveryTimeMin,
    deliveryTimeMax: deliveryTimeMax,
    isSponsored: isSponsored,
    isPublished: isPublished,
    isHalal: isHalal,
    myRole: myRole,
    phone: phone,
    facebookUrl: facebookUrl,
    tiktokUrl: tiktokUrl,
    telegramUsername: telegramUsername,
    videosCount: videosCount,
    menuPagesCount: menuPagesCount,
    menuUrl: menuUrl,
    openingTime: openingTime,
    closingTime: closingTime,
    openDaysLabel: openDaysLabel,
    deliveryLinks: deliveryLinks,
    todayHoliday: todayHoliday,
    upcomingHoliday: upcomingHoliday,
  );
}
