import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';

final apiClientProvider = Provider<Dio>((ref) {
  const baseUrl = String.fromEnvironment('VIKOPLUS_API_BASE_URL');
  if (baseUrl.isEmpty) {
    throw StateError(
      'VIKOPLUS_API_BASE_URL is required. '
      'Pass it with --dart-define=VIKOPLUS_API_BASE_URL=<backend-url>/v1',
    );
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
    ),
  );
  return dio;
});
