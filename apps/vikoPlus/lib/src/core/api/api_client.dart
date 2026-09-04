import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_secure_storage.dart';
import '../auth/auth_session.dart';
import '../config/app_config.dart';

final apiClientProvider = Provider<Dio>((ref) {
  const configuredBaseUrl = AppConfig.VIKOPLUS_API_BASE_URL;
  final baseUrl = _normalizeApiBaseUrl(configuredBaseUrl);
  if (baseUrl == null) {
    throw StateError('API connection is not configured.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final skipAuth = options.extra['skipAuth'] == true;
        final accessToken = ref.read(authSessionProvider).accessToken;
        if (!skipAuth && accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;
        final shouldRefresh =
            error.response?.statusCode == 401 &&
            requestOptions.extra['skipAuth'] != true &&
            requestOptions.extra['authRetry'] != true;
        if (!shouldRefresh) {
          handler.next(error);
          return;
        }

        final refreshToken = ref.read(authSessionProvider).refreshToken;
        if (refreshToken == null || refreshToken.isEmpty) {
          ref.read(authSessionProvider.notifier).clear();
          handler.next(error);
          return;
        }

        try {
          final refreshDio = Dio(dio.options);
          final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(extra: {'skipAuth': true}),
          );
          final tokenBody = _responseBody(refreshResponse.data);
          final accessToken = tokenBody['accessToken'];
          final newRefreshToken = tokenBody['refreshToken'];
          final user = tokenBody['user'];
          if (accessToken is! String ||
              accessToken.isEmpty ||
              newRefreshToken is! String ||
              newRefreshToken.isEmpty ||
              user is! Map<String, dynamic>) {
            throw const FormatException('Session refresh response is invalid.');
          }

          ref
              .read(authSessionProvider.notifier)
              .setAuthenticated(
                accessToken: accessToken,
                refreshToken: newRefreshToken,
                user: AuthUser.fromJson(user),
              );
          await ref
              .read(authSecureStorageProvider)
              .saveSession(ref.read(authSessionProvider));

          requestOptions.extra['authRetry'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $accessToken';
          final retryResponse = await dio.fetch<dynamic>(requestOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          ref.read(authSessionProvider.notifier).clear();
          await ref.read(authSecureStorageProvider).clearSession();
          handler.next(error);
        }
      },
    ),
  );
  return dio;
});

Map<String, dynamic> _responseBody(Map<String, dynamic>? json) {
  if (json == null) {
    throw const FormatException('API returned an empty response.');
  }

  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }

  return json;
}

String? _normalizeApiBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final withoutTrailingSlash = trimmed.replaceFirst(RegExp(r'/+$'), '');
  if (withoutTrailingSlash.endsWith('/v1')) return withoutTrailingSlash;
  return '$withoutTrailingSlash/v1';
}
