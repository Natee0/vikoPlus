import 'package:flutter_riverpod/flutter_riverpod.dart';

final passwordResetFlowProvider =
    NotifierProvider<PasswordResetFlowNotifier, PasswordResetFlow>(
  PasswordResetFlowNotifier.new,
);

class PasswordResetFlow {
  const PasswordResetFlow({
    this.identifier = '',
    this.destination = '',
    this.resetToken = '',
  });

  final String identifier;
  final String destination;
  final String resetToken;

  PasswordResetFlow copyWith({
    String? identifier,
    String? destination,
    String? resetToken,
  }) {
    return PasswordResetFlow(
      identifier: identifier ?? this.identifier,
      destination: destination ?? this.destination,
      resetToken: resetToken ?? this.resetToken,
    );
  }
}

class PasswordResetFlowNotifier extends Notifier<PasswordResetFlow> {
  @override
  PasswordResetFlow build() => const PasswordResetFlow();

  void setRequested({
    required String identifier,
    required String destination,
  }) {
    state = PasswordResetFlow(
      identifier: identifier,
      destination: destination,
    );
  }

  void setResetToken(String resetToken) {
    state = state.copyWith(resetToken: resetToken);
  }

  void clear() {
    state = const PasswordResetFlow();
  }
}
