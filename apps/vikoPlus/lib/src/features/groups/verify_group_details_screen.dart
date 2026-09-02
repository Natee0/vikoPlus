import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class VerifyGroupDetailsScreen extends StatelessWidget {
  const VerifyGroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Verify Group',
      backRoute: '/groups/join',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppInsets.card,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.level1(),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceContainer,
                  child: Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sofia Wajukuu',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                const StatusPill(label: '23 Members'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your invitation is valid. You will join as a member unless the chairperson/admin assigned another role.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/member/dashboard'),
            child: const Text('Join Group'),
          ),
        ],
      ),
    );
  }
}
