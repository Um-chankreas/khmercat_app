// lib/features/places/data/repositories/places_repository_impl.dart
import '../../domain/entities/place_details.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_datasource.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesRemoteDataSource _remote;
  PlacesRepositoryImpl(this._remote);

  @override
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final list = await _remote.autocomplete(input);
    return list
        .map(
          (e) => PlaceSuggestion(
            placeId: e['place_id'],
            description: e['description'],
          ),
        )
        .toList();
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final data = await _remote.details(placeId);
    if (data == null) return null;
    return PlaceDetails(
      placeId: data['place_id'],
      name: data['name'],
      address: data['address'],
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      businessStatus: data['business_status'],
    );
  }
}
