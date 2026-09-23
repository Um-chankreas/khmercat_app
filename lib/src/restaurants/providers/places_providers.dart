// lib/features/places/providers/places_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import '../data/datasources/places_remote_datasource.dart';
import '../data/repositories/places_repository_impl.dart';
import '../domain/repositories/places_repository.dart';

final placesRemoteDataSourceProvider = Provider<PlacesRemoteDataSource>((ref) {
  return PlacesRemoteDataSource(ref.watch(apiClientProvider));
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepositoryImpl(ref.watch(placesRemoteDataSourceProvider));
});
