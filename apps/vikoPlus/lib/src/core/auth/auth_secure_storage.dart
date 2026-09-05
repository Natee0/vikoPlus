import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

final authSecureStorageProvider = Provider<AuthSecureStorage>((ref) {
  return const AuthSecureStorage();
});

class AuthSecureStorage {
  const AuthSecureStorage();

  static const _accessTokenKey = 'vikoplus.accessToken';
  static const _refreshTokenKey = 'vikoplus.refreshToken';
  static const _userKey = 'vikoplus.user';
  static const _rememberedIdentifierKey = 'vikoplus.rememberedIdentifier';
  static const _rememberedPasswordKey = 'vikoplus.rememberedPassword';
  static final _storage = FlutterSecureStorage();

  Future<AuthSession> readSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userJson = await _storage.read(key: _userKey);

    if (accessToken == null || refreshToken == null || userJson == null) {
      return const AuthSession.empty();
    }

    try {
      final decodedUser = jsonDecode(userJson);
      if (decodedUser is! Map<String, dynamic>) {
        return const AuthSession.empty();
      }

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(decodedUser),
      );
    } catch (_) {
      await clearSession();
      return const AuthSession.empty();
    }
  }

  Future<void> saveSession(AuthSession session) async {
    final accessToken = session.accessToken;
    final refreshToken = session.refreshToken;
    final user = session.user;

    if (accessToken == null || refreshToken == null || user == null) {
      await clearSession();
      return;
    }

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  Future<RememberedLoginCredentials?> readRememberedLogin() async {
    final identifier = await _storage.read(key: _rememberedIdentifierKey);
    final password = await _storage.read(key: _rememberedPasswordKey);

    if (identifier == null ||
        identifier.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return RememberedLoginCredentials(
      identifier: identifier,
      password: password,
    );
  }

  Future<void> saveRememberedLogin({
    required String identifier,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(
        key: _rememberedIdentifierKey,
        value: identifier.trim(),
      ),
      _storage.write(key: _rememberedPasswordKey, value: password),
    ]);
  }

  Future<void> clearRememberedLogin() async {
    await Future.wait([
      _storage.delete(key: _rememberedIdentifierKey),
      _storage.delete(key: _rememberedPasswordKey),
    ]);
  }
}

class RememberedLoginCredentials {
  const RememberedLoginCredentials({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;
}
