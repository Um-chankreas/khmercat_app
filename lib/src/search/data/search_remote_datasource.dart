import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class SearchRemoteDataSource {
  final ApiClient _client;
  SearchRemoteDataSource(this._client);

  Future<Map<String, dynamic>> search({
    String? query,
    String? categoryId,
    double? lat,
    double? lng,
    bool nearest = false,
  }) async {
    final json = await _client.get(
      ApiRoute.search,
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        'category_id': ?categoryId,
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
        if (nearest) 'sort': 'nearest',
      },
    );
    return json.dataMap;
  }
}
