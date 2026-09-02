import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class BillingOverviewScreen extends StatelessWidget {
  const BillingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Billing',
      backRoute: '/billing/plans',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BillingStatusCard(
            title: 'Group access active',
            value: 'Sofia Wajukuu Group',
            icon: Icons.verified_user_outlined,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BillingStatusCard(
            title: 'Annual access',
            value: 'TZS $vikoplusGroupAccessAnnualPrice / year',
            icon: Icons.autorenew,
            color: AppColors.tertiaryFixedDim,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppInsets.compactCard,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'This purchase activates admin tools for the group. Member contributions remain separate financial records.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BillingStatusCard(
            title: 'Reminder package',
            value: 'SMS + WhatsApp at TZS 100 per message',
            icon: Icons.forum_outlined,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.credit_card_outlined),
            label: const Text('Update payment method'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Open admin dashboard'),
          ),
        ],
      ),
    );
  }
}

class _BillingStatusCard extends StatelessWidget {
  const _BillingStatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.level1(),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
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
