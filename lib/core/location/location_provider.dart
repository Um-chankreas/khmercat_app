// lib/core/location/location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Resolves the device position once, in the background, without blocking
/// whatever screen asked for it. Callers should fetch/render without
/// location first, then react to this becoming non-null to refine results
/// (e.g. re-fetch the feed with lat/lng once permission is granted).
class LocationController extends Notifier<Position?> {
  @override
  Position? build() {
    _resolve();
    return null;
  }

  Future<void> _resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      state = position;
    } catch (_) {
      // No location — callers just fall back to their non-location behavior.
    }
  }

  /// User-initiated retry (e.g. an "Enable location" button): asks for the
  /// permission again, or sends the user to the right settings screen when
  /// it can't be asked for any more.
  Future<void> enable() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) return;
      state = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {}
  }
}

final locationProvider = NotifierProvider<LocationController, Position?>(
  LocationController.new,
);
