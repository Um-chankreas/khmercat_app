// lib/core/network/api_exception.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  /// Only ever set on a 403 from POST /auth/login, per the API's
  /// "unverified email" path: { requires_verify: true, user_id }.
  final bool requiresVerification;
  final String? unverifiedUserId;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.requiresVerification = false,
    this.unverifiedUserId,
  });

  bool get isValidationError => errors != null && errors!.isNotEmpty;

  String? fieldError(String field) {
    final list = errors?[field];
    if (list is List && list.isNotEmpty) return list.first.toString();
    return null;
  }

  String get allErrorsMessage {
    if (errors == null || errors!.isEmpty) return message;
    return errors!.values.expand((v) => v is List ? v : [v]).join('\n');
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
