import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

import '../domain/saved_address.dart';
import '../providers/address_providers.dart';

/// The signed-in user's saved addresses, newest first. Shared by the
/// Addresses screen and the count on the Menu's "Saved addresses" row.
class AddressesController extends AsyncNotifier<List<SavedAddress>> {
  @override
  FutureOr<List<SavedAddress>> build() async {
    if (!ref.watch(isAuthenticatedProvider)) return const [];
    return ref.read(addressRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(addressRepositoryProvider).list(),
    );
  }

  /// Creates an address, or updates the one with [id]. When it fails,
  /// `message` is the server's reason if it gave one.
  Future<({bool ok, String? message})> save({
    String? id,
    required AddressLabel label,
    required String address,
    required String? detail,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final saved = await ref
          .read(addressRepositoryProvider)
          .save(
            id: id,
            label: label,
            address: address,
            detail: detail,
            latitude: latitude,
            longitude: longitude,
          );
      final current = state.value ?? const <SavedAddress>[];
      state = AsyncData(
        id == null
            ? [saved, ...current]
            : [for (final a in current) a.id == id ? saved : a],
      );
      return (ok: true, message: null);
    } on ApiException catch (e) {
      return (ok: false, message: e.message);
    } catch (_) {
      return (ok: false, message: null);
    }
  }

  /// Removes it from the list right away and puts it back if the request
  /// fails. Returns whether it was deleted.
  Future<bool> remove(String id) async {
    final before = state.value;
    if (before == null) return false;
    state = AsyncData([
      for (final a in before)
        if (a.id != id) a,
    ]);
    try {
      await ref.read(addressRepositoryProvider).delete(id);
      return true;
    } catch (_) {
      state = AsyncData(before);
      return false;
    }
  }
}

final addressesControllerProvider =
    AsyncNotifierProvider<AddressesController, List<SavedAddress>>(
      AddressesController.new,
    );
