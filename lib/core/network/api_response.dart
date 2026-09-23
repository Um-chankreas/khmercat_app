// lib/core/network/api_response.dart

/// Every response is `{ status, message, data }`. This pulls `.data` out of
/// a decoded response body without generic-type ceremony at each call site.
extension ApiEnvelope on Map<String, dynamic> {
  Map<String, dynamic> get dataMap =>
      (this['data'] as Map?)?.cast<String, dynamic>() ?? {};

  List<dynamic> get dataList => (this['data'] as List?) ?? const [];
}
