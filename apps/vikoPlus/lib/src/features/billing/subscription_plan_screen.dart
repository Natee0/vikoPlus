import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sample/sofia_sample_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design_tokens.dart';
import '../common/vikoplus_screen.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VikoplusScreen(
      title: 'Group Access',
      backRoute: '/groups/onboarding-success',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Activate Sofia Wajukuu Group',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The group creator becomes the administrator and pays platform access for this group. Members do not buy Vikoplus access individually.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const _AccessPlanCard(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Reminder Packages',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReminderPackageTile(
            title: 'SMS reminders',
            price: 'TZS $vikoplusSmsReminderPrice per SMS',
            icon: Icons.sms_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReminderPackageTile(
            title: 'WhatsApp reminders',
            price: 'TZS $vikoplusWhatsAppReminderPrice per WhatsApp',
            icon: Icons.chat_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ReminderPackageTile(
            title: 'SMS + WhatsApp',
            price: 'TZS $vikoplusSmsAndWhatsAppReminderPrice per message',
            icon: Icons.forum_outlined,
            selected: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/billing'),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('Start secure checkout'),
          ),
        ],
      ),
    );
  }
}

class _AccessPlanCard extends StatelessWidget {
  const _AccessPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppShadows.level1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Annual Group Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'TZS $vikoplusGroupAccessAnnualPrice',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Per group, billed yearly to the group administrator.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _IncludedFeature(label: 'Admin dashboard and member register'),
          const _IncludedFeature(label: 'Contribution tracking and reports'),
          const _IncludedFeature(
            label: 'Billing remains separate from member contributions',
          ),
        ],
      ),
    );
  }
}

class _IncludedFeature extends StatelessWidget {
  const _IncludedFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPackageTile extends StatelessWidget {
  const _ReminderPackageTile({
    required this.title,
    required this.price,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final String price;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.compactCard,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.secondaryContainer.withValues(alpha: 0.35)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: selected ? AppColors.secondary : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? AppColors.secondary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.secondary : AppColors.outline,
          ),
        ],
      ),
    );
  }
}
