import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class SearchRemoteDataSource {
  final ApiClient _client;
  SearchRemoteDataSource(this._client);

  Future<Map<String, dynamic>> search(String query) async {
    final json = await _client.get(ApiRoute.search, query: {'q': query});
    return json.dataMap;
  }
}
