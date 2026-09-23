import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class UserRemoteDataSource {
  final ApiClient _client;
  UserRemoteDataSource(this._client);

  Future<Map<String, dynamic>> show(String username) async {
    final json = await _client.get(ApiRoute.user(username));
    return json.dataMap;
  }
}
