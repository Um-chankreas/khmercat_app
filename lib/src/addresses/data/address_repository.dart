import '../domain/saved_address.dart';
import 'address_remote_datasource.dart';

class AddressRepository {
  final AddressRemoteDataSource _remote;
  AddressRepository(this._remote);

  /// Newest first.
  Future<List<SavedAddress>> list() async =>
      (await _remote.list()).map(SavedAddress.fromJson).toList();

  /// Creates the address, or updates the one with [id].
  Future<SavedAddress> save({
    String? id,
    required AddressLabel label,
    required String address,
    required String? detail,
    required double latitude,
    required double longitude,
  }) async {
    final body = {
      'label': label.apiValue,
      'address': address,
      'detail': detail,
      'latitude': latitude,
      'longitude': longitude,
    };
    return SavedAddress.fromJson(
      id == null ? await _remote.create(body) : await _remote.update(id, body),
    );
  }

  Future<void> delete(String id) => _remote.delete(id);
}
