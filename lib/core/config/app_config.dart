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

  /// Laravel Reverb's public app key — safe to embed client-side (unlike
  /// REVERB_APP_SECRET, which never leaves the server). Defaults to this
  /// repo's dev `.env` value.
  static String get reverbAppKey => _reverbAppKeyOverride.isNotEmpty
      ? _reverbAppKeyOverride
      : 'f7pjogc8xmbgpu5vamu5';

  /// Reverb always shares the API's host (see [baseUrl]) — just a different
  /// port, since both run on the same machine in dev and behind the same
  /// domain in staging/production.
  static String get reverbHost => Uri.parse(baseUrl).host;

  static const int _reverbPortOverride = int.fromEnvironment('REVERB_PORT');
  static int get reverbPort =>
      _reverbPortOverride != 0 ? _reverbPortOverride : 8080;

  static const bool reverbUseTls = bool.fromEnvironment('REVERB_TLS');

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
