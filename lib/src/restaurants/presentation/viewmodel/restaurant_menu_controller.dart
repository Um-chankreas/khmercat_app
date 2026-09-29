import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_menu.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/providers/restaurant_providers.dart';

/// A restaurant's menu pages (keyed by restaurant id). Owners add and remove
/// pages through it; the restaurant profile reloads so its page count and
/// Menu button stay in sync.
class RestaurantMenuController
    extends FamilyAsyncNotifier<RestaurantMenu, String> {
  @override
  FutureOr<RestaurantMenu> build(String restaurantId) =>
      ref.read(restaurantRepositoryProvider).menu(restaurantId);

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(restaurantRepositoryProvider).menu(arg),
    );
  }

  /// Uploads [files] as new pages after the existing ones. Throws on
  /// failure (the screen shows the message) and keeps the current pages.
  Future<void> addPages(
    List<File> files, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final menu = await ref
        .read(restaurantRepositoryProvider)
        .uploadMenuPages(arg, files, onProgress: onProgress);
    state = AsyncData(menu);
    _refreshProfile();
  }

  /// Removes a page right away; puts it back if the server refuses.
  Future<bool> deletePage(String pageId) async {
    final before = state.valueOrNull;
    if (before != null) {
      state = AsyncData(
        RestaurantMenu(
          menuUrl: before.menuUrl,
          pages: before.pages.where((p) => p.id != pageId).toList(),
        ),
      );
    }
    try {
      final menu = await ref
          .read(restaurantRepositoryProvider)
          .deleteMenuPage(arg, pageId);
      state = AsyncData(menu);
      _refreshProfile();
      return true;
    } catch (_) {
      if (before != null) state = AsyncData(before);
      return false;
    }
  }

  void _refreshProfile() {
    ref
        .read(restaurantProfileControllerProvider(arg).notifier)
        .refreshQuietly();
  }
}

final restaurantMenuControllerProvider =
    AsyncNotifierProvider.family<
      RestaurantMenuController,
      RestaurantMenu,
      String
    >(RestaurantMenuController.new);
