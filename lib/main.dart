import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/core/service/push_notification_provider.dart';
import 'package:khmer_cat_app/core/service/storage_provider.dart';
import 'package:khmer_cat_app/core/service/storage_service.dart';
import 'package:khmer_cat_app/core/settings/app_settings_controller.dart';
import 'package:khmer_cat_app/core/themes/app_themes_mode.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  AppConfig.environment = Environment.dev;
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (push notifications) reads android/app/google-services.json and
  // ios/Runner/GoogleService-Info.plist natively — no Dart-side project
  // config needed for mobile. Until those files are actually added (see
  // PushNotificationService's doc comment), this throws; caught here so the
  // rest of the app boots normally in the meantime, just without push.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      'Firebase not initialized (expected until Firebase is set up): $e',
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    // Connects once when the app opens and stays connected for its whole
    // life — not per-screen — so a comments sheet (or any future realtime
    // feature) just subscribes to its channel on an already-live socket
    // instead of paying a fresh connect on every open. See ReverbSocket's
    // doc comment for the full connection-lifecycle rationale.
    useEffect(() {
      ref.read(reverbSocketProvider).connect();
      ref.read(pushNotificationServiceProvider).initialize();
      return null;
    }, const []);

    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: AppThemesMode.lightTheme,
      darkTheme: AppThemesMode.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      routerDelegate: AppRouter.router.routerDelegate,
      builder: (context, child) {
        return child!;
      },
    );
  }
}
