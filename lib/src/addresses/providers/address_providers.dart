import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';

import '../data/address_remote_datasource.dart';
import '../data/address_repository.dart';

final addressRemoteDataSourceProvider = Provider<AddressRemoteDataSource>((
  ref,
) {
  return AddressRemoteDataSource(ref.watch(apiClientProvider));
});

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(addressRemoteDataSourceProvider));
});
