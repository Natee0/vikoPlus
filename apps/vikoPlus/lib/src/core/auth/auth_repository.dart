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
        'phone': phone,
        'email': email,
        'password': password,
        'preferredLocale': 'en',
      },
      options: Options(extra: {'skipAuth': true}),
    );

    return RegisterResult.fromJson(_responseBody(response.data));
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

    return AuthTokens.fromJson(_responseBody(response.data));
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

  Future<PasswordResetRequestResult> requestPasswordReset({
    required String identifier,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/password-reset/request',
      data: {'identifier': identifier},
      options: Options(extra: {'skipAuth': true}),
    );

    return PasswordResetRequestResult.fromJson(_responseBody(response.data));
  }

  Future<PasswordResetVerificationResult> verifyPasswordResetCode({
    required String identifier,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/password-reset/verify',
      data: {'identifier': identifier, 'code': code},
      options: Options(extra: {'skipAuth': true}),
    );

    return PasswordResetVerificationResult.fromJson(
      _responseBody(response.data),
    );
  }

  Future<void> completePasswordReset({
    required String resetToken,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/password-reset/complete',
      data: {
        'resetToken': resetToken,
        'password': password,
        'logoutOtherSessions': true,
      },
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );

    return AuthTokens.fromJson(_responseBody(response.data));
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/auth/logout');
  }

  Future<AuthUser> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(_responseBody(response.data));
  }

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
    final challengeId = challenge['id'];
    if (challengeId is! String || challengeId.isEmpty) {
      throw const FormatException(
        'Registration response did not include a verification challenge.',
      );
    }

    return RegisterResult(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      challengeId: challengeId,
      destination: challenge['destination'] as String? ?? '',
      channel: challenge['channel'] as String? ?? 'sms',
    );
  }

  final AuthUser user;
  final String challengeId;
  final String destination;
  final String channel;
}

class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.status,
    required this.destination,
    required this.expiresInSeconds,
  });

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResult(
      status: json['status'] as String? ?? 'RESET_CODE_SENT_IF_ACCOUNT_EXISTS',
      destination: json['destination'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 600,
    );
  }

  final String status;
  final String destination;
  final int expiresInSeconds;
}

class PasswordResetVerificationResult {
  const PasswordResetVerificationResult({
    required this.resetToken,
    required this.expiresAt,
  });

  factory PasswordResetVerificationResult.fromJson(Map<String, dynamic> json) {
    final resetToken = json['resetToken'];
    if (resetToken is! String || resetToken.isEmpty) {
      throw const FormatException(
        'Password reset response did not include a reset token.',
      );
    }

    return PasswordResetVerificationResult(
      resetToken: resetToken,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }

  final String resetToken;
  final DateTime? expiresAt;
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final user = json['user'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException(
        'Login response did not include an access token.',
      );
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const FormatException(
        'Login response did not include a refresh token.',
      );
    }
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Login response did not include user data.');
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(user),
    );
  }

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}
