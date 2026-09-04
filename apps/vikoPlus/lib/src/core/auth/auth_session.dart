import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    this.displayName,
    this.preferredLocale = 'en',
    this.selectedRole = 'NEW_USER',
    this.isPlatformAdmin = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Login response did not include a user id.');
    }

    return AuthUser(
      id: id,
      displayName: json['displayName'] as String?,
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      selectedRole: json['selectedRole'] as String? ?? 'NEW_USER',
      isPlatformAdmin: json['isPlatformAdmin'] as bool? ?? false,
    );
  }

  final String id;
  final String? displayName;
  final String preferredLocale;
  final String selectedRole;
  final bool isPlatformAdmin;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'preferredLocale': preferredLocale,
      'selectedRole': selectedRole,
      'isPlatformAdmin': isPlatformAdmin,
    };
  }
}

class PendingVerification {
  const PendingVerification({
    required this.challengeId,
    required this.destination,
    required this.channel,
    required this.identifier,
    required this.password,
  });

  final String challengeId;
  final String destination;
  final String channel;
  final String identifier;
  final String password;
}

class AuthSession {
  const AuthSession({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.pendingVerification,
  });

  const AuthSession.empty()
    : accessToken = null,
      refreshToken = null,
      user = null,
      pendingVerification = null;

  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;
  final PendingVerification? pendingVerification;

  bool get isAuthenticated => accessToken != null && user != null;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    AuthUser? user,
    PendingVerification? pendingVerification,
    bool clearPendingVerification = false,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      pendingVerification: clearPendingVerification
          ? null
          : pendingVerification ?? this.pendingVerification,
    );
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => const AuthSession.empty();

  void setPendingVerification(PendingVerification pendingVerification) {
    state = AuthSession(pendingVerification: pendingVerification);
  }

  void setAuthenticated({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) {
    state = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  void restore(AuthSession session) {
    state = session;
  }

  void clear() {
    state = const AuthSession.empty();
  }
}
