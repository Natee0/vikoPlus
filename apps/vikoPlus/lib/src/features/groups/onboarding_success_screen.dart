import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_components.dart';
import '../common/vikoplus_screen.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 128,
              height: 128,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer, width: 4),
                boxShadow: AppShadows.level1(),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryContainer,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Welcome to Sofia Wajukuu Group!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You are the group administrator. Activate yearly group access before inviting members and managing contributions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: AppShadows.level1(),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: 'Next Steps'),
                SizedBox(height: AppSpacing.sm),
                _NextStep(
                  number: '1',
                  title: 'Activate yearly group access',
                  subtitle: 'TZS 10,000 per group per year.',
                ),
                SizedBox(height: AppSpacing.xs),
                _NextStep(
                  number: '2',
                  title: 'Invite members and assign roles',
                  subtitle: 'Chairperson/admin controls member permissions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/billing/plans'),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Choose plan'),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
