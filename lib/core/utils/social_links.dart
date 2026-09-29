import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds openable links from what people type in the social fields:
/// a full URL, or just a username (with or without "@").
abstract class SocialLinks {
  static Uri? facebook(String? value) => _url(value);

  static Uri? tiktok(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('http')) return _url(v);
    return Uri.parse('https://www.tiktok.com/@${_strip(v)}');
  }

  static Uri? telegram(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('http')) return _url(v);
    return Uri.parse('https://t.me/${_strip(v)}');
  }

  /// Opens [uri] in the matching app (or the browser); shows a toast if
  /// nothing can open it.
  static Future<void> open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    AppService.showToast('Couldn\'t open this link.', isError: true);
  }

  static String _strip(String v) => v.startsWith('@') ? v.substring(1) : v;

  static Uri? _url(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    return (uri != null && uri.host.isNotEmpty) ? uri : null;
  }
}
