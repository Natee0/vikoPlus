import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';
import 'shared/password_reset_flow.dart';
import 'shared/password_reset_widgets.dart';

class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;

  bool get _hasUpperAndLower {
    final value = _passwordController.text;
    return RegExp('[A-Z]').hasMatch(value) && RegExp('[a-z]').hasMatch(value);
  }

  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);

  bool get _hasSymbol {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];]').hasMatch(
      _passwordController.text,
    );
  }

  bool get _passwordsMatch {
    return _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmController.text;
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() => _errorMessage = '');
      return;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final flow = ref.read(passwordResetFlowProvider);
    if (flow.resetToken.isEmpty) {
      setState(() => _errorMessage = 'Reset session expired. Start again.');
      return;
    }
    if (!_hasMinLength || !_hasUpperAndLower || !_hasNumber || !_hasSymbol) {
      setState(() => _errorMessage = 'Password does not meet requirements.');
      return;
    }
    if (!_passwordsMatch) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      await ref.read(authRepositoryProvider).completePasswordReset(
            resetToken: flow.resetToken,
            password: _passwordController.text,
          );
      ref.read(passwordResetFlowProvider.notifier).clear();
      if (!mounted) return;
      context.go('/forgot-password/success');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PasswordResetScaffold(
      title: 'Reset Password',
      onBack: () => context.go('/forgot-password/verify'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ResetHeroIcon(
            icon: Icons.lock_reset_outlined,
            badgeIcon: Icons.verified_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Create New Password',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your new password must be unique and satisfy the security requirements below.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: 'New Password',
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (_) => _clearError(),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  label: 'Confirm New Password',
                  hint: 'Confirm password',
                  icon: Icons.lock_outline,
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (_) => _clearError(),
                  onSubmitted: (_) {
                    if (!_isSubmitting) _submit();
                  },
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirm
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.base),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RequirementRow(
                        passed: _hasMinLength,
                        text: 'At least 8 characters',
                      ),
                      RequirementRow(
                        passed: _hasUpperAndLower,
                        text: 'Uppercase and lowercase letters',
                      ),
                      RequirementRow(
                        passed: _hasNumber,
                        text: 'At least one number',
                      ),
                      RequirementRow(
                        passed: _hasSymbol,
                        text: 'A special symbol',
                      ),
                      RequirementRow(
                        passed: _passwordsMatch,
                        text: 'Passwords match',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthErrorMessage(message: _errorMessage),
                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(_isSubmitting ? 'Updating' : 'Update Password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
