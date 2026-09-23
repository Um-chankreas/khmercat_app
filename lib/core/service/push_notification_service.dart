// lib/core/service/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/app_log.dart';

/// Must be a top-level (or static) function — Android runs it in a separate
/// background isolate with no access to the rest of the app's state — and
/// `@pragma('vm:entry-point')` is required so the AOT compiler doesn't strip
/// it as unused.
///
/// There's nothing to do here: every push this app sends carries a
/// `notification` payload (see PushNotificationService::sendToUser on the
/// backend), and the OS already shows those on its own while the app is
/// backgrounded/killed. `onBackgroundMessage` still has to be *registered*
/// with something, even a no-op, or `firebase_messaging` throws on startup.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Wraps `firebase_messaging`: permission + token registration, foreground
/// display, and tap-to-open. [initialize] is safe to call even when Firebase
/// itself failed to start (no `google-services.json` /
/// `GoogleService-Info.plist` yet) — it just logs and does nothing, so the
/// rest of the app keeps working while that setup is still in progress.
class PushNotificationService {
  final ApiClient _client;
  PushNotificationService(this._client);

  String? _lastRegisteredToken;

  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages don't show a system notification on their own
      // (that's an OS default, not something this app can opt out of
      // cheaply) — surface it the same way the rest of the app shows
      // transient feedback.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        final text = [
          notification.title,
          notification.body,
        ].whereType<String>().join(': ');
        if (text.isNotEmpty) AppService.showToast(text);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openFromNotification());

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _openFromNotification();

      FirebaseMessaging.instance.onTokenRefresh.listen((_) => registerToken());
    } catch (e) {
      AppLog.info('Push notifications unavailable (Firebase not set up yet?): $e');
    }
  }

  /// Deep-linking to the exact video/comment needs a "get one video by id"
  /// endpoint the backend doesn't have yet — for now a tap just brings the
  /// app to the front on the main feed, which is still meaningfully better
  /// than doing nothing.
  void _openFromNotification() {
    AppRouter.router.go(AppRoute.home.path);
  }

  /// Call once the user is signed in (and again is harmless — cheap no-op
  /// if the token hasn't changed). No-ops silently if Firebase isn't set up
  /// yet or the user hasn't granted notification permission.
  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token == _lastRegisteredToken) return;

      await _client.post(
        ApiRoute.deviceTokens,
        body: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
      _lastRegisteredToken = token;
    } catch (e) {
      AppLog.info('Failed to register push token: $e');
    }
  }

  /// Call on logout so a shared/reset device stops getting push
  /// notifications for the account that just signed out.
  Future<void> unregisterToken() async {
    try {
      final token = _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await _client.delete(ApiRoute.deviceTokens, body: {'token': token});
      _lastRegisteredToken = null;
    } catch (e) {
      AppLog.info('Failed to unregister push token: $e');
    }
  }
}
