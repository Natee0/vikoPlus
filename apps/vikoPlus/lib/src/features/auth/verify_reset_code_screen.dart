import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';
import 'shared/password_reset_flow.dart';
import 'shared/password_reset_widgets.dart';

class VerifyResetCodeScreen extends ConsumerStatefulWidget {
  const VerifyResetCodeScreen({super.key});

  @override
  ConsumerState<VerifyResetCodeScreen> createState() =>
      _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends ConsumerState<VerifyResetCodeScreen> {
  static const _codeLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  String _errorMessage = '';
  String _successMessage = '';
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  bool get _isComplete {
    return _controllers.every((controller) => controller.text.length == 1);
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  Duration _remainingFor(PasswordResetFlow flow) {
    final expiresAt = flow.codeExpiresAt;
    if (expiresAt == null) return Duration(seconds: flow.expiresInSeconds);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _clearError() {
    if (_errorMessage.isEmpty && _successMessage.isEmpty) return;
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _handleCodeChanged(String value, int index) {
    _clearError();
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _controllers[index].clear();
      setState(() {});
      return;
    }

    if (digits.length > 1) {
      var writeIndex = index;
      for (final digit in digits.split('')) {
        if (writeIndex >= _codeLength) break;
        _setDigit(writeIndex, digit);
        writeIndex++;
      }
      if (_isComplete) {
        _focusNodes.last.unfocus();
      } else {
        _focusNodes[writeIndex.clamp(0, _codeLength - 1)].requestFocus();
      }
      setState(() {});
      return;
    }

    _setDigit(index, digits);
    if (index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  void _setDigit(int index, String digit) {
    _controllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int index) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        index == 0 ||
        _controllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }

    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].clear();
    setState(() {});
    return KeyEventResult.handled;
  }

  Future<void> _verify() async {
    if (_isSubmitting || _isResending) return;

    final flow = ref.read(passwordResetFlowProvider);
    if (flow.identifier.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Reset session expired. Start again.'),
      );
      return;
    }
    if (!_isComplete) {
      setState(
        () => _errorMessage = context.vt('Enter the full verification code.'),
      );
      return;
    }
    if (_remainingFor(flow) == Duration.zero) {
      setState(
        () => _errorMessage = context.vt(
          'Verification code expired. Request a new code.',
        ),
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final result = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetCode(identifier: flow.identifier, code: _code);
      ref
          .read(passwordResetFlowProvider.notifier)
          .setResetToken(result.resetToken);
      if (!mounted) return;
      context.push('/forgot-password/reset');
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(AuthFailure.from(error).message),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isSubmitting || _isResending) return;

    final flow = ref.read(passwordResetFlowProvider);
    if (flow.identifier.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Reset session expired. Start again.'),
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _successMessage = '';
        _isResending = true;
      });
      final result = await ref.read(authRepositoryProvider).requestPasswordReset(
            identifier: flow.identifier,
            deliveryChannel: flow.channel == 'whatsapp'
                ? 'whatsapp'
                : flow.channel == 'sms'
                ? 'sms'
                : null,
          );
      ref.read(passwordResetFlowProvider.notifier).setRequested(
            identifier: flow.identifier,
            destination: result.destination.isEmpty
                ? flow.destination
                : result.destination,
            channel: result.channel,
            expiresInSeconds: result.expiresInSeconds,
          );
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
      if (!mounted) return;
      setState(
        () => _successMessage = context.vt('A new verification code has been sent.'),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = context.vt(AuthFailure.from(error).message),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(passwordResetFlowProvider);
    final destination = flow.destination.isEmpty
        ? context.vt('your phone or email')
        : flow.destination;
    final channelLabel = flow.channel == 'whatsapp'
        ? 'WhatsApp'
        : flow.channel == 'email'
        ? context.vt('email')
        : context.vt('SMS');
    final remaining = _remainingFor(flow);
    final hasExpired = remaining == Duration.zero;

    return PasswordResetScaffold(
      title: context.vt('Verification'),
      onBack: () => context.go('/forgot-password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ResetHeroIcon(
            icon: Icons.verified_user_outlined,
            badgeIcon: Icons.lock_clock_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Enter Security Code'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vtf(
              'We sent a 6-digit verification code to {destination}.',
              {'destination': '$destination ($channelLabel)'},
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasExpired
                ? context.vt('Verification code expired. Request a new code.')
                : context.vtf('Code expires in {time}', {
                    'time': _formatRemaining(remaining),
                  }),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: hasExpired ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.center,
                  children: List.generate(_codeLength, (index) {
                    return Focus(
                      onKeyEvent: (node, event) =>
                          _handleKeyEvent(event, index),
                      child: SizedBox(
                        width: 42,
                        height: 48,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          autofocus: index == 0,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                          onChanged: (value) =>
                              _handleCodeChanged(value, index),
                          onTap: () {
                            _controllers[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _controllers[index].text.length,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _isSubmitting || _isResending
                      ? null
                      : _resendCode,
                  child: Text(
                    _isResending
                        ? context.vt('Sending')
                        : context.vt('Resend OTP'),
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting || _isResending
                      ? null
                      : () => context.go('/forgot-password'),
                  child: Text(context.vt('Resend or change destination')),
                ),
                if (_successMessage.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _successMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                AuthErrorMessage(message: _errorMessage),
                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _isSubmitting || !_isComplete || hasExpired
                      ? null
                      : _verify,
                  iconAlignment: IconAlignment.end,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _isSubmitting
                        ? context.vt('Verifying')
                        : context.vt('Verify & Proceed'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TrustNote(
            icon: Icons.shield_outlined,
            title: context.vt('Vikoplus Mutual Trust Guarantee'),
            body: context.vt(
              'Your account credentials remain end-to-end protected.',
            ),
          ),
        ],
      ),
    );
  }
}
