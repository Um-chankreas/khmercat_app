// lib/core/network/api_client.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:khmer_cat_app/core/utils/app_log.dart';

import '../service/storage_service.dart';
import 'api_exception.dart';
import 'api_route.dart';

/// Thin wrapper around dio that:
///  - attaches `Authorization: Bearer <token>` to every request when one is
///    stored (guest requests simply go out with no header).
///  - on a 401, calls POST /auth/refresh-token using the *current* token
///    (this API refreshes in place — there's no separate long-lived refresh
///    token) and retries the original request once with the new token.
///  - if refresh also fails, clears the stored session and notifies
///    [onSessionExpired] so the app can drop back to guest/login state.
///  - converts every non-2xx response into an [ApiException] carrying the
///    server's `.message` / `.errors` / (for login) `requires_verify`.
class ApiClient {
  final Dio dio;
  final StorageService _storage;
  final String _baseUrl;
  final void Function()? onSessionExpired;

  ApiClient({
    required String baseUrl,
    required this._storage,
    this.onSessionExpired,
  }) : _baseUrl = baseUrl,
       dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 40),
           headers: {'Accept': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLog.info('request => === ${options.uri} ${options.data ?? ""}');
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !alreadyRetried) {
            final refreshedToken = await _tryRefreshToken();
            if (refreshedToken != null) {
              try {
                final retryOptions = error.requestOptions
                  ..extra['retried'] = true
                  ..headers['Authorization'] = 'Bearer $refreshedToken';
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // retry failed too — fall through to session-expired below
              }
            }
            await _storage.clearSession();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _tryRefreshToken() async {
    final currentToken = _storage.getToken();
    if (currentToken == null) return null;

    try {
      // A bare Dio instance — deliberately bypasses our interceptors so a
      // failed refresh can't recursively trigger another refresh attempt.
      final response = await Dio(BaseOptions(baseUrl: _baseUrl)).post(
        ApiRoute.refreshToken,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
        ),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      // AuthController::refreshToken() returns `access_token`, not `token`.
      final newToken = (data is Map ? data['access_token'] : null) as String?;
      if (newToken == null) return null;
      await _storage.saveToken(newToken);
      return newToken;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _unwrap(() => dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) {
    return _unwrap(() => dio.post(path, data: body));
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) {
    return _unwrap(() => dio.put(path, data: body));
  }

  Future<Map<String, dynamic>> delete(String path, {Object? body}) {
    return _unwrap(() => dio.delete(path, data: body));
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
  }) {
    return uploadMultipart(
      path,
      files: {fieldName: file},
      fields: fields,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required Map<String, File> files,
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
  }) {
    return _unwrap(() async {
      final formData = FormData.fromMap({
        ...?fields,
        for (final entry in files.entries)
          entry.key: await MultipartFile.fromFile(entry.value.path),
      });
      return dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        options: Options(sendTimeout: const Duration(minutes: 5)),
      );
    });
  }

  Future<Map<String, dynamic>> _unwrap(
    Future<Response> Function() request,
  ) async {
    late Response response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw _toApiException(e);
    } on SocketException {
      throw ApiException(message: 'No internet connection.');
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    // A 2xx with a body that isn't a JSON object usually means something sat
    // in front of the actual JSON (a stray PHP notice/warning printed before
    // it, a truncated body, etc.) — log the raw body instead of silently
    // discarding it so a "response was missing expected data" report upstream
    // is actually diagnosable.
    AppLog.info(
      'Non-JSON-object response body (status ${response.statusCode}): '
      '${data.runtimeType} ${data.toString().substring(0, data.toString().length.clamp(0, 500))}',
    );
    return {};
  }

  ApiException _toApiException(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(message: 'No internet connection.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(message: 'The request timed out. Please try again.');
    }

    final statusCode = e.response?.statusCode;
    final rawData = e.response?.data;

    // Rate limited (Laravel's throttle): say how long to wait instead of the
    // bare "Too Many Attempts." — the server sends the seconds left.
    if (statusCode == 429) {
      final seconds = int.tryParse(
        e.response?.headers.value('retry-after') ?? '',
      );
      final wait = seconds == null
          ? 'a minute'
          : seconds >= 90
          ? '${(seconds / 60).ceil()} minutes'
          : '$seconds seconds';
      return ApiException(
        message: 'Too many attempts. Please wait $wait and try again.',
        statusCode: statusCode,
      );
    }

    Map<String, dynamic>? json;
    if (rawData is Map<String, dynamic>) {
      json = rawData;
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        json = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        // leave json null — unexpected non-JSON server response
      }
    }

    if (json == null) {
      return ApiException(
        message: 'Something went wrong. Please try again.',
        statusCode: statusCode,
      );
    }

    // requires_verify / user_id ride inside `meta` — only ApiResponse::error()
    // (not the 422 validationError() path) ever sets it, e.g. login()'s
    // "email not verified" 403.
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>();

    return ApiException(
      message: json['message'] as String? ?? 'An error occurred',
      statusCode: statusCode,
      errors: (json['errors'] as Map?)?.cast<String, dynamic>(),
      requiresVerification: meta?['requires_verify'] == true,
      unverifiedUserId: meta?['user_id']?.toString(),
    );
  }
}
