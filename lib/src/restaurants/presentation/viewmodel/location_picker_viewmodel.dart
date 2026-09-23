// lib/features/places/presentation/viewmodels/location_picker_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../providers/places_providers.dart';

class LocationPickerState {
  final List<PlaceSuggestion> suggestions;
  final bool isSearching;
  final LatLng selectedLocation;
  final String? selectedAddress;
  final String? selectedName;
  final String? selectedPlaceId;

  const LocationPickerState({
    this.suggestions = const [],
    this.isSearching = false,
    required this.selectedLocation,
    this.selectedAddress,
    this.selectedName,
    this.selectedPlaceId,
  });
}

class LocationPickerViewModel extends Notifier<LocationPickerState> {
  Timer? _debounce;

  @override
  LocationPickerState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const LocationPickerState(
      selectedLocation: LatLng(11.5564, 104.9282),
    ); // Phnom Penh default
  }

  void setInitialLocation(LatLng location, {String? address}) {
    state = LocationPickerState(
      selectedLocation: location,
      selectedAddress: address,
    );
  }

  void search(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = LocationPickerState(
        suggestions: const [],
        selectedLocation: state.selectedLocation,
        selectedAddress: state.selectedAddress,
        selectedName: state.selectedName,
        selectedPlaceId: state.selectedPlaceId,
      );
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final repo = ref.read(placesRepositoryProvider);
      try {
        final results = await repo.autocomplete(query);
        state = LocationPickerState(
          suggestions: results,
          selectedLocation: state.selectedLocation,
          selectedAddress: state.selectedAddress,
          selectedName: state.selectedName,
          selectedPlaceId: state.selectedPlaceId,
        );
      } catch (_) {
        // silently ignore — user can keep typing or try again
      }
    });
  }

  /// User tapped a search result — fetch full details and move the pin.
  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    final repo = ref.read(placesRepositoryProvider);
    final details = await repo.getPlaceDetails(suggestion.placeId);
    if (details == null) return;

    state = LocationPickerState(
      suggestions: const [],
      selectedLocation: LatLng(details.lat, details.lng),
      selectedAddress: details.address,
      selectedName: details.name,
      selectedPlaceId: details.placeId,
    );
  }

  /// User dragged the marker or tapped the map manually — no longer tied
  /// to a verified Google place, so clear those fields.
  void selectOnMap(LatLng position) {
    state = LocationPickerState(
      suggestions: const [],
      selectedLocation: position,
      selectedAddress:
          state.selectedAddress, // keep last typed/known address text
      selectedName: null,
      selectedPlaceId: null,
    );
  }
}

final locationPickerViewModelProvider =
    NotifierProvider<LocationPickerViewModel, LocationPickerState>(
      LocationPickerViewModel.new,
    );
