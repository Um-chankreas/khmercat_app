import 'package:khmer_cat_app/core/config/app_config.dart';

/// One page (photo) of a restaurant's menu.
class MenuPage {
  final String id;
  final String url;
  final int position;

  const MenuPage({required this.id, required this.url, required this.position});

  factory MenuPage.fromJson(Map<String, dynamic> json) => MenuPage(
    id: json['id'].toString(),
    url: AppConfig.fixMediaUrl(json['url'] as String),
    position: (json['position'] as num?)?.toInt() ?? 0,
  );
}

/// A restaurant's menu: its pages in order, and the public web page URL its
/// QR code encodes (diners can scan it without the app).
class RestaurantMenu {
  final String menuUrl;
  final List<MenuPage> pages;

  const RestaurantMenu({required this.menuUrl, required this.pages});

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) => RestaurantMenu(
    menuUrl: AppConfig.fixMediaUrl(json['menu_url'] as String? ?? ''),
    pages: (json['images'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(MenuPage.fromJson)
        .toList(),
  );
}
