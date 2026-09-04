import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_secure_storage.dart';
import 'auth_session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    final storedSession =
        await ref.read(authSecureStorageProvider).readSession();
    if (storedSession.isAuthenticated) {
      ref.read(authSessionProvider.notifier).restore(storedSession);
    }
    return ref.read(authSessionProvider);
  }

  Future<String> register({
    required String fullName,
    String? phone,
    String? email,
    required String password,
  }) async {
    state = const AsyncLoading();
    return _guard(() async {
      final identifier = email ?? phone ?? '';
      final result = await ref.read(authRepositoryProvider).register(
            fullName: fullName,
            phone: phone,
            email: email,
            password: password,
          );
      final pendingVerification = PendingVerification(
        challengeId: result.challengeId,
        destination: result.destination,
        channel: result.channel,
        identifier: identifier,
        password: password,
      );
      ref
          .read(authSessionProvider.notifier)
          .setPendingVerification(pendingVerification);
      state = AsyncData(ref.read(authSessionProvider));
      return result.challengeId;
    });
  }

  Future<String> login({
    required String identifier,
    required String password,
    String? previewRoute,
  }) async {
    state = const AsyncLoading();
    return _guard(() async {
      final tokens = await ref
          .read(authRepositoryProvider)
          .login(identifier: identifier, password: password);
      ref.read(authSessionProvider.notifier).setAuthenticated(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            user: tokens.user,
          );
      final session = ref.read(authSessionProvider);
      await ref.read(authSecureStorageProvider).saveSession(session);
      state = AsyncData(session);
      return routeForRole(tokens.user.selectedRole, fallback: previewRoute);
    });
  }

  Future<String> verifyPendingOtp(String code) async {
    state = const AsyncLoading();
    return _guard(() async {
      final pending = ref.read(authSessionProvider).pendingVerification;
      if (pending == null) {
        throw const AuthFailure('Verification session expired. Sign in again.');
      }

      await ref.read(authRepositoryProvider).verifyOtp(
            challengeId: pending.challengeId,
            code: code,
          );
      return login(
        identifier: pending.identifier,
        password: pending.password,
        previewRoute: '/create-or-join-group',
      );
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _guard(() async {
      final refreshToken = ref.read(authSessionProvider).refreshToken;
      if (refreshToken == null) {
        throw const AuthFailure('Session expired. Sign in again.');
      }
      final tokens = await ref.read(authRepositoryProvider).refresh(refreshToken);
      ref.read(authSessionProvider.notifier).setAuthenticated(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            user: tokens.user,
          );
      final session = ref.read(authSessionProvider);
      await ref.read(authSecureStorageProvider).saveSession(session);
      state = AsyncData(session);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      final accessToken = ref.read(authSessionProvider).accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        await ref.read(authRepositoryProvider).logout();
      }
    } catch (_) {
      // Local logout should still succeed if the server token is expired,
      // the API is unreachable, or the remote session was already revoked.
    } finally {
      ref.read(authSessionProvider.notifier).clear();
      await ref.read(authSecureStorageProvider).clearSession();
      state = const AsyncData(AuthSession.empty());
    }
  }

  String routeForRole(String? role, {String? fallback}) {
    switch (role) {
      case 'GROUP_ADMIN':
      case 'TREASURER':
      case 'SECRETARY':
      case 'MEMBER':
        return '/groups';
      case 'NEW_USER':
        return '/create-or-join-group';
      default:
        return fallback ?? '/create-or-join-group';
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      final failure = AuthFailure.from(error);
      state = AsyncError(failure, stackTrace);
      throw failure;
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  factory AuthFailure.from(Object error) {
    if (error is AuthFailure) return error;
    final errorText = error.toString();
    if (errorText.contains('API connection is not configured')) {
      return const AuthFailure(
        'API connection is not configured.',
      );
    }
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = _messageFromMap(data);
        if (message != null) return AuthFailure(message);
      }
      if (data is String && data.trim().isNotEmpty) {
        return AuthFailure(data.trim());
      }
      return AuthFailure(error.message ?? 'Network request failed.');
    }
    if (error is StateError) return AuthFailure(error.message);
    if (error is FormatException) return AuthFailure(error.message);
    return AuthFailure(errorText);
  }

  final String message;

  @override
  String toString() => message;

  static String? _messageFromMap(Map<String, dynamic> data) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List && message.isNotEmpty) {
      return message.map((item) => item.toString()).join('\n');
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      return _messageFromMap(nestedData);
    }

    return null;
  }
}
