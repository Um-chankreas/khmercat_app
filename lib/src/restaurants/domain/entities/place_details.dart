// lib/features/places/domain/entities/place_details.dart
class PlaceDetails {
  final String placeId;
  final String? name;
  final String? address;
  final double lat;
  final double lng;
  final String? businessStatus;

  const PlaceDetails({
    required this.placeId,
    this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.businessStatus,
  });
}
