import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/service/storage_provider.dart';

/// Persisted theme-mode preference (system / light / dark). Read once on
/// startup from [StorageService] and written back on every change.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.read(storageServiceProvider).getThemeMode();
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(storageServiceProvider).saveThemeMode(mode.name);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Persisted language preference. `null` means "follow the device locale".
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(storageServiceProvider).getLocale();
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    await ref.read(storageServiceProvider).saveLocale(locale?.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
