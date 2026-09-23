// lib/core/service/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Token management
  Future<bool> saveToken(String token) {
    return _prefs.setString(StorageKeys.token, token);
  }

  String? getToken() => _prefs.getString(StorageKeys.token);

  // User cache
  Future<bool> saveUser(String jsonUser) {
    return _prefs.setString(StorageKeys.user, jsonUser);
  }

  String? getUser() => _prefs.getString(StorageKeys.user);

  // Active restaurant context (id of the switcher's current selection)
  Future<bool> saveActiveRestaurantId(String? id) {
    if (id == null) return _prefs.remove(StorageKeys.activeRestaurantId);
    return _prefs.setString(StorageKeys.activeRestaurantId, id);
  }

  String? getActiveRestaurantId() =>
      _prefs.getString(StorageKeys.activeRestaurantId);

  // App preferences (kept across sign-out).
  Future<bool> saveThemeMode(String value) =>
      _prefs.setString(StorageKeys.themeMode, value);

  String? getThemeMode() => _prefs.getString(StorageKeys.themeMode);

  Future<bool> saveLocale(String? languageCode) {
    if (languageCode == null) return _prefs.remove(StorageKeys.locale);
    return _prefs.setString(StorageKeys.locale, languageCode);
  }

  String? getLocale() => _prefs.getString(StorageKeys.locale);

  Future<bool> clearSession() async {
    await _prefs.remove(StorageKeys.token);
    await _prefs.remove(StorageKeys.user);
    await _prefs.remove(StorageKeys.activeRestaurantId);
    return true;
  }
}
