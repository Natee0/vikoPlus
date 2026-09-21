import 'package:flutter_riverpod/flutter_riverpod.dart';

final passwordResetFlowProvider =
    NotifierProvider<PasswordResetFlowNotifier, PasswordResetFlow>(
      PasswordResetFlowNotifier.new,
    );

class PasswordResetFlow {
  const PasswordResetFlow({
    this.identifier = '',
    this.destination = '',
    this.channel = 'sms',
    this.resetToken = '',
    this.expiresInSeconds = 600,
    this.requestedAt,
  });

  final String identifier;
  final String destination;
  final String channel;
  final String resetToken;
  final int expiresInSeconds;
  final DateTime? requestedAt;

  DateTime? get codeExpiresAt {
    final start = requestedAt;
    if (start == null) return null;
    return start.add(Duration(seconds: expiresInSeconds));
  }

  PasswordResetFlow copyWith({
    String? identifier,
    String? destination,
    String? channel,
    String? resetToken,
    int? expiresInSeconds,
    DateTime? requestedAt,
  }) {
    return PasswordResetFlow(
      identifier: identifier ?? this.identifier,
      destination: destination ?? this.destination,
      channel: channel ?? this.channel,
      resetToken: resetToken ?? this.resetToken,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }
}

class PasswordResetFlowNotifier extends Notifier<PasswordResetFlow> {
  @override
  PasswordResetFlow build() => const PasswordResetFlow();

  void setRequested({
    required String identifier,
    required String destination,
    required String channel,
    required int expiresInSeconds,
  }) {
    state = PasswordResetFlow(
      identifier: identifier,
      destination: destination,
      channel: channel,
      expiresInSeconds: expiresInSeconds,
      requestedAt: DateTime.now(),
    );
  }

  void setResetToken(String resetToken) {
    state = state.copyWith(resetToken: resetToken);
  }

  void clear() {
    state = const PasswordResetFlow();
  }
}
