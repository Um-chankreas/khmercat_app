/// What a saved address is for.
enum AddressLabel {
  home('home'),
  office('office'),
  other('other');

  const AddressLabel(this.apiValue);

  /// The value the API stores.
  final String apiValue;

  static AddressLabel fromApi(String? value) =>
      values.firstWhere((l) => l.apiValue == value, orElse: () => other);
}

/// One of the user's saved addresses (Menu → Address).
class SavedAddress {
  final String id;
  final AddressLabel label;

  /// The street address the map pin resolved to.
  final String address;

  /// House number, building, floor — typed by the user, optional.
  final String? detail;
  final double latitude;
  final double longitude;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.detail,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'].toString(),
    label: AddressLabel.fromApi(json['label'] as String?),
    address: json['address'] as String? ?? '',
    detail: switch (json['detail']) {
      final String d when d.trim().isNotEmpty => d,
      _ => null,
    },
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  /// "Floor 3, Street 271, Phnom Penh" — the detail first, as it's read
  /// to a driver.
  String get fullAddress => detail == null ? address : '$detail, $address';
}
