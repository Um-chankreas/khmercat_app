import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class AddressRemoteDataSource {
  final ApiClient _client;
  AddressRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> list() async {
    final json = await _client.get(ApiRoute.addresses);
    return json.dataList.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final json = await _client.post(ApiRoute.addresses, body: body);
    return json.dataMap;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final json = await _client.put(ApiRoute.address(id), body: body);
    return json.dataMap;
  }

  Future<void> delete(String id) => _client.delete(ApiRoute.address(id));
}
