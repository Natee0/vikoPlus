import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<RegisterResult> register({
    required String fullName,
    String? phone,
    String? email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'password': password,
        'preferredLocale': 'en',
      },
      options: Options(extra: {'skipAuth': true}),
    );

    return RegisterResult.fromJson(response.data ?? {});
  }

  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );

    return AuthTokens.fromJson(response.data ?? {});
  }

  Future<void> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'challengeId': challengeId, 'code': code},
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );

    return AuthTokens.fromJson(response.data ?? {});
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/auth/logout');
  }

  Future<AuthUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(response.data ?? {});
  }
}

class RegisterResult {
  const RegisterResult({
    required this.user,
    required this.challengeId,
    required this.destination,
    required this.channel,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    final challenge = json['otpChallenge'] as Map<String, dynamic>? ?? {};
    return RegisterResult(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      challengeId: challenge['id'] as String? ?? '',
      destination: challenge['destination'] as String? ?? '',
      channel: challenge['channel'] as String? ?? 'sms',
    );
  }

  final AuthUser user;
  final String challengeId;
  final String destination;
  final String channel;
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}
