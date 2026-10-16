import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';

import '../domain/person.dart';

typedef PeoplePage = ({List<Person> people, bool hasMore});

class PeopleRemoteDataSource {
  final ApiClient _client;
  PeopleRemoteDataSource(this._client);

  /// One page (from 1) of the list at [path].
  Future<PeoplePage> page(String path, int page) async {
    final data = (await _client.get(path, query: {'page': page})).dataMap;
    return (
      people: (data['people'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Person.fromJson)
          .toList(),
      hasMore: data['has_more'] == true,
    );
  }
}

final peopleRemoteDataSourceProvider = Provider<PeopleRemoteDataSource>((ref) {
  return PeopleRemoteDataSource(ref.watch(apiClientProvider));
});
