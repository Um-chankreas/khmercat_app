// lib/core/config/app_config.dart

enum Environment { dev, staging, production }

class AppConfig {
  static Environment environment = Environment.staging;

  /// Override at build/run time with:
  ///   --dart-define=API_BASE_URL=https://staging.khmercat.com/api
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    switch (environment) {
      case Environment.dev:
        return 'http://192.168.0.129:8000/api';
      case Environment.staging:
        return 'http://159.223.43.180/api';
      case Environment.production:
        return 'https://api.khmercat.com/api';
    }
  }

  /// Override at build/run time with:
  ///   --dart-define=REVERB_APP_KEY=xxxxx
  static const String _reverbAppKeyOverride = String.fromEnvironment(
    'REVERB_APP_KEY',
  );

  /// Laravel Reverb's public app key (the server's REVERB_APP_KEY) — safe
  /// to embed client-side, unlike REVERB_APP_SECRET, which never leaves the
  /// server. Each server has its own; a wrong key is rejected with "4001
  /// Application does not exist".
  static String get reverbAppKey {
    if (_reverbAppKeyOverride.isNotEmpty) return _reverbAppKeyOverride;
    switch (environment) {
      case Environment.dev:
        return 'f7pjogc8xmbgpu5vamu5';
      case Environment.staging:
      // TODO: production's own key once api.khmercat.com has a server.
      case Environment.production:
        return '14b0a0e858ab588c728e521d070b03ecb4193613';
    }
  }

  /// Reverb always shares the API's host (see [baseUrl]).
  static String get reverbHost => Uri.parse(baseUrl).host;

  static const int _reverbPortOverride = int.fromEnvironment('REVERB_PORT');

  /// On a server, nginx proxies `/app` to Reverb, so the websocket uses the
  /// API's own port (80/443) — Reverb's port 8080 isn't open to the
  /// internet. Only a local `php artisan serve` API (an explicit port such
  /// as :8000) talks to `reverb:start` on 8080 directly.
  static int get reverbPort {
    if (_reverbPortOverride != 0) return _reverbPortOverride;
    final api = Uri.parse(baseUrl);
    final behindProxy = !api.hasPort || api.port == 80 || api.port == 443;
    return behindProxy ? api.port : 8080;
  }

  /// `wss` whenever the API is https, unless overridden with
  /// --dart-define=REVERB_TLS=true|false.
  static bool get reverbUseTls => const bool.hasEnvironment('REVERB_TLS')
      ? const bool.fromEnvironment('REVERB_TLS')
      : Uri.parse(baseUrl).scheme == 'https';

  /// Rewrites the scheme/host/port of an absolute media URL (video,
  /// thumbnail, profile picture, ...) to match [baseUrl].
  ///
  /// The backend embeds its own `APP_URL` host in these URLs, which drifts
  /// from the current dev IP whenever you switch Wi-Fi networks. Routing
  /// every media URL through this keeps a single source of truth: change
  /// the dev IP above and playback fixes itself without touching the
  /// backend `.env`.
  static String fixMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) return url;

    final target = Uri.parse(baseUrl);
    return uri
        .replace(scheme: target.scheme, host: target.host, port: target.port)
        .toString();
  }
}
