import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  String _errorMessage = '';
  String _deliveryChannel = 'sms';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Enter your phone number or email.'),
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
          .requestPasswordReset(
            identifier: identifier,
            deliveryChannel: _isPhoneIdentifier(identifier)
                ? _deliveryChannel
                : null,
          );
      ref
          .read(passwordResetFlowProvider.notifier)
          .setRequested(
            identifier: identifier,
            destination: result.destination.isEmpty
                ? identifier
                : result.destination,
            channel: result.channel,
            expiresInSeconds: result.expiresInSeconds,
          );
      if (!mounted) return;
      context.push('/forgot-password/verify');
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

  bool _isPhoneIdentifier(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && !trimmed.contains('@');
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneIdentifier = _isPhoneIdentifier(_identifierController.text);
    return PasswordResetScaffold(
      title: context.vt('Forgot Password'),
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ResetHeroIcon(
            icon: Icons.lock_reset_outlined,
            badgeIcon: Icons.shield_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Forgot Password?'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vt(
              "Enter your registered details and we'll send a secure one-time verification code.",
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: context.vt('Phone number or email'),
                  hint: '+255 712 345 678',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _identifierController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    setState(() => _errorMessage = '');
                  },
                  onSubmitted: (_) {
                    if (!_isSubmitting) _submit();
                  },
                ),
                if (isPhoneIdentifier) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OtpDeliveryChannelSelector(
                    value: _deliveryChannel,
                    onChanged: (value) {
                      setState(() {
                        _deliveryChannel = value;
                        _errorMessage = '';
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _deliveryChannel == 'whatsapp'
                        ? context.vt(
                            'We will send the reset code through WhatsApp.',
                          )
                        : context.vt('We will send the reset code by SMS.'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TrustNote(
                  icon: Icons.groups_2_outlined,
                  title: '',
                  body: context.vt(
                    'Group contributions and account access remain secure.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthErrorMessage(message: _errorMessage),
                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
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
                        ? context.vt('Sending')
                        : context.vt('Send Reset Code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthTextLink(
            text: context.vt('Remember password? '),
            action: context.vt('Sign in'),
            onPressed: () => context.go('/sign-in'),
          ),
        ],
      ),
    );
  }
}
