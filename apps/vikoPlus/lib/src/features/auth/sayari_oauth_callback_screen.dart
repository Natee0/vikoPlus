import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';

class SayariOAuthCallbackScreen extends ConsumerStatefulWidget {
  const SayariOAuthCallbackScreen({
    super.key,
    required this.callbackUri,
  });

  final Uri callbackUri;

  @override
  ConsumerState<SayariOAuthCallbackScreen> createState() =>
      _SayariOAuthCallbackScreenState();
}

class _SayariOAuthCallbackScreenState
    extends ConsumerState<SayariOAuthCallbackScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _completeSignIn());
  }

  Future<void> _completeSignIn() async {
    try {
      final route = await ref
          .read(authControllerProvider.notifier)
          .completeSayariAccountSignIn(widget.callbackUri);
      if (!mounted) return;
      context.go(route);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(error.message));
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.vt(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo/sayari-software-logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            errorMessage == null
                ? context.vt('Finishing Sayari sign-in')
                : context.vt('Sayari sign-in failed'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (errorMessage == null) ...[
            Text(
              context.vt('Please wait while we connect your account.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.go('/sign-in'),
              child: Text(context.vt('Back to Sign In')),
            ),
          ],
        ],
      ),
    );
  }
}
