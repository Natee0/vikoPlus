import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';

class AuthLogoutIconButton extends ConsumerWidget {
  const AuthLogoutIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return IconButton(
      tooltip: 'Logout',
      onPressed: isLoading
          ? null
          : () async {
              await _logoutAndOpenSignIn(context, ref);
            },
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_outlined),
    );
  }
}

class AuthLogoutTile extends ConsumerWidget {
  const AuthLogoutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: isLoading
            ? null
            : () async {
                await _logoutAndOpenSignIn(context, ref);
              },
        child: Padding(
          padding: AppInsets.compactCard,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.logout_outlined,
                  color: isLoading ? AppColors.outline : AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Logging out' : 'Logout',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'End your session on this device',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _logoutAndOpenSignIn(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authControllerProvider.notifier).logout();
  } finally {
    if (context.mounted) context.go('/sign-in');
  }
}
