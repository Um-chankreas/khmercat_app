// lib/features/places/domain/repositories/places_repository.dart
import '../entities/place_details.dart';
import '../entities/place_suggestion.dart';

abstract class PlacesRepository {
  Future<List<PlaceSuggestion>> autocomplete(String input);
  Future<PlaceDetails?> getPlaceDetails(String placeId);
}
