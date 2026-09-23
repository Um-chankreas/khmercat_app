import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';

import '../data/search_remote_datasource.dart';
import '../data/search_repository.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource(ref.watch(apiClientProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(searchRemoteDataSourceProvider));
});
