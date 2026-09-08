import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/vikoplus_translations.dart';
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
    if (_isSubmitting || !_acceptedTerms) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final identity = _identityController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || identity.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Complete all required fields.'),
      );
      return;
    }
    if (password.length < 8) {
      setState(
        () => _errorMessage = context.vt(
          'Password must be at least 8 characters.',
        ),
      );
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = context.vt('Passwords do not match.'));
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _errorMessage = context.vt(
          'Accept the terms before creating an account.',
        ),
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
      if (!mounted) {
        return;
      }
      final query = Uri(
        queryParameters: {
          'challengeId': challengeId,
          'destination': identity,
          'channel': _useEmail ? 'email' : 'sms',
          'next': '/create-or-join-group',
          'back': '/create-account',
        },
      ).query;
      context.push('/verify-account?$query');
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = context.vt(error.message));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearError() {
    if (_errorMessage.isEmpty) {
      return;
    }
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
              AppLocalizations.of(context).createAccount,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).communityJoin,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              label: AppLocalizations.of(context).fullName,
              hint: context.vt('John Doe'),
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
                    _useEmail
                        ? AppLocalizations.of(context).emailAddress
                        : AppLocalizations.of(context).phoneNumber,
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
                    _useEmail
                        ? AppLocalizations.of(context).usePhone
                        : AppLocalizations.of(context).useEmail,
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
                  ? AppLocalizations.of(context).emailVerifyNote
                  : AppLocalizations.of(context).verifyNote,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthField(
              label: AppLocalizations.of(context).password,
              hint: AppLocalizations.of(context).password,
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearError(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? AppLocalizations.of(context).showPassword
                    : AppLocalizations.of(context).hidePassword,
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              helperText: AppLocalizations.of(context).passwordLength,
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthField(
              label: AppLocalizations.of(context).confirmPassword,
              hint: AppLocalizations.of(context).password,
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearError(),
              onSubmitted: (_) {
                if (!isLoading && _acceptedTerms) {
                  _createAccount();
                }
              },
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? AppLocalizations.of(context).showPassword
                    : AppLocalizations.of(context).hidePassword,
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
                      text: AppLocalizations.of(context).agreeTerms,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context).terms,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: AppLocalizations.of(context).andWord),
                        TextSpan(
                          text: AppLocalizations.of(context).privacy,
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
            if (_errorMessage.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: isLoading || !_acceptedTerms ? null : _createAccount,
              iconAlignment: IconAlignment.end,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(
                isLoading
                    ? context.vt('Creating account')
                    : context.vt('Create account'),
              ),
            ),
            const SizedBox(height: 12),
            AuthTextLink(
              text: context.vt('Already have an account? '),
              action: context.vt('Log in'),
              onPressed: () => context.push('/sign-in'),
            ),
          ],
        ),
      ),
    );
  }
}
