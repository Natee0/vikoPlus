import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_secure_storage.dart';
import '../../core/auth/auth_session.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _needsVerification = false;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedLogin() async {
    final credentials = await ref
        .read(authSecureStorageProvider)
        .readRememberedLogin();
    if (!mounted || credentials == null) {
      return;
    }

    setState(() {
      _identifierController.text = credentials.identifier;
      _passwordController.text = credentials.password;
      _rememberMe = true;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = context.vt('Enter your phone/email and password.'),
      );
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final route = await ref
          .read(authControllerProvider.notifier)
          .login(identifier: identifier, password: password);
      final storage = ref.read(authSecureStorageProvider);
      if (_rememberMe) {
        await storage.saveRememberedLogin(
          identifier: identifier,
          password: password,
        );
      } else {
        await storage.clearRememberedLogin();
      }
      if (!mounted) {
        return;
      }
      context.go(route);
    } on AuthVerificationRequired catch (error) {
      final storage = ref.read(authSecureStorageProvider);
      if (_rememberMe) {
        await storage.saveRememberedLogin(
          identifier: identifier,
          password: password,
        );
      } else {
        await storage.clearRememberedLogin();
      }
      if (!mounted) {
        return;
      }
      ref.read(authSessionProvider.notifier).setPendingVerification(
            PendingVerification(
              challengeId: error.challengeId,
              destination: error.destination,
              channel: error.channel,
              identifier: identifier,
              password: password,
              expiresAt: error.expiresAt,
            ),
          );
      setState(() {
        _needsVerification = true;
        _errorMessage = context.vt(
          'Your account needs verification. Tap Verify account to continue.',
        );
      });
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _needsVerification = false;
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearError() {
    if (_errorMessage.isEmpty && !_needsVerification) {
      return;
    }
    setState(() {
      _errorMessage = '';
      _needsVerification = false;
    });
  }

  void _openVerification() {
    final pending = ref.read(authSessionProvider).pendingVerification;
    if (pending == null) {
      setState(() {
        _needsVerification = false;
        _errorMessage = context.vt(
          'Verification session expired. Sign in again.',
        );
      });
      return;
    }

    final query = Uri(
      queryParameters: {
        'challengeId': pending.challengeId,
        'destination': pending.destination,
        'channel': pending.channel,
        'next': '/groups',
        'back': '/sign-in',
      },
    ).query;
    context.push('/verify-account?$query');
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    if (!value) {
      await ref.read(authSecureStorageProvider).clearRememberedLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authControllerProvider).isLoading || _isSubmitting;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo/vikoPlus-logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vikoplus',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).signInTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: AppLocalizations.of(context).identifierLabel,
                  hint: AppLocalizations.of(context).identifierHint,
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  controller: _identifierController,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthField(
                  label: AppLocalizations.of(context).password,
                  hint: AppLocalizations.of(context).password,
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearError(),
                  onSubmitted: (_) {
                    if (!isLoading) _submit();
                  },
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
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthErrorMessage(message: _errorMessage),
                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          _setRememberMe(value ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).rememberMe,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push('/forgot-password'),
                      child: Text(
                        AppLocalizations.of(context).forgotPasswordLink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : _needsVerification
                      ? _openVerification
                      : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _needsVerification
                              ? context.vt('Verify account')
                              : AppLocalizations.of(context).signIn,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthTextLink(
            text: AppLocalizations.of(context).noAccount,
            action: AppLocalizations.of(context).createOne,
            onPressed: () => context.push('/create-account'),
          ),
        ],
      ),
    );
  }
}
