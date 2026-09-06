import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/vikoplus_translations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import 'auth_widgets.dart';
import 'shared/password_reset_widgets.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PasswordResetScaffold(
      title: context.vt('Login'),
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ResetHeroIcon(
            icon: Icons.verified_outlined,
            badgeIcon: Icons.lock_outlined,
            size: 92,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.vt('Password Changed!'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.vt(
              'Your password has been reset successfully. You can now sign in with your new credentials.',
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
                TrustNote(
                  icon: Icons.fact_check_outlined,
                  title: context.vt('Security Audit'),
                  body: context.vt(
                    'Password reset verified and active sessions ended.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => context.go('/sign-in'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(context.vt('Back to Sign In')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
