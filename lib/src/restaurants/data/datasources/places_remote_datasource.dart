// lib/features/places/data/datasources/places_remote_datasource.dart
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_route.dart';

class PlacesRemoteDataSource {
  final ApiClient _client;
  PlacesRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> autocomplete(String input) async {
    final json = await _client.get(
      ApiRoute.placesAutocomplete,
      query: {'input': input},
    );
    return json.dataList.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> details(String placeId) async {
    final json = await _client.get(
      ApiRoute.placesDetails,
      query: {'place_id': placeId},
    );
    final data = json.dataMap;
    return data.isEmpty ? null : data;
  }
}
