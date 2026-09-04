import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _fullNameController = TextEditingController();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _useEmail = false;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _identityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) return;

    final fullName = _fullNameController.text.trim();
    final identity = _identityController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || identity.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Complete all required fields.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _errorMessage = 'Accept the terms before creating an account.',
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final challengeId = await ref
          .read(authControllerProvider.notifier)
          .register(
            fullName: fullName,
            email: _useEmail ? identity : null,
            phone: _useEmail ? null : identity,
            password: password,
          );
      if (!mounted) return;
      final query = Uri(queryParameters: {
        'challengeId': challengeId,
        'destination': identity,
        'channel': _useEmail ? 'email' : 'sms',
        'next': '/create-or-join-group',
        'back': '/create-account',
      }).query;
      context.push('/verify-account?$query');
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearError() {
    if (_errorMessage.isEmpty) return;
    setState(() => _errorMessage = '');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authControllerProvider).isLoading || _isSubmitting;

    return AuthScaffold(
      child: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join the modern financial community.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              label: 'Full Name',
              hint: 'John Doe',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearError(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _useEmail ? 'Email Address' : 'Phone Number',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useEmail = !_useEmail;
                      _identityController.clear();
                      _errorMessage = '';
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _useEmail ? 'Use Phone Instead' : 'Use Email Instead',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: AppSizes.inputHeight,
              child: TextField(
                controller: _identityController,
                keyboardType: _useEmail
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearError(),
                decoration: InputDecoration(
                  hintText: _useEmail ? 'you@example.com' : '+255 785 546 336',
                  prefixIcon: Icon(
                    _useEmail ? Icons.email_outlined : Icons.phone_outlined,
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _useEmail
                  ? "We'll send a secure verification code to this email."
                  : "We'll use this for secure verification.",
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthField(
              label: 'Password',
              hint: 'Password',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearError(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              helperText: 'Must be at least 8 characters long.',
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthField(
              label: 'Confirm Password',
              hint: 'Password',
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearError(),
              onSubmitted: (_) {
                if (!isLoading) _createAccount();
              },
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                        _errorMessage = '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AuthErrorMessage(message: _errorMessage),
            if (_errorMessage.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: isLoading ? null : _createAccount,
              iconAlignment: IconAlignment.end,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(isLoading ? 'Creating account' : 'Create account'),
            ),
            const SizedBox(height: 12),
            AuthTextLink(
              text: 'Already have an account? ',
              action: 'Log in',
              onPressed: () => context.push('/sign-in'),
            ),
          ],
        ),
      ),
    );
  }
}
