import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_design_widgets.dart';
import 'auth_widgets.dart';

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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  String _errorMessage = '';
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
      setState(() => _errorMessage = 'Enter your phone number or email.');
      return;
    }

    try {
      setState(() {
        _errorMessage = '';
        _isSubmitting = true;
      });
      final result = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(identifier: identifier);
      ref.read(passwordResetFlowProvider.notifier).setRequested(
        identifier: identifier,
        destination: result.destination.isEmpty ? identifier : result.destination,
      );
      if (!mounted) return;
      context.push('/forgot-password/verify');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthFailure.from(error).message);
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
    return _ResetScaffold(
      title: 'Forgot Password',
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ResetHeroIcon(
            icon: Icons.lock_reset_outlined,
            badgeIcon: Icons.shield_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Enter your registered details and we'll send a secure one-time verification code.",
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
                  label: 'Phone number or email',
                  hint: '+255 712 345 678',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _identifierController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearError(),
                  onSubmitted: (_) {
                    if (!_isSubmitting) _submit();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _TrustNote(
                  icon: Icons.groups_2_outlined,
                  title: '',
                  body: 'Group contributions and account access remain secure.',
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
                  label: Text(_isSubmitting ? 'Sending' : 'Send Reset Code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthTextLink(
            text: 'Remember password? ',
            action: 'Sign in',
            onPressed: () => context.go('/sign-in'),
          ),
        ],
      ),
    );
  }
}

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
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isComplete {
    return _controllers.every((controller) => controller.text.length == 1);
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _clearError() {
    if (_errorMessage.isEmpty) return;
    setState(() => _errorMessage = '');
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
    if (_isSubmitting) return;

    final flow = ref.read(passwordResetFlowProvider);
    if (flow.identifier.isEmpty) {
      setState(() => _errorMessage = 'Reset session expired. Start again.');
      return;
    }
    if (!_isComplete) {
      setState(() => _errorMessage = 'Enter the full verification code.');
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
      setState(() => _errorMessage = AuthFailure.from(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(passwordResetFlowProvider);
    final destination = flow.destination.isEmpty
        ? 'your phone or email'
        : flow.destination;

    return _ResetScaffold(
      title: 'Verification',
      onBack: () => context.go('/forgot-password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ResetHeroIcon(
            icon: Icons.verified_user_outlined,
            badgeIcon: Icons.lock_clock_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Enter Security Code',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We sent a 6-digit verification code to $destination.',
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  onPressed: _isSubmitting
                      ? null
                      : () => context.go('/forgot-password'),
                  child: const Text('Resend or change destination'),
                ),
                AuthErrorMessage(message: _errorMessage),
                if (_errorMessage.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _isSubmitting || !_isComplete ? null : _verify,
                  iconAlignment: IconAlignment.end,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isSubmitting ? 'Verifying' : 'Verify & Proceed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TrustNote(
            icon: Icons.shield_outlined,
            title: 'Vikoplus Mutual Trust Guarantee',
            body: 'Your account credentials remain end-to-end protected.',
          ),
        ],
      ),
    );
  }
}

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
    return _ResetScaffold(
      title: 'Reset Password',
      onBack: () => context.go('/forgot-password/verify'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ResetHeroIcon(
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
                      _RequirementRow(
                        passed: _hasMinLength,
                        text: 'At least 8 characters',
                      ),
                      _RequirementRow(
                        passed: _hasUpperAndLower,
                        text: 'Uppercase and lowercase letters',
                      ),
                      _RequirementRow(
                        passed: _hasNumber,
                        text: 'At least one number',
                      ),
                      _RequirementRow(
                        passed: _hasSymbol,
                        text: 'A special symbol',
                      ),
                      _RequirementRow(
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            '256-bit Bank Grade Security Protection',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ResetScaffold(
      title: 'Login',
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ResetHeroIcon(
            icon: Icons.verified_outlined,
            badgeIcon: Icons.lock_outlined,
            size: 92,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Password Changed!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your password has been reset successfully. You can now sign in with your new credentials.',
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
                _TrustNote(
                  icon: Icons.fact_check_outlined,
                  title: 'Security Audit',
                  body: 'Password reset verified and active sessions ended.',
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => context.go('/sign-in'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetScaffold extends StatelessWidget {
  const _ResetScaffold({
    required this.title,
    required this.child,
    required this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: VikoplusConstrainedContent(
            child: Column(
              children: [
                VikoplusTopBar(
                  title: title,
                  onBack: onBack,
                  trailing: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.onPrimary,
                      size: 18,
                    ),
                  ),
                  showBorder: false,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenMobile,
                      AppSpacing.sm,
                      AppSpacing.screenMobile,
                      AppSpacing.md,
                    ),
                    children: [child],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetHeroIcon extends StatelessWidget {
  const _ResetHeroIcon({
    required this.icon,
    required this.badgeIcon,
    this.size = 72,
  });

  final IconData icon;
  final IconData badgeIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed.withValues(alpha: 0.65),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: size * 0.44),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.tertiaryFixed,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Icon(
                badgeIcon,
                color: AppColors.primary,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.base),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondaryFixed,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.passed, required this.text});

  final bool passed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? AppColors.primary : AppColors.outline,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        passed ? AppColors.primaryText : AppColors.secondaryText,
                    fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
